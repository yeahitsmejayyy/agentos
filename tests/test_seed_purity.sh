# Seed purity — static invariants on the shipped seed. Catches regressions like a personal value
# creeping back into the constitution, an eager PROFILE stub returning, or a leaked stack standard.
C="$SEED_ROOT/shared/CONSTITUTION.md"

# --- Constitution: blank where the user owns it, engine + floor where the OS does ---
p1="$(sed -n '/## Part 1/,/## Part 2/p' "$C")"
absent  "constitution: Part 1 ships empty (no value bullets)"        "$p1" "- **"
absent  "constitution: North Star not hardcoded to 'objective truth'" "$(cat "$C")" "North star: objective truth"
p3="$(sed -n '/## Part 3/,/## How it governs/p' "$C")"
contains "constitution: Part 3 keeps the safety floor (never deceive)" "$p3" "Never deceive"
contains "constitution: Part 3 keeps the safety floor (never harm)"    "$p3" "Never harm people"
absent  "constitution: Part 3 has no assumed personal hard-lines (no slop line)" "$p3" "Never ship slop"

# --- No personal-worldview / stack leaks anywhere shipped ---
grep_absent "no personal-value / stack leaks in the seed" \
  "side of light|entrepreneurial|craft over slop|wielded for good|tanstack" \
  "$SEED_ROOT/shared" "$SEED_ROOT/agents" "$SEED_ROOT/memory" "$SEED_ROOT/procedural" \
  "$SEED_ROOT/harness/claude-code/skills" "$SEED_ROOT/harness/claude-code/GENESIS.md"

# --- Orchestrator-only seed ---
agentdirs="$(ls "$SEED_ROOT/agents" 2>/dev/null | sort | tr '\n' ' ')"
contains "agents/: ships orchestrator+watcher+_template only" "$agentdirs" "_template orchestrator watcher "
absent   "agents/: no grown workers shipped"                  "$agentdirs" "researcher"

# --- Agent memory is lazy: template ships just the definition ---
tmpl="$(ls "$SEED_ROOT/memory/agents/_template" 2>/dev/null | tr '\n' ' ')"
contains "agent template: ships AGENT.md (the definition)"      "$tmpl" "AGENT.md"
absent   "agent template: no eager PROFILE.md stub (lazy memory)" "$tmpl" "PROFILE.md"

# --- Uppercase self-file convention (no lowercase identity/constitution/about-me refs) ---
grep_absent_cs "self files use the UPPERCASE convention (no lowercase refs)" \
  "self/(identity|constitution|about-me)\.md" \
  "$SEED_ROOT/shared" "$SEED_ROOT/agents" "$SEED_ROOT/memory" "$SEED_ROOT/harness"

# --- Standards ship near-empty ---
grep_absent "standards ship near-empty (no live bun principle)" "default to \*\*bun\*\*|^### Package manager" "$SEED_ROOT/procedural/standards.md"

# --- Watcher: all six proposal kinds present + consistent ---
loop="$(cat "$SEED_ROOT/agents/watcher/LOOP.md")"
for k in promote-standard add-agent add-skill realign propose-self-update propose-constitution-update; do
  contains "watcher LOOP: kind '$k' present" "$loop" "$k"
done
grep_absent "watcher: no stale 'about-me' refs (renamed to PROFILE.md)" "self/about-me" \
  "$SEED_ROOT/agents/watcher" "$SEED_ROOT/harness/claude-code/skills/watch" "$SEED_ROOT/harness/claude-code/skills/watch-review"

# --- Agent template carries the full RISEN frame ---
risen="$(cat "$SEED_ROOT/memory/agents/_template/AGENT.md")"; risen_ok=1
for sec in "## Role" "## Instructions" "## Steps" "## End Goal" "## Narrowing"; do
  case "$risen" in *"$sec"*) ;; *) risen_ok=0;; esac
done
eq "agent template: carries the full RISEN frame" "1" "$risen_ok"

# --- All seven skills ship ---
sk_ok=1
for s in genesis watch watch-review create-agent wrap-session consolidate-memory promote-standard; do
  [ -f "$SEED_ROOT/harness/claude-code/skills/$s/SKILL.md" ] || sk_ok=0
done
eq "all 7 skills ship in the adapter" "1" "$sk_ok"

# --- Settings snippet declares all 5 hook events ---
snip="$(cat "$SEED_ROOT/harness/claude-code/settings.snippet.json")"; ev_ok=1
for ev in SessionStart UserPromptSubmit SessionEnd PreCompact PostToolUse; do
  case "$snip" in *"\"$ev\""*) ;; *) ev_ok=0;; esac
done
eq "settings snippet: declares all 5 hook events" "1" "$ev_ok"

# --- .gitignore protects mind / index / creds / personal tooling ---
gi="$(cat "$SEED_ROOT/.gitignore")"; gi_ok=1
for p in ".agentos/" "*.db" "seedtest.sh" "CLAUDE.md"; do
  case "$gi" in *"$p"*) ;; *) gi_ok=0;; esac
done
eq ".gitignore: protects mind, index, creds, personal harness" "1" "$gi_ok"

# --- Repo hygiene: nothing sensitive is tracked ---
if git -C "$SEED_ROOT" ls-files 2>/dev/null | grep -qE "\.credentials|^\.agentos/|/seedtest\.sh$|index\.db$"; then
  no "repo hygiene: no mind/creds/index/seedtest tracked"
else
  ok "repo hygiene: no mind/creds/index/seedtest tracked"
fi

# --- No author real-name anywhere in the repo. The pattern is built from two pieces so THIS file
#     never contains the literal string (otherwise the check would match itself). ---
nm="P""J"
if grep -rwnq "$nm" "$SEED_ROOT/shared" "$SEED_ROOT/agents" "$SEED_ROOT/memory" "$SEED_ROOT/procedural" \
     "$SEED_ROOT/harness" "$SEED_ROOT/tests" "$SEED_ROOT/README.md" "$SEED_ROOT/LICENSE" 2>/dev/null; then
  no "no author real-name anywhere in the repo"
else
  ok "no author real-name anywhere in the repo"
fi
