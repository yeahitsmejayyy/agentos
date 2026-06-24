#!/bin/bash
# Agent OS — per-prompt recall (UserPromptSubmit). stdout is injected as context.
# Prefers the local semantic index; falls back to grep if the index isn't built.
set -euo pipefail
MEM_DIR="${AGENT_OS_MEM:-${AGENT_OS_HOME:-$HOME/.agentos}/.mem}"
DIR="$(cd "$(dirname "$0")" && pwd)"
read -t 5 HOOK_JSON || HOOK_JSON='{}'
jget(){ local json="$1"; shift
  if command -v jq >/dev/null 2>&1; then
    for k in "$@"; do v=$(printf '%s' "$json" | jq -r --arg k "$k" '.[$k] // empty' 2>/dev/null); [ -n "${v:-}" ] && { printf '%s' "$v"; return; }; done
  elif command -v python3 >/dev/null 2>&1; then
    for k in "$@"; do v=$(printf '%s' "$json" | python3 -c "import sys,json;print(json.load(sys.stdin).get('$k',''))" 2>/dev/null); [ -n "${v:-}" ] && { printf '%s' "$v"; return; }; done
  fi
}
PROMPT=$(jget "$HOOK_JSON" prompt user_prompt userPrompt)
[ -z "${PROMPT:-}" ] && exit 0
if [ -f "$MEM_DIR/.index/index.db" ] && command -v python3 >/dev/null 2>&1; then
  OUT=$(AGENT_OS_MEM="$MEM_DIR" python3 "$DIR/index/mem_query.py" "$PROMPT" -k 5 2>/dev/null || true)
  [ -n "${OUT:-}" ] && { printf '%s\n' "$OUT"; exit 0; }
fi
KW=$(printf '%s' "$PROMPT" | tr 'A-Z' 'a-z' | grep -oE '[a-z]{4,}' | sort -u | head -8 | paste -sd'|' - || true)
[ -z "${KW:-}" ] && exit 0
HITS=$(grep -rilE "$KW" "$MEM_DIR"/{self,projects,knowledge,decisions} 2>/dev/null | head -5 || true)
[ -z "${HITS:-}" ] && exit 0
echo "## Possibly relevant memory (grep fallback)"
while IFS= read -r f; do [ -z "$f" ] && continue; echo "### ${f#$MEM_DIR/}"; sed -n '1,20p' "$f"; echo; done <<< "$HITS"
exit 0
