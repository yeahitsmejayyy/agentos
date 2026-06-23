#!/bin/bash
# Agent OS — resync the installed Claude Code adapter from the repo source of truth.
#
# Copies ONLY the adapter CODE (hooks + skills) into ~/.claude, so an existing install
# stops running stale code after the repo changes. Re-runnable and idempotent.
#
# DOES NOT TOUCH (by design — code is disposable, memory is sacred):
#   • the memory vault  ~/.mem            (your notes — source of truth)
#   • the recall index  ~/.mem/.index     (derived; rebuilt from the vault anyway)
#   • ~/.claude/settings.json             (hand-merged; holds your other hooks)
#   • ~/.claude/CLAUDE.md                 (append-only; your own instructions)
#   • your other skills in ~/.claude/skills (only Agent OS skills are refreshed)
#
# Usage:  bash harness/claude-code/update.sh        (run from anywhere)
# Env:    AGENT_OS_HOME to override repo location (else inferred from this script's path)
set -euo pipefail

# Repo root = two dirs up from this script (harness/claude-code/update.sh -> repo root).
# Inferred, not hard-coded, so it works wherever the repo lives (portable / locale-neutral).
OS="${AGENT_OS_HOME:-$(cd "$(dirname "$0")/../.." && pwd)}"
SRC="$OS/harness/claude-code"
DEST_HOOKS="$HOME/.claude/hooks/agent-os"
DEST_SKILLS="$HOME/.claude/skills"

[ -d "$SRC/hooks" ] && [ -d "$SRC/skills" ] || { echo "✗ repo source not found at $SRC" >&2; exit 1; }

mkdir -p "$DEST_HOOKS" "$DEST_SKILLS"

# Refresh adapter code (additive overwrite of Agent OS files only; never a delete).
cp -R "$SRC"/hooks/*  "$DEST_HOOKS"/
cp -R "$SRC"/skills/* "$DEST_SKILLS"/
chmod +x "$DEST_HOOKS"/*.sh "$DEST_HOOKS"/index/*.sh "$DEST_HOOKS"/index/*.py 2>/dev/null || true

# Clear stale Python bytecode so the freshly-copied source is what actually runs.
find "$DEST_HOOKS" -name '__pycache__' -type d -prune -exec rm -rf {} + 2>/dev/null || true

echo "✓ Agent OS adapter resynced from: $OS"
echo "    hooks  → $DEST_HOOKS"
echo "    skills → $DEST_SKILLS  (Agent OS skills only)"
echo "  Untouched: ~/.mem (vault + index), settings.json, CLAUDE.md, your other skills."
