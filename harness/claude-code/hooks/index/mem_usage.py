#!/usr/bin/env python3
"""Agent OS — usage signals for the Watcher. Reads the recall log (`.index/usage.jsonl`, appended by
mem_query) and the index, and reports what is *valuable* (recalled often) vs *unused* (indexed but never
recalled — a retire candidate). This is the data the Watcher reasons over — beyond reading .mem prose —
so `propose-retire` and the recurrence behind `promote-standard` rest on evidence, not vibes.

Usage: python3 mem_usage.py            # human summary
       python3 mem_usage.py --json     # machine-readable
Env:   AGENT_OS_MEM, AGENT_OS_PROC  (same as the index)
"""
import os, json, sqlite3, argparse
from collections import Counter

HOME_DIR = os.environ.get("AGENT_OS_HOME", os.path.expanduser("~/.agentos"))
MEM = os.environ.get("AGENT_OS_MEM") or os.path.join(HOME_DIR, ".mem")
PROC = os.environ.get("AGENT_OS_PROC") or os.path.join(HOME_DIR, ".proc")
LOG = os.path.join(MEM, ".index", "usage.jsonl")
DB = os.path.join(MEM, ".index", "index.db")


def load_hits():
    counts, last = Counter(), {}
    if not os.path.exists(LOG):
        return counts, last
    with open(LOG) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rec = json.loads(line)
            except Exception:
                continue
            ts = rec.get("ts", "")
            for h in rec.get("hits", []):
                key = (h.get("store", "mem"), h.get("path", ""))
                if not key[1]:
                    continue
                counts[key] += 1
                if ts > last.get(key, ""):
                    last[key] = ts
    return counts, last


def indexed_files():
    """Distinct (store, rel-path) in the index — lets us spot indexed-but-never-recalled notes."""
    out = set()
    if not os.path.exists(DB):
        return out
    con = sqlite3.connect(DB)
    try:
        for path, store in con.execute("SELECT DISTINCT path, store FROM chunks"):
            root = PROC if store == "proc" else MEM
            try:
                rel = os.path.relpath(path, root)
            except ValueError:
                rel = path
            out.add((store or "mem", rel))
    except Exception:
        pass
    con.close()
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--top", type=int, default=10)
    a = ap.parse_args()

    counts, last = load_hits()
    idx = indexed_files()
    never = sorted(idx - set(counts.keys()))
    top = counts.most_common(a.top)
    total = sum(counts.values())

    if a.json:
        print(json.dumps({
            "total_recalls": total,
            "top": [{"store": k[0], "path": k[1], "hits": n, "last": last.get(k, "")} for k, n in top],
            "never_recalled": [{"store": s, "path": p} for s, p in never],
        }, indent=2))
        return

    print("## Recall usage — signal for the Watcher")
    print(f"({total} recall hits logged across {len(idx)} indexed notes)\n")
    if top:
        print("Most recalled (valuable — keep / promote):")
        for (s, p), n in top:
            print(f"  {n:>4}× [{s}] {p}   (last {last.get((s, p), '?')})")
        print()
    if never:
        print("Never recalled (retire / low-value candidates):")
        for s, p in never:
            print(f"     0× [{s}] {p}")
    else:
        print("Never-recalled: none — every indexed note has surfaced at least once.")


if __name__ == "__main__":
    main()
