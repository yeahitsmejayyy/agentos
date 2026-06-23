#!/bin/bash
# Agent OS — refresh the local memory index AND the Obsidian graph links.
# Indexes both stores: .mem (recall) and .proc (standards discovery).
# Run by cron or by hand:  ./reindex.sh [--rebuild]
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
export AGENT_OS_HOME="${AGENT_OS_HOME:-$HOME/.agentos}"   # one portable unit: stores nest here
export AGENT_OS_MEM="${AGENT_OS_MEM:-$AGENT_OS_HOME/.mem}"
export AGENT_OS_PROC="${AGENT_OS_PROC:-$AGENT_OS_HOME/.proc}"
python3 "$DIR/mem_index.py" "$@"   # vector index (recall + .proc discovery)
python3 "$DIR/mem_links.py"        # Obsidian [[links]] (graph view, both stores)
