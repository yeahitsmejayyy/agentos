# Watcher usage signals — recall logging (mem_query → usage.jsonl) + the summary (mem_usage).
if ! have python3; then no "usage: python3 available"; else
  T="$(newtmp)"; MEM="$T/.mem"; mkdir -p "$MEM/decisions" "$MEM/knowledge"
  printf -- '---\nmemory_type: semantic\n---\n# Flux note\nflux capacitor gigawatts calibration before launch\n' > "$MEM/decisions/hit.md"
  printf -- '---\nmemory_type: semantic\n---\n# Lonely note\nan obscure unrelated topic about xylophones\n' > "$MEM/knowledge/never.md"
  AGENT_OS_MEM="$MEM" python3 "$HARNESS/hooks/index/mem_index.py" >/dev/null 2>&1

  # recall the first note a few times → logs hits; never touch the second
  for i in 1 2 3; do
    AGENT_OS_MEM="$MEM" python3 "$HARNESS/hooks/index/mem_query.py" "flux capacitor gigawatts" -k 1 >/dev/null 2>&1
  done
  check    "usage: recall appends to usage.jsonl"        test -f "$MEM/.index/usage.jsonl"
  contains "usage: log records the recalled note"        "$(cat "$MEM/.index/usage.jsonl" 2>/dev/null)" "hit.md"

  u="$(AGENT_OS_MEM="$MEM" python3 "$HARNESS/hooks/index/mem_usage.py" 2>/dev/null || true)"
  contains "usage summary: flags the recalled note as valuable"          "$u" "hit.md"
  contains "usage summary: flags the never-recalled note (retire signal)" "$u" "never.md"
  rm -rf "$T"
fi
