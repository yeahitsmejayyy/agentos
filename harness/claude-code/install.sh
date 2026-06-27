#!/bin/bash
# Agent OS — Claude Code installer (one command, idempotent, path-derived, vault-safe).
#
# Does everything INSTALL.md does by hand:
#   1. instantiate the mind (memory/ + procedural/ -> $AGENT_OS_HOME)   — only if absent (vault-safe)
#   2. install the adapter code (hooks + skills) into the Claude config — disposable, overwrite
#   3. safely merge the hooks block into settings.json                  — backup + dedup, never clobber
#   4. wire the orchestrator + constitution into CLAUDE.md              — guarded, no duplicate appends
#   5. build the memory index + (optionally) schedule the hourly cron   — best-effort
#
# Re-runnable: every step is guarded so a second run changes nothing it shouldn't.
# Portable: nothing is hard-coded to a machine — the repo root is inferred from this script's path,
# the mind homes at $AGENT_OS_HOME (default ~/.agentos), the host config at $CLAUDE_CONFIG_DIR (~/.claude).
#
# Usage:   bash harness/claude-code/install.sh [--no-cron]
set -euo pipefail

# ---- resolve paths (inferred, not hard-coded) -------------------------------------------------
OS="$(cd "$(dirname "$0")/../.." && pwd)"                  # repo root: harness/claude-code/ -> ../../
SRC="$OS/harness/claude-code"
HOME_DIR="${AGENT_OS_HOME:-$HOME/.agentos}"               # the mind (portable, outside version control)
MEM="${AGENT_OS_MEM:-$HOME_DIR/.mem}"
PROC="${AGENT_OS_PROC:-$HOME_DIR/.proc}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"          # the host config (Claude Code honors this var)
HOOKS_DEST="$CLAUDE_DIR/hooks/agent-os"
SKILLS_DEST="$CLAUDE_DIR/skills"
DO_CRON=1
[ "${1:-}" = "--no-cron" ] && DO_CRON=0

say(){ printf '%s\n' "$*"; }
ok(){  printf '  \033[32m✓\033[0m %s\n' "$*"; }
skip(){ printf '  \033[33m•\033[0m %s\n' "$*"; }

[ -d "$SRC/hooks" ] && [ -d "$SRC/skills" ] || { echo "✗ repo source not found at $SRC" >&2; exit 1; }
command -v python3 >/dev/null || { echo "✗ python3 is required (index + safe settings merge)" >&2; exit 1; }
command -v jq >/dev/null || skip "jq not found — fine, the scripts fall back to python3"

say "Agent OS installer"
say "  repo (OS):     $OS"
say "  mind (HOME):   $HOME_DIR"
say "  host config:   $CLAUDE_DIR"
say ""

# ---- 1 · instantiate the mind (VAULT-SAFE: never clobber an existing mind) ---------------------
say "1 · mind"
mkdir -p "$HOME_DIR"
if [ -e "$MEM" ]; then skip "vault exists — preserved untouched ($MEM)"; else cp -R "$OS/memory" "$MEM"; ok "memory skeleton → $MEM"; fi
if [ -e "$PROC" ]; then skip "standards exist — preserved untouched ($PROC)"; else cp -R "$OS/procedural" "$PROC"; ok "procedural skeleton → $PROC"; fi

