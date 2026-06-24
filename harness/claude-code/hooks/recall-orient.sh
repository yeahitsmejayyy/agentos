#!/bin/bash
# Agent OS — orientation recall (SessionStart). stdout is injected as context.
# Cheap always-load tier: the memory index + the user model, plus the standards
# library map so the producing half (.proc) is discoverable from the first turn.
set -euo pipefail
MEM_DIR="${AGENT_OS_MEM:-${AGENT_OS_HOME:-$HOME/.agentos}/.mem}"
PROC_DIR="${AGENT_OS_PROC:-${AGENT_OS_HOME:-$HOME/.agentos}/.proc}"

# First run? No identity written yet → the orchestrator must conduct genesis.
if [ ! -f "$MEM_DIR/self/identity.md" ]; then
  echo "## FIRST RUN — genesis not yet done"
  echo "This Agent OS has no identity yet (no \`self/identity.md\`). You are the **nameless"
  echo "orchestrator**. Your first and only job this session is to conduct **genesis**: run the"
  echo "\`genesis\` skill — name yourself, get to know the user, fork the CONSTITUTION into their"
  echo "words, and write the first \`self/\` memories. Do that before anything else."
  echo
fi

[ -f "$MEM_DIR/home.md" ] && { echo "## Memory index (.mem/home.md)"; cat "$MEM_DIR/home.md"; echo; }

# The forked CONSTITUTION is the law — inject it in FULL (not under the capped self/ block below).
[ -f "$MEM_DIR/self/constitution.md" ] && { echo "## Constitution (the user's forked law — self/constitution.md)"; cat "$MEM_DIR/self/constitution.md"; echo; }

if [ -d "$MEM_DIR/self" ]; then
  echo "## Self (identity + user model)"
  find "$MEM_DIR/self" -name '*.md' ! -name '_index.md' ! -name 'constitution.md' -exec cat {} \; 2>/dev/null | head -c 4000
  echo
fi

# Watcher inbox — surface a COUNT of waiting proposals (pure-pull; the Watcher never pushes).
WINBOX="$MEM_DIR/agents/watcher/inbox"
if [ -d "$WINBOX" ]; then
  WCOUNT=$(grep -rlE '^status: (pending|snoozed)' "$WINBOX" 2>/dev/null | wc -l | tr -d ' ')
  if [ "${WCOUNT:-0}" -gt 0 ]; then
    echo "## Watcher — $WCOUNT proposal(s) waiting"
    echo "Run \`/watch-review\` to approve / modify / reject / snooze. (The Watcher never acts on its own.)"
    echo
  fi
fi
# Standards library (.proc) — categorical "here's what standards exist", cheaply.
[ -f "$PROC_DIR/home.md" ] && { echo "## Standards index (.proc/home.md)"; cat "$PROC_DIR/home.md"; echo; }
[ -f "$PROC_DIR/standards.md" ] && { echo "## Standards (seed — principles)"; head -c 3000 "$PROC_DIR/standards.md"; echo; }
exit 0
