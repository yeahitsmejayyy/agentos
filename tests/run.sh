#!/bin/bash
# Agent OS — regression suite (deterministic layer). One command, no LLM, no network.
# Covers: seed purity · the memory index · the recall/reindex hooks · the install lifecycle.
# Usage:  bash tests/run.sh        (exit 0 = all pass, 1 = something failed)
cd "$(dirname "$0")" || exit 2
source ./lib.sh

echo "Agent OS — regression suite"
echo "  seed: $SEED_ROOT"
echo
for t in test_*.sh; do
  [ -e "$t" ] || continue
  printf '\033[1m▸ %s\033[0m\n' "$t"
  source "./$t"
  echo
done

echo "──────────────────────────────────────────"
total=$((PASS + FAIL))
if [ "$FAIL" -eq 0 ]; then
  printf '\033[32m✓ ALL PASS\033[0m — %d checks\n' "$total"
  exit 0
else
  printf '\033[31m✗ %d of %d checks FAILED\033[0m\n' "$FAIL" "$total"
  for f in "${FAILED[@]}"; do printf '   - %s\n' "$f"; done
  exit 1
fi
