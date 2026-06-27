# Memory index — build over a fixture vault (offline hash backend), then query it.
if ! have python3; then no "index: python3 available"; else
  T="$(newtmp)"; MEM="$T/.mem"; mkdir -p "$MEM/decisions" "$MEM/self"
  cat > "$MEM/decisions/calibration.md" <<'EOF'
---
memory_type: semantic
type: decisions
---
# Flux capacitor calibration
We always calibrate the flux capacitor to 1.21 gigawatts before any launch.
EOF
  cat > "$MEM/self/IDENTITY.md" <<'EOF'
# Identity
- Orchestrator name: Testbot
EOF

  AGENT_OS_MEM="$MEM" python3 "$HARNESS/hooks/index/mem_index.py" >/dev/null 2>&1
  check "index: build creates index.db" test -f "$MEM/.index/index.db"

  out="$(AGENT_OS_MEM="$MEM" python3 "$HARNESS/hooks/index/mem_query.py" "flux capacitor power output" -k 3 2>/dev/null || true)"
  contains "index: query prints the recall header" "$out" "Relevant memory"
  contains "index: query surfaces the relevant note" "$out" "gigawatts"

  # Privacy tiers: scratch/ is NEVER indexed; an agent's profile IS (discoverable on-demand)
  mkdir -p "$MEM/agents/researcher/scratch"
  printf -- '---\nmemory_type: semantic\n---\nZZSCRATCHSECRET ephemeral working note\n' > "$MEM/agents/researcher/scratch/secret.md"
  printf -- '---\nmemory_type: semantic\n---\nZZPROFILEFACT a learned operating note\n' > "$MEM/agents/researcher/PROFILE.md"
  AGENT_OS_MEM="$MEM" python3 "$HARNESS/hooks/index/mem_index.py" >/dev/null 2>&1
  sout="$(AGENT_OS_MEM="$MEM" python3 "$HARNESS/hooks/index/mem_query.py" "ZZSCRATCHSECRET ephemeral working" -k 8 2>/dev/null || true)"
  absent   "index: scratch/ is never indexed (truly private)"   "$sout" "ZZSCRATCHSECRET"
  pout="$(AGENT_OS_MEM="$MEM" python3 "$HARNESS/hooks/index/mem_query.py" "ZZPROFILEFACT learned operating" -k 8 2>/dev/null || true)"
  contains "index: an agent's profile IS indexed (discoverable)" "$pout" "ZZPROFILEFACT"

  rm -rf "$T"
fi
