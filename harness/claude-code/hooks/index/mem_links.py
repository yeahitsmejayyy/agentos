#!/usr/bin/env python3
"""Agent OS — maintain Obsidian [[wiki-links]] so the graph view connects.

Builds a hub-and-spoke per store: home.md -> each bucket `_index` -> its notes.
This is what turns "floating" notes into a navigable graph in Obsidian. Runs over
both stores: .mem (the six memory buckets) and .proc (patterns/modules/scaffolds).

Re-runnable and non-destructive: it only rewrites a delimited block in each
`_index.md` / `home.md`, leaving the human-written description intact. Run it from
cron alongside the reindex, or via the consolidate-memory skill.

Env: AGENT_OS_MEM (default ~/.agentos/.mem), AGENT_OS_PROC (default ~/.agentos/.proc)
"""
import os

HOME_DIR = os.environ.get("AGENT_OS_HOME", os.path.expanduser("~/.agentos"))  # one portable unit
MEM = os.environ.get("AGENT_OS_MEM") or os.path.join(HOME_DIR, ".mem")
PROC = os.environ.get("AGENT_OS_PROC") or os.path.join(HOME_DIR, ".proc")
MEM_BUCKETS = ["self", "projects", "knowledge", "decisions", "sessions", "agents"]
PROC_BUCKETS = ["patterns", "modules", "scaffolds"]
START = "<!-- mem-links:start (auto-maintained — edit above this line) -->"
END = "<!-- mem-links:end -->"


def rel(path, root):
    r = os.path.relpath(path, root)
    return r[:-3] if r.endswith(".md") else r


def label(path):
    """Note label for the link. Modules are <name>/README.md → use the dir name."""
    base = os.path.basename(path)
    if base == "README.md":
        return os.path.basename(os.path.dirname(path))
    return base[:-3] if base.endswith(".md") else base


def notes_in(root, bucket):
    base = os.path.join(root, bucket)
    out = []
    for r, _, names in os.walk(base):
        if "/_template" in r:
            continue
        for fn in sorted(names):
            if fn.endswith(".md") and not fn.startswith("_"):
                out.append(os.path.join(r, fn))
    return sorted(out)


def write_block(path, lines):
    body = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
    block = START + "\n" + "\n".join(lines) + "\n" + END
    if START in body and END in body:
        body = body[:body.index(START)] + block + body[body.index(END) + len(END):]
    else:
        body = body.rstrip() + "\n\n" + block + "\n"
    open(path, "w", encoding="utf-8").write(body)


def link_store(root, buckets):
    if not os.path.isdir(root):
        return
    present = []
    for b in buckets:
        idx = os.path.join(root, b, "_index.md")
        if not os.path.exists(idx):
            continue
        present.append(b)
        notes = notes_in(root, b)
        links = [f"- [[{rel(n, root)}|{label(n)}]]" for n in notes]
        write_block(idx, ["## Map", *(links or ["_(empty — notes will appear here as they're written)_"])])
        print(f"{os.path.basename(root.rstrip('/')) or root}:{b}: {len(notes)} linked")
    home = os.path.join(root, "home.md")
    if os.path.exists(home):
        links = [f"- [[{b}/_index|{b}]]" for b in present]
        write_block(home, ["## Map", *links])
        print(f"{os.path.basename(root.rstrip('/')) or root}:home: linked buckets")


def main():
    link_store(MEM, MEM_BUCKETS)
    link_store(PROC, PROC_BUCKETS)


if __name__ == "__main__":
    main()
