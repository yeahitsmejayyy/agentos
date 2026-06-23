#!/bin/bash
# Agent OS — deterministic capture (SessionEnd). Dumps a raw session note to the
# vault. The rich summary comes from the wrap-session skill; this is the floor.
set -euo pipefail
MEM_DIR="${AGENT_OS_MEM:-${AGENT_OS_HOME:-$HOME/.agentos}/.mem}"
read -t 5 HOOK_JSON || HOOK_JSON='{}'
# field getter tolerant of jq-missing and snake/camel name variants
jget(){ local json="$1"; shift
  if command -v jq >/dev/null 2>&1; then
    for k in "$@"; do v=$(printf '%s' "$json" | jq -r --arg k "$k" '.[$k] // empty' 2>/dev/null); [ -n "${v:-}" ] && { printf '%s' "$v"; return; }; done
  elif command -v python3 >/dev/null 2>&1; then
    for k in "$@"; do v=$(printf '%s' "$json" | python3 -c "import sys,json;print(json.load(sys.stdin).get('$k',''))" 2>/dev/null); [ -n "${v:-}" ] && { printf '%s' "$v"; return; }; done
  fi
}
SID=$(jget "$HOOK_JSON" session_id sessionId); SID=${SID:-unknown}
REASON=$(jget "$HOOK_JSON" reason); REASON=${REASON:-n/a}
TRANSCRIPT=$(jget "$HOOK_JSON" transcript_path transcriptPath)
DATE=$(date -u +%Y-%m-%d)                  # date-only, for the filename (colons are unsafe in paths)
STAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)       # full ISO 8601 UTC timestamp, for the audit trail
mkdir -p "$MEM_DIR/sessions"
OUT="$MEM_DIR/sessions/${DATE}_${SID}.md"
{
  echo "---"; echo "memory_type: episodic"; echo "type: session"; echo "date: $STAMP"; echo "tags: [raw-capture]"
  echo "agent:"; echo "project:"; echo "status: active"; echo "---"; echo
  echo "# Session $SID (raw capture)"; echo
  echo "**Ended:** $STAMP · **Reason:** $REASON"; echo
  if [ -n "${TRANSCRIPT:-}" ] && [ -f "$TRANSCRIPT" ]; then
    echo "## Transcript (tail)"; echo '```'; tail -n 200 "$TRANSCRIPT"; echo '```'
  fi
} > "$OUT"
exit 0
