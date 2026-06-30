#!/bin/bash
# Agent OS — orientation recall (SessionStart). stdout is injected as context.
# Cheap always-load tier: the memory index + the user model, plus the standards
# library map so the producing half (.proc) is discoverable from the first turn.
set -euo pipefail
MEM_DIR="${AGENT_OS_MEM:-${AGENT_OS_HOME:-$HOME/.agentos}/.mem}"
PROC_DIR="${AGENT_OS_PROC:-${AGENT_OS_HOME:-$HOME/.agentos}/.proc}"

# First run? No identity written yet → the orchestrator must conduct genesis.
if [ ! -f "$MEM_DIR/self/IDENTITY.md" ]; then
  echo "## FIRST RUN — genesis not yet done"
  echo "This Agent OS has no identity yet (no \`self/IDENTITY.md\`). You are the **nameless"
  echo "orchestrator**. Your first and only job this session is to conduct **genesis**: run the"
  echo "\`genesis\` skill — name yourself, get to know the user, fork the CONSTITUTION into their"
  echo "words, and write the first \`self/\` memories. Do that before anything else."
  echo
fi

# IDENTITY FIRST — the name anchor. SessionStart hook stdout is capped when injected
# into context (oversized output is persisted to a file and only a small preview is
# injected), so identity MUST lead or it gets truncated away and the orchestrator
# boots not knowing its own name. Tiny (~0.5 KB); always survives the preview window.
[ -f "$MEM_DIR/self/IDENTITY.md" ] && { echo "## Identity (self/IDENTITY.md) — who you are"; cat "$MEM_DIR/self/IDENTITY.md"; echo; }

[ -f "$MEM_DIR/home.md" ] && { echo "## Memory index (.mem/home.md)"; cat "$MEM_DIR/home.md"; echo; }

# The forked CONSTITUTION is the law — inject it in FULL (not under the capped self/ block below).
[ -f "$MEM_DIR/self/CONSTITUTION.md" ] && { echo "## Constitution (the user's forked law — self/CONSTITUTION.md)"; cat "$MEM_DIR/self/CONSTITUTION.md"; echo; }

if [ -d "$MEM_DIR/self" ]; then
  echo "## Self (user model)"
  find "$MEM_DIR/self" -name '*.md' ! -name '_index.md' ! -name 'CONSTITUTION.md' ! -name 'IDENTITY.md' -exec cat {} \; 2>/dev/null | head -c 4000 || true
  echo
fi

# Grown team — workers the user has grown. Their AGENT.md lives in the mind (beside their memory),
# NOT in the shipped repo. Surface a lightweight roster; read the full AGENT.md before delegating.
if [ -d "$MEM_DIR/agents" ]; then
  ROSTER=""
  for d in "$MEM_DIR"/agents/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    [ "$name" = "_template" ] && continue
    [ -f "$d/AGENT.md" ] || continue   # only GROWN agents define here (shipped ones define in the repo)
    role="$(grep -A1 '^## Role' "$d/AGENT.md" 2>/dev/null | sed -n '2p' | head -c 140 || true)"
    ROSTER="${ROSTER}- **${name}** — ${role:-(see its AGENT.md)}"$'\n'
  done
  if [ -n "$ROSTER" ]; then
    echo "## Your grown team (delegate to these workers)"
    printf '%s' "$ROSTER"
    echo "Each worker's full RISEN definition is at \`.mem/agents/<name>/AGENT.md\` — read it before delegating."
    echo
  fi
fi

# Watcher inbox — surface a COUNT of waiting proposals (pure-pull; the Watcher never pushes).
WINBOX="$MEM_DIR/agents/watcher/inbox"
if [ -d "$WINBOX" ]; then
  WCOUNT=$(grep -rlE '^status: (pending|snoozed)' "$WINBOX" 2>/dev/null | wc -l | tr -d ' ' || true)
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
