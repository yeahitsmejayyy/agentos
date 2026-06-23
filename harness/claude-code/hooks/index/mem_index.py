#!/usr/bin/env python3
"""Agent OS — build/refresh the local vector index over the .mem + .proc stores.

Derived, rebuildable index (the stores stay the source of truth). Local-only.
One index, two namespaced collections — a `store` column distinguishes `.mem`
(recall) from `.proc` (standards discovery). Every chunk also carries `memory_type`
(episodic | semantic | procedural) for filter-before-search typed recall.

Respects the recall-scope rules per store:
  .mem  — durable buckets always; sessions on a rolling window; agent profile/skills
          (scoped) yes; scratch and _template/_index never; raw-capture never.
  .proc — real standards only (patterns / module READMEs / scaffolds); selective:
          _template/_index/home never, and the near-empty standards.md seed is NOT
          embedded (surfaced categorically at orient instead — see migration §4).

Usage: python3 mem_index.py            # incremental (changed files only)
       python3 mem_index.py --rebuild  # wipe + full rebuild
Env:   AGENT_OS_MEM (default ~/.agentos/.mem), AGENT_OS_PROC (default ~/.agentos/.proc),
       AGENT_OS_EMBED, AGENT_OS_SESSION_DAYS
"""
import os, re, sys, sqlite3, time, struct
import lib_embed

HOME_DIR = os.environ.get("AGENT_OS_HOME", os.path.expanduser("~/.agentos"))  # one portable unit
MEM = os.environ.get("AGENT_OS_MEM") or os.path.join(HOME_DIR, ".mem")
PROC = os.environ.get("AGENT_OS_PROC") or os.path.join(HOME_DIR, ".proc")
INDEX_DIR = os.path.join(MEM, ".index")   # one shared index, under .mem
DB = os.path.join(INDEX_DIR, "index.db")
DURABLE = ["self", "projects", "knowledge", "decisions"]
SESSION_WINDOW_DAYS = int(os.environ.get("AGENT_OS_SESSION_DAYS", "14"))
MAX_CHUNK = 1200

# Legacy topic `type` → cognitive `memory_type` (the migration §2 table). Applied
# only to notes that predate the memory_type overlay (no memory_type field). It
# touches nothing on disk — only the derived index — and closes the typed-recall
# gap for un-retyped notes until Part B retypes the live vault. Hybrid: map the
# documented buckets; for any UNKNOWN topic, keep the literal string (never assert
# a cognitive type we don't have a rule for).
LEGACY_TYPE_MAP = {
    "session": "episodic",
    "decision": "semantic",
    "knowledge": "semantic",
    "self": "semantic",
    "project": "semantic",
}


def parse_note(path):
    text = open(path, encoding="utf-8", errors="ignore").read()
    fm, body = {}, text
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            for line in text[3:end].splitlines():
                if ":" in line:
                    k, v = line.split(":", 1)
                    fm[k.strip()] = v.strip()
            body = text[end + 4:]
    return fm, body.strip()


def chunks_of(body):
    if not body:
        return []
    if len(body) <= MAX_CHUNK:
        return [body]
    # Split on blank lines, then HARD-slice any single paragraph that still
    # exceeds MAX_CHUNK. Without this, a break-less blob (e.g. a raw JSON
    # transcript) stays one giant chunk and overflows the embedder's context
    # window — ollama returns 500 "input length exceeds the context length".
    paras = []
    for para in re.split(r"\n\s*\n", body):
        if len(para) <= MAX_CHUNK:
            paras.append(para)
        else:
            for i in range(0, len(para), MAX_CHUNK):
                paras.append(para[i:i + MAX_CHUNK])
    out, cur = [], ""
    for para in paras:
        if len(cur) + len(para) > MAX_CHUNK and cur:
            out.append(cur.strip()); cur = ""
        cur += para + "\n\n"
    if cur.strip():
        out.append(cur.strip())
    return out


def gather_mem():
    """Note paths to index from the .mem store (recall)."""
    files, now = set(), time.time()
    for b in DURABLE:
        base = os.path.join(MEM, b)
        for root, _, names in os.walk(base):
            if "/_template" in root:
                continue
            for fn in names:
                if fn.endswith(".md") and not fn.startswith("_"):
                    files.add(os.path.join(root, fn))
    # sessions — rolling recent window only
    sbase = os.path.join(MEM, "sessions")
    for root, _, names in os.walk(sbase):
        if "/_template" in root:
            continue
        for fn in names:
            if fn.endswith(".md") and not fn.startswith("_"):
                p = os.path.join(root, fn)
                if (now - os.path.getmtime(p)) > SESSION_WINDOW_DAYS * 86400:
                    continue
                # raw-capture notes are the forensic floor (a tail of the raw
                # transcript JSONL). Kept on disk, but NOT indexed — the distilled
                # wrap-session notes carry session recall. Indexing the raw blob
                # just pollutes results with transcript/base64 noise.
                fm, _ = parse_note(p)
                if "raw-capture" in fm.get("tags", ""):
                    continue
                files.add(p)
    # agent private: profile + skills (scoped), never scratch
    abase = os.path.join(MEM, "agents")
    for root, _, names in os.walk(abase):
        if "/scratch" in root or "/_template" in root:
            continue
        for fn in names:
            if fn.endswith(".md") and not fn.startswith("_"):
                files.add(os.path.join(root, fn))
    return files


