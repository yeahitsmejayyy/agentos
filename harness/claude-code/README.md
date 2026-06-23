# Harness Adapter — Claude Code

Ties Agent OS to Claude Code's hooks + skills. The universal core (`../../`) is untouched; only this wiring is host-specific.

## Install
1. **Hooks:** copy `hooks/*.sh` → `~/.claude/hooks/agent-os/` (keep them executable).
2. **Skills:** copy `skills/*` → `~/.claude/skills/`.
3. **Settings:** merge `settings.snippet.json`'s `hooks` block into `~/.claude/settings.json`.
4. **Stores:** both nest under `$AGENT_OS_HOME` (default `~/.agentos`) — `.mem` (memory) + `.proc` (standards). Override the root with `AGENT_OS_HOME`, or a single store with `AGENT_OS_MEM` / `AGENT_OS_PROC`.
5. **Deps:** `jq` and `ripgrep`/`grep` on PATH; `python3` for the semantic index.
6. **Semantic index (optional but recommended):** see `hooks/index/README.md` — build it with `bash hooks/index/reindex.sh --rebuild` and add the cron line. Recommended backend: Ollama (`ollama pull nomic-embed-text`). Until the index exists, recall auto-falls-back to grep.

## What it wires (maps to the memory design)
| Mechanism | Hook / file | Action |
|---|---|---|
| Capture floor | `SessionEnd` + `PreCompact` → `capture-session.sh` | raw session note → `sessions/` |
| Rich summary | `wrap-session` skill (model) | structured session note → `sessions/` |
| First-run genesis | `SessionStart` → `recall-orient.sh` detects no `self/identity.md` → `genesis` skill | nameless seed → named, personalized instance (see `GENESIS.md`) |
| Orientation recall | `SessionStart` → `recall-orient.sh` | inject `home.md` + forked `self/constitution.md` + `self/` |
| Per-prompt recall | `UserPromptSubmit` → `recall-prompt.sh` | **local semantic index** (`hooks/index/`), grep fallback → inject relevant notes |
| Reindex | `hooks/index/reindex.sh` (cron) | refresh the vector index over the vault |
| Consolidation | `consolidate-memory` skill | distill + propose promotions (you approve) |

## Test-drive order
Add `capture-session` first; confirm notes land. Then orientation recall, then build the semantic index and try per-prompt recall, then consolidation. Each step is independent and reversible.

> Recall uses a fully-local vector index (`hooks/index/`) with three embedding tiers — Ollama → sentence-transformers → hashing baseline — so it works with zero install and upgrades to real semantic quality once Ollama is added. On Hermes (July) this same role is filled by Hindsight; only the adapter changes.
