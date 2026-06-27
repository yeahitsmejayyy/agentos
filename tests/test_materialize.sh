# .proc materialize — install a module's code into a target project (deterministic, no LLM).
T="$(newtmp)"; PROC="$T/.proc"; TARGET="$T/project"
mkdir -p "$PROC/modules/data-table/src" "$PROC/modules/data-table/tests"
printf -- '---\nkind: module\nmaterializable: true\n---\n# data-table\n' > "$PROC/modules/data-table/README.md"
printf 'export const table = 1\n'        > "$PROC/modules/data-table/src/table.js"
printf 'test("table", () => {})\n'       > "$PROC/modules/data-table/tests/table.test.js"
# a recall-only entry (must be refused)
mkdir -p "$PROC/modules/just-a-note"
printf -- '---\nkind: pattern\nmaterializable: false\n---\n# note\n' > "$PROC/modules/just-a-note/README.md"

AGENT_OS_PROC="$PROC" bash "$HARNESS/materialize.sh" data-table "$TARGET" >/dev/null 2>&1
check "materialize: installs the module's src/"  test -f "$TARGET/src/table.js"
check "materialize: installs the bundled tests/" test -f "$TARGET/tests/table.test.js"

# gating: a non-materializable entry is refused
AGENT_OS_PROC="$PROC" bash "$HARNESS/materialize.sh" just-a-note "$T/p2" >/dev/null 2>&1; rc=$?
eq "materialize: refuses a recall-only entry" "1" "$rc"

# unknown entry is refused
AGENT_OS_PROC="$PROC" bash "$HARNESS/materialize.sh" nope "$T/p3" >/dev/null 2>&1; rc=$?
eq "materialize: refuses an unknown entry" "1" "$rc"

# no-clobber: a local edit is never overwritten by a re-materialize
printf 'LOCAL EDIT\n' > "$TARGET/src/table.js"
AGENT_OS_PROC="$PROC" bash "$HARNESS/materialize.sh" data-table "$TARGET" >/dev/null 2>&1
contains "materialize: never overwrites an existing file" "$(cat "$TARGET/src/table.js" 2>/dev/null)" "LOCAL EDIT"

rm -rf "$T"