# ---- 2 · adapter code (disposable; overwrite is the point — same as update.sh) -----------------
say "2 · adapter"
mkdir -p "$HOOKS_DEST" "$SKILLS_DEST"
cp -R "$SRC"/hooks/*  "$HOOKS_DEST"/
cp -R "$SRC"/skills/* "$SKILLS_DEST"/
chmod +x "$HOOKS_DEST"/*.sh "$HOOKS_DEST"/index/*.sh "$HOOKS_DEST"/index/*.py 2>/dev/null || true
find "$HOOKS_DEST" -name '__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null || true
ok "hooks → $HOOKS_DEST"
ok "skills → $SKILLS_DEST"

# ---- 3 · settings.json (backup-first, dedup merge — never overwrite other owners' hooks) --------
say "3 · settings.json"
SETTINGS="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  skip "backed up existing settings.json"
fi
python3 - "$SRC/settings.snippet.json" "$SETTINGS" "$HOOKS_DEST" <<'PY'
import json, sys
snip_path, settings_path, hooks_dest = sys.argv[1], sys.argv[2], sys.argv[3]
# Wire hooks to the ACTUAL install dir (absolute), not a "~/.claude" assumption — so an install into a
# non-default CLAUDE_CONFIG_DIR (e.g. an isolated test home) runs THESE hooks, not the live ~/.claude ones.
raw = open(snip_path).read().replace("~/.claude/hooks/agent-os", hooks_dest)
snip_hooks = json.loads(raw).get("hooks", {})
try:
    cur = json.load(open(settings_path))
except (FileNotFoundError, ValueError):
    cur = {}
hooks = cur.get("hooks", {})
def commands(entries):
    out = set()
    for e in entries:
        for h in e.get("hooks", []):
            if h.get("command"): out.add(h["command"])
    return out
added = 0
for ev, entries in snip_hooks.items():
    existing = hooks.get(ev, [])
    have = commands(existing)
    for e in entries:
        ecmds = {h.get("command") for h in e.get("hooks", [])}
        if ecmds & have:   # this hook command already wired — skip (idempotent)
            continue
        existing.append(e); added += 1
    hooks[ev] = existing
cur["hooks"] = hooks
json.dump(cur, open(settings_path, "w"), indent=2)
open(settings_path, "a").write("\n")
print(f"WIRED {added}")
PY
ok "hooks merged into settings.json (existing owners preserved; dedup'd)"

# ---- 4 · bootloader: CLAUDE.md (guarded append — boot as orchestrator + baseline law) ----------
say "4 · bootloader (CLAUDE.md)"
CLAUDEMD="$CLAUDE_DIR/CLAUDE.md"
MARK="# >>> Agent OS (managed — do not duplicate) >>>"
if [ -f "$CLAUDEMD" ] && grep -qF "$MARK" "$CLAUDEMD"; then
  skip "orchestrator already wired in CLAUDE.md"
else
  { printf '\n%s\n' "$MARK"
    printf '@%s\n' "$OS/shared/CONSTITUTION.md"
    printf '@%s\n' "$OS/agents/orchestrator/AGENT.md"
    printf '%s\n' "# <<< Agent OS <<<"
  } >> "$CLAUDEMD"
  ok "wired orchestrator + constitution frame into CLAUDE.md"
fi
say "    (the frame is the always-on baseline law; once genesis writes self/CONSTITUTION.md,"
say "     the forked law is injected live by recall-orient.sh — see GENESIS.md §5)"

# ---- 5 · memory index + hourly refresh (best-effort) ------------------------------------------
say "5 · index"
if bash "$HOOKS_DEST/index/reindex.sh" --rebuild >/dev/null 2>&1; then
  ok "memory index built"
else
  skip "index build skipped/failed (recall falls back to grep — non-fatal; see hooks/index/README.md)"
fi
if [ "$DO_CRON" = 1 ] && command -v crontab >/dev/null 2>&1; then
  CRON_CMD="/bin/bash $HOOKS_DEST/index/reindex.sh >/dev/null 2>&1"
  if crontab -l 2>/dev/null | grep -qF "$HOOKS_DEST/index/reindex.sh"; then
    skip "reindex cron already scheduled"
  else
    ( crontab -l 2>/dev/null; echo "0 * * * * $CRON_CMD" ) | crontab - && ok "hourly reindex cron scheduled"
  fi
else
  skip "cron skipped (--no-cron or crontab unavailable)"
fi

# ---- done -------------------------------------------------------------------------------------
say ""
say "✓ Agent OS installed."
say "  Vault preserved if it already existed; adapter, settings, and bootloader are idempotent."
say "  Tip: put the unified CLI on PATH →  ln -s $OS/bin/agentos ~/.local/bin/agentos   (then: agentos doctor)"
say "  Next: open a NEW Claude Code session — the nameless orchestrator boots and runs genesis"
say "  (names itself, forks the constitution into your words, writes your first memories)."
