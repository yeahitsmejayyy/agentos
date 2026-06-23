# Agent OS — Claude Code Install

`~/.claude` is your live Claude Code config and is **protected** — the assistant can't edit it, so
run these yourself, in order. Commands are verified against current Claude Code docs (2026).

Nothing here is hard-coded to a particular machine: `OS` is derived from wherever you cloned this
repo, and the mind homes at `$AGENT_OS_HOME` (default `~/.agentos`).

```bash
# Point OS at this repo (run from anywhere inside your clone, or set it explicitly):
OS="$(git -C . rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
echo "$OS"   # sanity-check: should be the root of your agentos clone
```

## Quick install (one command)

From anywhere inside your clone:

```bash
bash harness/claude-code/install.sh        # add --no-cron to skip the hourly reindex schedule
```

`install.sh` does steps 1–4 below automatically and is **idempotent, path-derived, and vault-safe** —
it instantiates the mind only if absent (never clobbers an existing vault), backs up and *dedup-merges*
the hooks into `settings.json` (never overwrites your other hooks), and wires `CLAUDE.md` exactly once.
Re-run it any time to repair or update an install. It honors `AGENT_OS_HOME` (mind), `CLAUDE_CONFIG_DIR`
(host config), and infers the repo root from its own location.

Then jump to **§5 · Genesis** (open a new session and name your instance) and **§6 · Verify**.

> Prefer to run it by hand, or on a non-Claude-Code harness? The steps below are exactly what the
> script automates — they remain the canonical, portable reference.

---

## 0 · Prerequisites
```bash
python3 --version     # REQUIRED (index + JSON-parsing fallback)
jq --version          # optional (scripts fall back to python3 if absent)
rg --version || true  # optional (plain grep fallback works)
```
*(Optional, best recall quality: install Ollama, then `ollama pull nomic-embed-text`.)*

## 1 · Instantiate the mind (the empty brain)
The repo ships **zeroed** `memory/` and `procedural/` skeletons. Copy them into the portable home:
```bash
mkdir -p ~/.agentos
cp -R "$OS/memory"     ~/.agentos/.mem
cp -R "$OS/procedural" ~/.agentos/.proc
```
*(`AGENT_OS_HOME` defaults to `~/.agentos`; set it in your shell only if you want the mind elsewhere.)*

## 2 · Install the adapter
```bash
mkdir -p ~/.claude/hooks/agent-os ~/.claude/skills
cp -R "$OS"/harness/claude-code/hooks/*  ~/.claude/hooks/agent-os/
cp -R "$OS"/harness/claude-code/skills/* ~/.claude/skills/
chmod +x ~/.claude/hooks/agent-os/*.sh ~/.claude/hooks/agent-os/index/*.sh ~/.claude/hooks/agent-os/index/*.py
```
Merge the hooks into `~/.claude/settings.json`:
```bash
cat "$OS"/harness/claude-code/settings.snippet.json   # inspect the block to merge
# if you have no settings.json yet, this creates one (then delete the "_comment" line):
[ -f ~/.claude/settings.json ] || cp "$OS"/harness/claude-code/settings.snippet.json ~/.claude/settings.json
```
If `settings.json` already exists, hand-merge the `"hooks"` object (don't overwrite the file).

## 3 · Wire the orchestrator as the boot agent  *(the critical step)*
This makes every session boot **as your orchestrator** and inherit the constitution. On first boot
the orchestrator is still nameless — that first session **is genesis** (§5).
```bash
cat >> ~/.claude/CLAUDE.md <<MD

@$OS/shared/CONSTITUTION.md
@$OS/agents/orchestrator/AGENT.md
MD
```
(`@path` imports load in full at session start.)

## 4 · Build the memory index + schedule a refresh
```bash
bash ~/.claude/hooks/agent-os/index/reindex.sh --rebuild
python3 ~/.claude/hooks/agent-os/index/mem_query.py "test"
# hourly refresh:
( crontab -l 2>/dev/null; echo "0 * * * * /bin/bash $HOME/.claude/hooks/agent-os/index/reindex.sh >/dev/null 2>&1" ) | crontab -
```

## 5 · Genesis — name your instance  *(first new session)*
Open a **new** Claude Code session. The orchestrator boots nameless and runs the first-run
interview: it asks what to call it, forks the constitution into your words, and writes your first
memories to the vault as you answer. When it finishes, the generic seed has become *your* instance.

## 6 · Verify  *(don't assume — confirm)*
- **Orientation:** start a session → `home.md` / `self` context appears.
- **Per-prompt recall:** send a prompt → relevant memory injected. If nothing shows, confirm the
  `UserPromptSubmit` prompt field name on your version and adjust `recall-prompt.sh` (it already
  tries `prompt` / `user_prompt` / `userPrompt`).
- **Rich summary:** run `/wrap-session` → structured note lands in `~/.agentos/.mem/sessions/`.
- **Capture floor:** end the session → a `raw-capture` note appears in `~/.agentos/.mem/sessions/`.
- **Consolidation:** run `/consolidate-memory` → it *proposes* durable writes (doesn't auto-write).

## 7 · Upgrade recall (optional, when ready)
```bash
ollama pull nomic-embed-text
echo 'export AGENT_OS_EMBED=ollama' >> ~/.zshrc
AGENT_OS_EMBED=ollama bash ~/.claude/hooks/agent-os/index/reindex.sh --rebuild
```

## Notes / caveats
- The snippet's `_comment` key is for humans — drop it when merging into `settings.json`.
- Hook event names / the prompt field name can drift between Claude Code versions — Step 6 verifies
  them; the scripts tolerate the common variants.
- Hooks run shell on your machine — review `~/.claude/hooks/agent-os/` before enabling (least privilege).
- The `hash` embedding backend is lexical/weak; install Ollama (Step 7) for real semantic recall.
