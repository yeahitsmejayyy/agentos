# Unified `agentos` CLI + the generic cli adapter — proves the SAME OS + Mind boot on a non-Claude-Code
# host, driven through the one front door (`bin/agentos`). HOME-isolated; touches no real config.
BIN="$SEED_ROOT/bin/agentos"
T="$(newtmp)"

# `agentos install cli` routes to the cli adapter installer → instantiates the shared Mind
env HOME="$T" bash "$BIN" install cli >/dev/null 2>&1
check "agentos install cli: instantiates the shared mind (.mem)"  test -d "$T/.agentos/.mem"
check "agentos install cli: instantiates the shared mind (.proc)" test -d "$T/.agentos/.proc"

# `agentos boot` delegates to the cli adapter runtime — FIRST RUN + orchestrator + constitution, no Claude Code
out="$(env HOME="$T" bash "$BIN" boot 2>/dev/null || true)"
contains "agentos boot: FIRST RUN before genesis"             "$out" "FIRST RUN"
contains "agentos boot: includes the orchestrator definition" "$out" "Orchestrator"
contains "agentos boot: includes the CONSTITUTION frame"      "$out" "CONSTITUTION"

# named instance + grown agent → boot injects them, drops FIRST RUN
mkdir -p "$T/.agentos/.mem/self" "$T/.agentos/.mem/agents/researcher"
printf '# Identity\n- Orchestrator name: Cli-bot\n' > "$T/.agentos/.mem/self/IDENTITY.md"
printf '# Researcher\n## Role\nThe research specialist.\n' > "$T/.agentos/.mem/agents/researcher/AGENT.md"
out="$(env HOME="$T" bash "$BIN" boot 2>/dev/null || true)"
absent   "agentos boot: no FIRST RUN once named"  "$out" "FIRST RUN"
contains "agentos boot: injects the identity"     "$out" "Cli-bot"
contains "agentos boot: surfaces the grown team"  "$out" "researcher"

# capture floor through the front door
env HOME="$T" bash "$BIN" capture "wrapping a test" >/dev/null 2>&1
if ls "$T"/.agentos/.mem/sessions/*cli-*.md >/dev/null 2>&1; then
  ok "agentos capture: writes a raw session note"
else
  no "agentos capture: writes a raw session note"
fi

# dispatcher routing
help="$(bash "$BIN" help 2>/dev/null || true)"
contains "agentos help: lists manage + run verbs" "$help" "boot"
bash "$BIN" bogus-cmd >/dev/null 2>&1; rc=$?
eq "agentos: unknown command exits non-zero" "1" "$rc"
# a not-yet-built feature routes gracefully (backup arrives in task 34)
env HOME="$T" bash "$BIN" backup >/dev/null 2>&1; rc=$?
eq "agentos backup: routes (not-available until built)" "1" "$rc"

rm -rf "$T"
