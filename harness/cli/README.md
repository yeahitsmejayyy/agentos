# Generic CLI — harness adapter

Boots Agent OS on **any host that can run a shell command** — an LLM CLI/REPL, a script, or a human
driving a chat by hand. It exists to **prove the three-plane design**: this adapter shares the OS
(`agents/` + `shared/`) and the Mind (`~/.agentos`) *unchanged* with the Claude Code adapter — only the
wiring differs. Swap the harness; the OS and the mind come with you.

## Install
```bash
bash harness/cli/install.sh        # instantiates the Mind (shared), makes `agentos` runnable
ln -s "$PWD/harness/cli/agentos" ~/.local/bin/agentos   # optional: put it on PATH
```

## Use
```bash
agentos boot               # the system prompt: orchestrator + constitution + self + grown team
agentos recall "<text>"    # per-turn recall to inject before a prompt
agentos capture [reason]   # capture floor — a raw session note to the vault
agentos reindex [--rebuild]# refresh the memory index
```
Wire it into your host: set `boot` output as the **system message**; run `recall` before each turn and
prepend its output; run `capture` at session end. The richer session summary comes from the shared
`wrap-session` skill.

## Adapter contract (see [`../_template/README.md`](../_template/README.md))
| Role | Here |
|---|---|
| Capture floor | `agentos capture` |
| Orientation recall | `agentos boot` |
| Per-prompt recall | `agentos recall` |
| Rich summary / consolidation | the shared `wrap-session` / `consolidate-memory` skills |
| Vault / skill paths | `$AGENT_OS_MEM` + the canonical `skills/` |

## Shared vs adapter-specific
- **Shared, unchanged across adapters:** the OS (`agents/`, `shared/`), the Mind (`~/.agentos`), and the
  **index engine** (`../claude-code/hooks/index/` — the portable core; a natural candidate to hoist to
  `harness/_shared/index/` now that a second adapter exists).
- **This adapter:** just the `agentos` shell entrypoint — the host-specific wiring of boot/recall/capture.

That separation *is* the proof: genesis, recall, and capture all run here against the same seed, with no
Claude Code hooks, settings, or `CLAUDE.md` in sight.
