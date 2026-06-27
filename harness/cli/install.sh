#!/bin/bash
# Agent OS — generic CLI adapter installer. Instantiates the MIND (the same skeletons every adapter uses,
# proving the Mind is adapter-independent) and makes the `agentos` entrypoint runnable. No host hooks to
# wire — this adapter is driven by running `agentos` directly.
#
# Usage:  bash harness/cli/install.sh
set -euo pipefail
OS="$(cd "$(dirname "$0")/../.." && pwd)"
HOME_DIR="${AGENT_OS_HOME:-$HOME/.agentos}"
MEM="${AGENT_OS_MEM:-$HOME_DIR/.mem}"
PROC="${AGENT_OS_PROC:-$HOME_DIR/.proc}"
ok(){ printf '  \033[32m✓\033[0m %s\n' "$*"; }
skip(){ printf '  \033[33m•\033[0m %s\n' "$*"; }

mkdir -p "$HOME_DIR"
if [ -e "$MEM" ]; then skip "vault exists — preserved ($MEM)"; else cp -R "$OS/memory" "$MEM"; ok "memory skeleton → $MEM"; fi
if [ -e "$PROC" ]; then skip "standards exist — preserved ($PROC)"; else cp -R "$OS/procedural" "$PROC"; ok "procedural skeleton → $PROC"; fi
chmod +x "$OS/harness/cli/run" "$OS/bin/agentos" 2>/dev/null || true
ok "agentos CLI + cli runtime ready"

echo
echo "✓ Generic CLI adapter installed. The Mind (${HOME_DIR}) is shared with any other adapter — unchanged."
echo "  Boot:     $OS/bin/agentos boot"
echo "  On PATH:  ln -s $OS/bin/agentos ~/.local/bin/agentos   # then just: agentos boot"
echo "  Wire it:  set 'agentos boot' as your host's system message; run 'agentos recall' before each"
echo "            turn and prepend its output; run 'agentos capture' at session end."
