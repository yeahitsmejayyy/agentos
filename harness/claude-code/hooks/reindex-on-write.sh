#!/bin/bash
# Agent OS — recall freshness (PostToolUse on Write/Edit). When a vault note is written, incrementally
# re-embed it so it's recallable THIS session, not an hour later when the cron runs. No-op for any write
# outside the vault. This is the "enforce in the harness" half of recall: gestures just write notes; the
# index stays fresh on its own, no skill has to remember a reindex step.
set -uo pipefail
MEM_DIR="${AGENT_OS_MEM:-${AGENT_OS_HOME:-$HOME/.agentos}/.mem}"
PROC_DIR="${AGENT_OS_PROC:-${AGENT_OS_HOME:-$HOME/.agentos}/.proc}"
DIR="$(cd "$(dirname "$0")" && pwd)"

# read the whole hook payload (the Write tool's input carries the full file content — can be multi-line,
# so `read` would truncate it; `cat` takes all of stdin)
HOOK_JSON=$(cat 2>/dev/null || true)
[ -z "${HOOK_JSON:-}" ] && exit 0

# the path the tool just wrote (PostToolUse nests the tool params under tool_input)
FP=""
if command -v jq >/dev/null 2>&1; then
  FP=$(printf '%s' "$HOOK_JSON" | jq -r '.tool_input.file_path // .tool_input.path // .tool_input.notebook_path // empty' 2>/dev/null || true)
elif command -v python3 >/dev/null 2>&1; then
  FP=$(printf '%s' "$HOOK_JSON" | python3 -c "import sys,json
try: d=json.load(sys.stdin)
except Exception: d={}
ti=d.get('tool_input',{}) if isinstance(d,dict) else {}
print(ti.get('file_path') or ti.get('path') or ti.get('notebook_path') or '')" 2>/dev/null || true)
fi
[ -z "${FP:-}" ] && exit 0

# only act when a Markdown note landed inside the vault (.mem or .proc). case globs span '/'.
case "$FP" in
  "$MEM_DIR"/*.md|"$PROC_DIR"/*.md) ;;
  *) exit 0 ;;
esac

# incremental re-embed (only changed files) — cheap; the hourly cron still does full upkeep + graph links
command -v python3 >/dev/null 2>&1 || exit 0
AGENT_OS_MEM="$MEM_DIR" AGENT_OS_PROC="$PROC_DIR" python3 "$DIR/index/mem_index.py" >/dev/null 2>&1 || true
exit 0
