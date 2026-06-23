#!/bin/bash
# Agent OS — orientation recall (SessionStart). stdout is injected as context.
# Cheap always-load tier: the memory index + the user model, plus the standards
# library map so the producing half (.proc) is discoverable from the first turn.
set -euo pipefail
MEM_DIR="${AGENT_OS_MEM:-${AGENT_OS_HOME:-$HOME/.agentos}/.mem}"
PROC_DIR="${AGENT_OS_PROC:-${AGENT_OS_HOME:-$HOME/.agentos}/.proc}"
[ -f "$MEM_DIR/home.md" ] && { echo "## Memory index (.mem/home.md)"; cat "$MEM_DIR/home.md"; echo; }
if [ -d "$MEM_DIR/self" ]; then
  echo "## Self (user model)"
  find "$MEM_DIR/self" -name '*.md' ! -name '_index.md' -exec cat {} \; 2>/dev/null | head -c 4000
  echo
fi
# Standards library (.proc) — categorical "here's what standards exist", cheaply.
[ -f "$PROC_DIR/home.md" ] && { echo "## Standards index (.proc/home.md)"; cat "$PROC_DIR/home.md"; echo; }
[ -f "$PROC_DIR/standards.md" ] && { echo "## Standards (seed — principles)"; head -c 3000 "$PROC_DIR/standards.md"; echo; }
exit 0
