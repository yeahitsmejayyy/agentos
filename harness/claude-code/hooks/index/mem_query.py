#!/usr/bin/env python3
"""Agent OS — query the local vector index; print top matches for hook injection.

Embeds the query with the same backend the index was built with, then ranks chunks
by cosine similarity. Filter-before-search: narrow by metadata (memory_type, store)
*first*, then run cosine over the survivors — the tokenomics lever that raises
precision@k. Pure-python cosine over the (filtered) rows — fine for a personal
vault (thousands of notes, sub-second).

Usage: python3 mem_query.py "how do I scope a project" -k 5
       python3 mem_query.py "data table" --type procedural --store proc
Env:   AGENT_OS_MEM (default ~/.agentos/.mem), AGENT_OS_PROC (default ~/.agentos/.proc)
"""
import os, sys, sqlite3, struct, math, argparse
import lib_embed

HOME_DIR = os.environ.get("AGENT_OS_HOME", os.path.expanduser("~/.agentos"))  # one portable unit
MEM = os.environ.get("AGENT_OS_MEM") or os.path.join(HOME_DIR, ".mem")
PROC = os.environ.get("AGENT_OS_PROC") or os.path.join(HOME_DIR, ".proc")
DB = os.path.join(MEM, ".index", "index.db")


def from_blob(b):
    return struct.unpack("%sf" % (len(b) // 4), b)


def cosine(a, b):
    s = da = db = 0.0
    for x, y in zip(a, b):
        s += x * y; da += x * x; db += y * y
    return s / ((math.sqrt(da) * math.sqrt(db)) or 1.0)


def rel_to_store(path, store):
    """Display path relative to whichever store the note lives in."""
    root = PROC if store == "proc" else MEM
    try:
        return os.path.relpath(path, root)
    except ValueError:
        return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("query")
    ap.add_argument("-k", type=int, default=5)
    ap.add_argument("--type", default=None, help="filter on memory_type (episodic|semantic|procedural)")
    ap.add_argument("--store", default=None, choices=["mem", "proc"], help="filter on store")
    ap.add_argument("--min", type=float, default=0.0, help="min cosine score")
    a = ap.parse_args()

    if not os.path.exists(DB):
        return
    con = sqlite3.connect(DB)
    cur = con.cursor()
    r = cur.execute("SELECT v FROM meta WHERE k='backend'").fetchone()
    backend = r[0] if r else None
    qv = lib_embed.embed([a.query], backend)[0][0]

    scored = []
    for path, ci, text, mtype, store, vec in cur.execute(
        "SELECT path, chunk_idx, text, memory_type, store, vec FROM chunks"
    ):
        if a.type and mtype != a.type:          # filter-before-search: type first
            continue
        if a.store and store != a.store:        # then store
            continue
        scored.append((cosine(qv, from_blob(vec)), path, text, mtype, store))
    con.close()

    scored.sort(reverse=True, key=lambda x: x[0])
    top = [s for s in scored if s[0] > a.min][:a.k]
    if not top:
        return

    print("## Relevant memory (semantic recall)")
    for score, path, text, mtype, store in top:
        rel = rel_to_store(path, store)
        snip = " ".join(text.split())
        if len(snip) > 400:
            snip = snip[:400] + "…"
        print(f"### {rel}  ({store or 'mem'}/{mtype or 'note'}, score {score:.2f})")
        print(snip)
        print()


if __name__ == "__main__":
    main()
