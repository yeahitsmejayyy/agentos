# Install lifecycle — install → doctor → uninstall (vault-safe) → doctor → --purge, fully HOME-isolated
# (never touches the real ~/.claude or ~/.agentos). --no-cron so it never touches the real crontab.
T="$(newtmp)"

# 1 · install
env HOME="$T" bash "$HARNESS/install.sh" --no-cron >/dev/null 2>&1
check "install: adapter hooks present" test -d "$T/.claude/hooks/agent-os"
check "install: skills present"        test -f "$T/.claude/skills/genesis/SKILL.md"
check "install: mind instantiated"     test -d "$T/.agentos/.mem"
check "install: bootloader wired"      grep -qF ">>> Agent OS" "$T/.claude/CLAUDE.md"

# 2 · doctor → healthy
env HOME="$T" bash "$HARNESS/doctor.sh" >/dev/null 2>&1; rc=$?
eq "doctor: healthy after install (exit 0)" "0" "$rc"

# 2b · all seven skills installed
sk_ok=1; for s in genesis watch watch-review create-agent wrap-session consolidate-memory promote-standard; do
  [ -f "$T/.claude/skills/$s/SKILL.md" ] || sk_ok=0
done
eq "install: all 7 skills installed" "1" "$sk_ok"

# 2c · settings.json wires all 5 hook events, ABSOLUTE paths (no literal ~/.claude)
if have python3; then
  if python3 - "$T/.claude/settings.json" <<'PY' >/dev/null 2>&1
import json,sys
h=json.load(open(sys.argv[1])).get("hooks",{})
for ev in ("SessionStart","UserPromptSubmit","SessionEnd","PreCompact","PostToolUse"): assert ev in h, ev
cmds=[x.get("command","") for es in h.values() for e in es for x in e.get("hooks",[]) if "agent-os" in (x.get("command") or "")]
assert cmds, "no agent-os hooks"
assert not any("~/.claude" in c for c in cmds), "literal ~/.claude not substituted"
PY
  then ok "install: 5 hook events wired with absolute paths"; else no "install: 5 hook events wired with absolute paths"; fi
fi

# 2d · idempotency — re-install, expect exactly ONE bootloader block and no duplicate hooks
env HOME="$T" bash "$HARNESS/install.sh" --no-cron >/dev/null 2>&1
eq "install: idempotent — exactly one CLAUDE.md block" "1" "$(grep -cF '>>> Agent OS' "$T/.claude/CLAUDE.md")"
if have python3; then
  if python3 - "$T/.claude/settings.json" <<'PY' >/dev/null 2>&1
import json,sys
h=json.load(open(sys.argv[1])).get("hooks",{})
# dedup is PER EVENT — the same hook legitimately runs on two events (capture-session: SessionEnd+PreCompact)
for ev,es in h.items():
    c=[x.get("command","") for e in es for x in e.get("hooks",[]) if "agent-os" in (x.get("command") or "")]
    assert len(c)==len(set(c)), f"duplicate agent-os hook in {ev} after 2nd install"
PY
  then ok "install: idempotent — no duplicate hooks on re-run"; else no "install: idempotent — no duplicate hooks on re-run"; fi
fi

# 3 · inject a foreign hook + a model setting (must survive uninstall)
if have python3; then
python3 - "$T/.claude/settings.json" <<'PY'
import json,sys
p=sys.argv[1]; d=json.load(open(p))
d.setdefault("hooks",{}).setdefault("SessionStart",[]).append(
  {"matcher":"","hooks":[{"type":"command","command":"echo FOREIGN_OWNER"}]})
d["model"]="opus"; json.dump(d,open(p,"w"),indent=2)
PY
fi

# 4 · uninstall (no --purge) — vault-safe, other owners preserved
env HOME="$T" bash "$HARNESS/uninstall.sh" >/dev/null 2>&1; rc=$?
eq    "uninstall: exit 0"                       "0" "$rc"
check "uninstall: adapter hooks removed"        test ! -d "$T/.claude/hooks/agent-os"
check "uninstall: agent-os skills removed"      test ! -d "$T/.claude/skills/genesis"
check "uninstall: VAULT-SAFE — mind preserved"  test -d "$T/.agentos/.mem"
if grep -qF ">>> Agent OS" "$T/.claude/CLAUDE.md" 2>/dev/null; then no "uninstall: CLAUDE.md block removed"; else ok "uninstall: CLAUDE.md block removed"; fi
if have python3; then
  if python3 - "$T/.claude/settings.json" <<'PY' >/dev/null 2>&1
import json,sys
d=json.load(open(sys.argv[1]))
ss=[x.get("command","") for e in d.get("hooks",{}).get("SessionStart",[]) for x in e.get("hooks",[])]
assert "echo FOREIGN_OWNER" in ss      # other owner survived
assert not any("agent-os" in c for c in ss)   # ours gone
assert d.get("model")=="opus"          # other settings survived
PY
  then ok "uninstall: foreign hook + settings preserved, ours removed"
  else no "uninstall: foreign hook + settings preserved, ours removed"; fi
fi

# 5 · doctor → unhealthy after uninstall, but mind still there
env HOME="$T" bash "$HARNESS/doctor.sh" >/dev/null 2>&1; rc=$?
eq "doctor: unhealthy after uninstall (exit 1)" "1" "$rc"

# 6 · reinstall, then --purge → mind gone
env HOME="$T" bash "$HARNESS/install.sh" --no-cron >/dev/null 2>&1
env HOME="$T" bash "$HARNESS/uninstall.sh" --purge >/dev/null 2>&1
check "uninstall --purge: mind removed" test ! -e "$T/.agentos"

rm -rf "$T"
