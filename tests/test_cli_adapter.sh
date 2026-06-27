# Generic CLI adapter — proves the SAME OS + Mind boot on a non-Claude-Code host (HOME-isolated).
CLI="$SEED_ROOT/harness/cli"
T="$(newtmp)"

# install instantiates the shared Mind (identical skeletons — adapter-independent)
env HOME="$T" bash "$CLI/install.sh" >/dev/null 2>&1
check "cli: install instantiates the shared mind (.mem)"  test -d "$T/.agentos/.mem"
check "cli: install instantiates the shared mind (.proc)" test -d "$T/.agentos/.proc"

# boot BEFORE genesis → FIRST RUN + orchestrator + constitution frame, no Claude Code anywhere
out="$(env HOME="$T" bash "$CLI/agentos" boot 2>/dev/null || true)"
contains "cli boot: FIRST RUN before genesis"            "$out" "FIRST RUN"
contains "cli boot: includes the orchestrator definition" "$out" "Orchestrator"
contains "cli boot: includes the CONSTITUTION frame"      "$out" "CONSTITUTION"

# simulate a named instance + a grown agent → boot injects them, drops FIRST RUN
mkdir -p "$T/.agentos/.mem/self" "$T/.agentos/.mem/agents/researcher"
printf '# Identity\n- Orchestrator name: Cli-bot\n' > "$T/.agentos/.mem/self/IDENTITY.md"
printf '# Researcher\n## Role\nThe research specialist.\n' > "$T/.agentos/.mem/agents/researcher/AGENT.md"
out="$(env HOME="$T" bash "$CLI/agentos" boot 2>/dev/null || true)"
absent   "cli boot: no FIRST RUN once named"   "$out" "FIRST RUN"
contains "cli boot: injects the identity"      "$out" "Cli-bot"
contains "cli boot: surfaces the grown team"   "$out" "researcher"

# capture floor writes a session note to the shared vault
env HOME="$T" bash "$CLI/agentos" capture "wrapping a test" >/dev/null 2>&1
if ls "$T"/.agentos/.mem/sessions/*cli-*.md >/dev/null 2>&1; then
  ok "cli capture: writes a raw session note"
else
  no "cli capture: writes a raw session note"
fi

rm -rf "$T"
