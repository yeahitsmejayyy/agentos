#!/bin/bash
# Agent OS — doctor: a read-only health check of an install. Turns INSTALL.md §6 "verify" into a
# runnable diagnostic — nothing is changed. Exit 0 = healthy, 1 = problems found.
#
# Usage:  bash harness/claude-code/doctor.sh
set -uo pipefail

OS="$(cd "$(dirname "$0")/../.." && pwd)"
HOME_DIR="${AGENT_OS_HOME:-$HOME/.agentos}"
MEM="${AGENT_OS_MEM:-$HOME_DIR/.mem}"
PROC="${AGENT_OS_PROC:-$HOME_DIR/.proc}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
HOOKS_DEST="$CLAUDE_DIR/hooks/agent-os"
SKILLS_DEST="$CLAUDE_DIR/skills"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDEMD="$CLAUDE_DIR/CLAUDE.md"
MARK="# >>> Agent OS (managed — do not duplicate) >>>"
FAIL=0; WARN=0
say(){ printf '%s\n' "$*"; }
ok(){   printf '  \033[32m✓\033[0m %s\n' "$*"; }
bad(){  printf '  \033[31m✗\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }
warn(){ printf '  \033[33m!\033[0m %s\n' "$*"; WARN=$((WARN+1)); }

say "Agent OS doctor — checking install"
say "  mind:   $HOME_DIR"
say "  config: $CLAUDE_DIR"
say ""

say "deps"
command -v python3 >/dev/null && ok "python3" || bad "python3 missing (recall + index need it)"
command -v jq >/dev/null && ok "jq" || warn "jq missing (python3 fallback is used — fine)"

say "mind"
[ -d "$MEM" ]  && ok ".mem present"  || bad ".mem missing ($MEM) — run install.sh"
[ -d "$PROC" ] && ok ".proc present" || bad ".proc missing ($PROC)"
[ -f "$MEM/.index/index.db" ] && ok "recall index built" || warn "no index yet (recall falls back to grep until a reindex runs)"

say "adapter hooks"
for h in recall-orient recall-prompt capture-session reindex-on-write; do
  [ -f "$HOOKS_DEST/$h.sh" ] && ok "$h.sh" || bad "missing hook: $h.sh"
done
[ -f "$HOOKS_DEST/index/mem_index.py" ] && ok "index tools" || bad "index tools missing"

say "skills"
for s in genesis watch watch-review wrap-session consolidate-memory promote-standard; do
  [ -f "$SKILLS_DEST/$s/SKILL.md" ] && ok "$s" || bad "missing skill: $s"
done

say "settings.json (hooks wired + paths resolve)"
if [ -f "$SETTINGS" ] && command -v python3 >/dev/null; then
  if python3 - "$SETTINGS" <<'PY'
import json, sys, os, shlex
try: h = json.load(open(sys.argv[1])).get("hooks", {})
except Exception: print("    cannot parse settings.json"); sys.exit(1)
rc = 0
for ev in ("SessionStart", "UserPromptSubmit", "SessionEnd", "PostToolUse"):
    if ev not in h: print(f"    missing hook event: {ev}"); rc = 1
for ev, entries in h.items():
    for e in entries:
        for hk in e.get("hooks", []):
            c = hk.get("command", "") or ""
            if "/hooks/agent-os/" in c:
                fp = next((p for p in shlex.split(c) if p.endswith(".sh")), "")
                if fp and not os.path.exists(fp): print(f"    dead hook path: {fp}"); rc = 1
sys.exit(rc)
PY
  then ok "all hook events present; agent-os commands resolve"; else bad "settings.json hook issues (above)"; fi
else
  bad "no settings.json (run install.sh)"
fi

say "bootloader (CLAUDE.md)"
if [ -f "$CLAUDEMD" ] && grep -qF "$MARK" "$CLAUDEMD"; then
  ok "orchestrator wired"
  miss=0
  while IFS= read -r f; do
    [ -n "$f" ] && { [ -f "$f" ] || { bad "@import target missing: $f"; miss=1; }; }
  done < <(awk '/# >>> Agent OS/{f=1} f&&/^@/{sub(/^@/,"");print} /# <<< Agent OS/{f=0}' "$CLAUDEMD")
  [ $miss = 0 ] && ok "@import targets resolve"
else
  bad "orchestrator not wired in CLAUDE.md (run install.sh)"
fi

say "genesis state"
[ -f "$MEM/self/identity.md" ] && ok "named instance (genesis done)" || warn "no identity yet — first boot will run genesis"

say ""
if [ $FAIL -eq 0 ]; then say "✓ healthy — 0 problems, $WARN warning(s)"; exit 0
else say "✗ unhealthy — $FAIL problem(s), $WARN warning(s) (see above)"; exit 1; fi
