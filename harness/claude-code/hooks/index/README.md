# Local Memory Index (Claude Code adapter)

A derived, **fully-local** vector index over **both stores** — `.mem` (memory recall) and `.proc` (standards discovery), nested under `$AGENT_OS_HOME` (default `~/.agentos`). One index, two namespaced collections (a `store` column). The Claude Code stand-in for what Hindsight will do on Hermes. The stores stay the source of truth; this index is rebuildable (delete `~/.agentos/.mem/.index/` and re-run).

## What's here
- `lib_embed.py` — embedding layer, three tiers (graceful, all local): **Ollama → sentence-transformers → hashing baseline**.
- `mem_index.py` — builds/refreshes the index (incremental; `--rebuild` for full).
- `mem_query.py` — semantic query; prints top matches (used by `recall-prompt.sh`). Also appends each
  recall to `.index/usage.jsonl` (best-effort) — the raw usage signal.
- `mem_usage.py` — summarizes `usage.jsonl` + the index into **usage signals for the Watcher**: what's
  recalled often (valuable) vs indexed-but-never-recalled (retire candidate). `--json` for machine use.
- `reindex.sh` — convenience wrapper (for cron or manual runs).

## Embedding backends (pick with `AGENT_OS_EMBED`)
- **`ollama`** (recommended) — warm local server, fast per-query, good quality. Setup: install Ollama, then `ollama pull nomic-embed-text`.
- **`st`** — Python `sentence-transformers` (all-MiniLM). `pip install sentence-transformers`. No Ollama needed; slower per call.
- **`hash`** — zero-dependency lexical baseline. Always works, but relevance is crude (lexical only). Good for testing the loop before installing anything.
- **`auto`** (default) — Ollama if its server answers, else sentence-transformers if importable, else hash.

> The hash tier lets you test-drive the whole capture→recall loop *today* with nothing installed. Install Ollama when you want real semantic quality — no code changes, just `./reindex.sh --rebuild` to re-embed.

## First run
```bash
export AGENT_OS_HOME="$HOME/.agentos"  # only if you don't want the default
# (optional, for real quality) install Ollama, then:
#   ollama pull nomic-embed-text && export AGENT_OS_EMBED=ollama
bash reindex.sh --rebuild             # build the index over both stores
python3 mem_query.py "test query"     # sanity check (add --store proc / --type procedural to scope)
```
The recall hook (`recall-prompt.sh`) uses the index automatically once `~/.agentos/.mem/.index/index.db` exists; until then it falls back to grep.

## Keep it fresh — cron
Re-index on a timer (pairs naturally with the nightly consolidation sweep):
```cron
# every hour
0 * * * * AGENT_OS_HOME="$HOME/.agentos" AGENT_OS_EMBED=ollama /bin/bash ~/.claude/hooks/agent-os/index/reindex.sh >/dev/null 2>&1
```
Adjust the path to wherever you installed the adapter hooks.

## Scope (matches recall-layer-plan)
**`.mem`** — Indexed: `self`, `projects`, `knowledge`, `decisions`, recent `sessions` (rolling window, `AGENT_OS_SESSION_DAYS`, default 14), and each agent's `profile` + `skills`.
**`.proc`** — Indexed: real standards (`patterns/`, module `README`s, `scaffolds/`) for discovery. Selective: the near-empty `standards.md` seed is **not** embedded (surfaced wholesale at orient instead).
Never indexed (either store): `scratch/`, `_template/`, `_index`/`home` files, `.obsidian`. Old sessions age out of the window automatically.

Every chunk carries `memory_type` (episodic | semantic | procedural) + `store` (mem | proc) → query with `--type` / `--store` for filter-before-search.

## Notes / caveats
- Pure-python cosine over all rows — fine for a personal vault (thousands of notes). For very large vaults, swap in a vector store later.
- If you change embed backends, run `./reindex.sh --rebuild` (vectors from different models aren't comparable).
- Nothing here calls a remote API; all three backends run on your machine.