def gather_proc():
    """Note paths to index from the .proc store (standards discovery).

    Selective by design (migration §4): index the real standards — patterns,
    module READMEs, scaffolds — so the index can answer "do I even have a standard
    for this?". Skip the scaffolding (_index/_template/home) AND the near-empty
    standards.md seed, which is surfaced wholesale at orient, not embedded.
    """
    files = set()
    if not os.path.isdir(PROC):
        return files
    for root, _, names in os.walk(PROC):
        if "/_template" in root:
            continue
        for fn in names:
            if not fn.endswith(".md") or fn.startswith("_"):
                continue
            if fn in ("home.md", "standards.md"):
                continue
            files.add(os.path.join(root, fn))
    return files


def gather():
    """Return {path: store} for every note that should be indexed, across both stores."""
    out = {p: "mem" for p in gather_mem()}
    out.update({p: "proc" for p in gather_proc()})
    return out


def to_blob(vec):
    return struct.pack("%sf" % len(vec), *vec)


def main():
    rebuild = "--rebuild" in sys.argv
    os.makedirs(INDEX_DIR, exist_ok=True)
    con = sqlite3.connect(DB)
    cur = con.cursor()
    # Schema migration: a pre-two-axis DB lacks the memory_type/store columns and
    # would crash the positional INSERT below. The index is derived + rebuildable,
    # so the cheapest correct fix is to drop the old table and re-embed from source.
    existing = cur.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='chunks'"
    ).fetchone()
    if existing:
        cols = [r[1] for r in cur.execute("PRAGMA table_info(chunks)").fetchall()]
        if "store" not in cols or "memory_type" not in cols:
            cur.execute("DROP TABLE chunks")
            print("[mem-index] old schema detected — rebuilding chunks table (two-axis)")
    cur.execute("""CREATE TABLE IF NOT EXISTS chunks(
        path TEXT, chunk_idx INT, text TEXT, memory_type TEXT, type TEXT,
        store TEXT, project TEXT, tags TEXT,
        mtime REAL, backend TEXT, dim INT, vec BLOB, PRIMARY KEY(path, chunk_idx))""")
    cur.execute("CREATE TABLE IF NOT EXISTS meta(k TEXT PRIMARY KEY, v TEXT)")
    if rebuild:
        cur.execute("DELETE FROM chunks")
    con.commit()

    backend = lib_embed.select_backend()
    files = gather()

    # drop deleted files
    for (p,) in cur.execute("SELECT DISTINCT path FROM chunks").fetchall():
        if p not in files:
            cur.execute("DELETE FROM chunks WHERE path=?", (p,))

    n_files = n_chunks = 0
    for p in sorted(files):
        store = files[p]
        mt = os.path.getmtime(p)
        row = cur.execute("SELECT mtime, backend FROM chunks WHERE path=? LIMIT 1", (p,)).fetchone()
        if row and abs(row[0] - mt) < 1e-6 and row[1] == backend:
            continue  # unchanged
        fm, body = parse_note(p)
        # Primary axis: memory_type. If absent (a pre-overlay note), derive it from
        # the legacy topic `type` via the §2 map — mapped where we have a rule,
        # literal where we don't. The raw topic is still stored in the `type` column.
        memory_type = fm.get("memory_type")
        if not memory_type:
            legacy = fm.get("type", "")
            memory_type = LEGACY_TYPE_MAP.get(legacy, legacy)
        cks = chunks_of(body)
        cur.execute("DELETE FROM chunks WHERE path=?", (p,))
        if not cks:
            continue
        vecs, used = lib_embed.embed(cks, backend)
        for i, (c, v) in enumerate(zip(cks, vecs)):
            cur.execute(
                "INSERT OR REPLACE INTO chunks VALUES(?,?,?,?,?,?,?,?,?,?,?,?)",
                (p, i, c, memory_type, fm.get("type", ""), store,
                 fm.get("project", ""), fm.get("tags", ""),
                 mt, used, len(v), to_blob(v)),
            )
        n_files += 1
        n_chunks += len(cks)

    cur.execute("INSERT OR REPLACE INTO meta VALUES('backend', ?)", (backend,))
    cur.execute("INSERT OR REPLACE INTO meta VALUES('updated', ?)", (str(time.time()),))
    con.commit()
    con.close()
    print(f"[mem-index] backend={backend}  changed_files={n_files}  chunks={n_chunks}  db={DB}")


if __name__ == "__main__":
    main()
