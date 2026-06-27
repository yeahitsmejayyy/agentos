# Recall / reindex hooks — driven with fixture vaults + mock hook payloads (no LLM).
T="$(newtmp)"; MEM="$T/.mem"; PROC="$T/.proc"
mkdir -p "$MEM/self" "$MEM/agents/researcher" "$PROC"
RO="$HARNESS/hooks/recall-orient.sh"

# 1) recall-orient: FIRST RUN when no identity exists yet
out="$(AGENT_OS_MEM="$MEM" AGENT_OS_PROC="$PROC" bash "$RO" 2>/dev/null || true)"
contains "recall-orient: emits FIRST RUN when no IDENTITY.md" "$out" "FIRST RUN"

# 2) recall-orient: normal boot once named — injects identity, no FIRST RUN, surfaces grown roster
cat > "$MEM/self/IDENTITY.md" <<'EOF'
# Identity
- Orchestrator name: Testbot
- Speaks to: Tester
EOF
cat > "$MEM/agents/researcher/AGENT.md" <<'EOF'
# Researcher
## Role
The deep-research specialist.
EOF
out="$(AGENT_OS_MEM="$MEM" AGENT_OS_PROC="$PROC" bash "$RO" 2>/dev/null || true)"
absent   "recall-orient: no FIRST RUN once named"        "$out" "FIRST RUN"
contains "recall-orient: injects the identity"           "$out" "Testbot"
contains "recall-orient: surfaces the grown-team roster" "$out" "researcher"

# 3) reindex-on-write: path-gating — a write OUTSIDE the vault is a no-op (no index built)
echo '{"tool_input":{"file_path":"/tmp/somewhere-else.md"}}' \
  | AGENT_OS_MEM="$MEM" AGENT_OS_PROC="$PROC" bash "$HARNESS/hooks/reindex-on-write.sh" >/dev/null 2>&1
check "reindex-on-write: non-vault write is a no-op" test ! -f "$MEM/.index/index.db"

# 3b) reindex-on-write: a vault .md write DOES build the index (offline)
if have python3; then
  echo "{\"tool_input\":{\"file_path\":\"$MEM/self/IDENTITY.md\"}}" \
    | AGENT_OS_MEM="$MEM" AGENT_OS_PROC="$PROC" bash "$HARNESS/hooks/reindex-on-write.sh" >/dev/null 2>&1
  check "reindex-on-write: vault .md write builds the index" test -f "$MEM/.index/index.db"
fi

# 4) recall-prompt: grep fallback surfaces a matching note (delete the index to force the fallback path)
rm -rf "$MEM/.index"
cat > "$MEM/self/PROFILE.md" <<'EOF'
# About Tester
Tester cares about gigawatts and flux capacitors.
EOF
out="$(echo '{"prompt":"tell me about gigawatts"}' | AGENT_OS_MEM="$MEM" bash "$HARNESS/hooks/recall-prompt.sh" 2>/dev/null || true)"
contains "recall-prompt: grep fallback surfaces a matching note" "$out" "gigawatts"

# 5) recall-orient: full constitution injection + standards index + Watcher inbox count
cat > "$MEM/self/CONSTITUTION.md" <<'EOF'
# CONSTITUTION
North star: ZZ_NORTHSTAR_MARKER
EOF
mkdir -p "$MEM/agents/watcher/inbox"
printf -- '---\nstatus: pending\nkind: realign\n---\na proposal\n' > "$MEM/agents/watcher/inbox/p1.md"
printf '# .proc — Home\nZZ_STANDARDS_MARKER\n' > "$PROC/home.md"
out="$(AGENT_OS_MEM="$MEM" AGENT_OS_PROC="$PROC" bash "$RO" 2>/dev/null || true)"
contains "recall-orient: injects the forked constitution in full" "$out" "ZZ_NORTHSTAR_MARKER"
contains "recall-orient: surfaces the standards (.proc) index"    "$out" "ZZ_STANDARDS_MARKER"
contains "recall-orient: surfaces the Watcher inbox count"        "$out" "proposal(s) waiting"

# 6) capture-session: writes a raw session note (the SessionEnd floor)
echo '{"session_id":"testsess123","reason":"clear"}' | AGENT_OS_MEM="$MEM" bash "$HARNESS/hooks/capture-session.sh" >/dev/null 2>&1
note="$MEM/sessions/$(date -u +%Y-%m-%d)_testsess123.md"
check    "capture-session: writes a session note"     test -f "$note"
contains "capture-session: tags the note raw-capture" "$(cat "$note" 2>/dev/null)" "raw-capture"

rm -rf "$T"
