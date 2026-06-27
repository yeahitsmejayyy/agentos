# tests — Agent OS regression suite

Deterministic checks (no LLM, no network, no real `~/.claude` or `~/.agentos` touched) over the parts of
the seed that *can* be tested mechanically.

```bash
bash tests/run.sh        # exit 0 = all pass, 1 = something regressed
```

## Coverage (58 checks)
- **`test_seed_purity.sh`** — static invariants we hand-guarded by eye for days: constitution Part 1
  empty, North Star not hardcoded, Part 3 safety floor, no personal-value/stack leaks, orchestrator-only
  seed, lazy agent memory (template = `AGENT.md` only), uppercase self-files, all six Watcher kinds, no
  stale `about-me`, full RISEN template, all 7 skills ship, all 5 hook events declared, `.gitignore`
  protects mind/index/creds, nothing sensitive tracked.
- **`test_index.sh`** — `mem_index` build + `mem_query` recall (offline hash backend), **and the privacy
  tiers**: `scratch/` is never indexed; an agent's `PROFILE.md` is.
- **`test_hooks.sh`** — `recall-orient` (FIRST RUN / normal / grown roster / full constitution injection /
  standards index / Watcher inbox count), `reindex-on-write` path-gating (vault `.md` only, no-op
  otherwise), `recall-prompt` grep fallback, `capture-session` raw note.
- **`test_install_lifecycle.sh`** — install → doctor(healthy) → all 7 skills + 5 hook events (absolute
  paths) → **idempotent re-install** (one bootloader block, no dup hooks) → uninstall (vault-safe; a
  foreign hook + setting survive) → doctor(unhealthy) → `--purge`. Fully `HOME`-isolated, `--no-cron`.

## What it does NOT cover
The LLM-driven behavior — genesis *feel*, the Watcher's *judgment*. Those stay a manual sandbox check
(`seedtest.sh`). The suite asserts their deterministic scaffolding and file-shape invariants instead.

## Adding a test
Drop `test_<area>.sh` here — `run.sh` sources every `test_*.sh` into one shell. Use the `lib.sh` helpers
(`ok` / `no` / `check` / `contains` / `absent` / `grep_absent` / `grep_absent_cs` / `eq` / `newtmp` / `have`).
**Don't** `set -e` or `exit` in a test file — they're sourced, so that would kill the runner.
