#!/bin/bash
# Agent OS — shared test helpers. Sourced by run.sh (and each test_*.sh runs in the same shell,
# so PASS/FAIL accumulate across files). Test files must NOT `set -e` or `exit` — use the helpers.
SEED_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HARNESS="$SEED_ROOT/harness/claude-code"
: "${PASS:=0}"; : "${FAIL:=0}"; declare -a FAILED 2>/dev/null || FAILED=()

ok(){ PASS=$((PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); FAILED+=("$1"); printf '  \033[31m✗\033[0m %s\n' "$1"; }

# check DESC CMD...  → pass iff CMD exits 0
check(){ local d="$1"; shift; if "$@" >/dev/null 2>&1; then ok "$d"; else no "$d"; fi; }
# contains DESC HAYSTACK NEEDLE  → pass iff NEEDLE is a substring of HAYSTACK
contains(){ case "$2" in *"$3"*) ok "$1";; *) no "$1";; esac; }
# absent DESC HAYSTACK NEEDLE   → pass iff NEEDLE is NOT in HAYSTACK
absent(){ case "$2" in *"$3"*) no "$1";; *) ok "$1";; esac; }
# grep_absent DESC PATTERN PATHS...  → pass iff PATTERN is found nowhere (case-INsensitive)
grep_absent(){ local d="$1" pat="$2"; shift 2; if grep -rqniE "$pat" "$@" 2>/dev/null; then no "$d"; else ok "$d"; fi; }
# grep_absent_cs — same, but case-SENSITIVE (use when case is the signal, e.g. lowercase filenames)
grep_absent_cs(){ local d="$1" pat="$2"; shift 2; if grep -rqnE "$pat" "$@" 2>/dev/null; then no "$d"; else ok "$d"; fi; }
# eq DESC EXPECTED ACTUAL
eq(){ if [ "$2" = "$3" ]; then ok "$1"; else no "$1 (want '$2' got '$3')"; fi; }

newtmp(){ mktemp -d "${TMPDIR:-/tmp}/agentos-test.XXXXXX"; }
have(){ command -v "$1" >/dev/null 2>&1; }
