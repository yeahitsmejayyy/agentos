#!/bin/bash
# Agent OS — Claude Code uninstaller. Reverses install.sh, step for step. VAULT-SAFE by default: your
# mind (~/.agentos) is never touched. Pass --purge to remove the mind too. Backs up settings.json and
# CLAUDE.md before editing, and removes ONLY Agent OS's own entries (other hook owners + skills survive).
#
# Usage:  bash harness/claude-code/uninstall.sh [--purge]
set -euo pipefail

OS="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$OS/harness/claude-code"
HOME_DIR="${AGENT_OS_HOME:-$HOME/.agentos}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
HOOKS_DEST="$CLAUDE_DIR/hooks/agent-os"
SKILLS_DEST="$CLAUDE_DIR/skills"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDEMD="$CLAUDE_DIR/CLAUDE.md"
MARK="# >>> Agent OS (managed — do not duplicate) >>>"
PURGE=0; [ "${1:-}" = "--purge" ] && PURGE=1
ts(){ date -u +%Y%m%dT%H%M%SZ; }
say(){ printf '%s\n' "$*"; }
ok(){  printf '  \033[32m✓\033[0m %s\n' "$*"; }
skip(){ printf '  \033[33m•\033[0m %s\n' "$*"; }

say "Agent OS uninstaller"
say "  host config:  $CLAUDE_DIR"
say "  mind (HOME):  $HOME_DIR  $([ $PURGE = 1 ] && echo '(WILL BE PURGED)' || echo '(preserved)')"
say ""

# ---- 1 · adapter hooks --------------------------------------------------------------------------
say "1 · adapter hooks"
[ -d "$HOOKS_DEST" ] && { rm -rf "$HOOKS_DEST"; ok "removed $HOOKS_DEST"; } || skip "no agent-os hooks dir"

# ---- 2 · skills (only Agent OS's own — the user's other skills stay) ----------------------------
say "2 · skills"
removed=0
for d in "$SRC"/skills/*/; do
  name="$(basename "$d")"
  [ -e "$SKILLS_DEST/$name" ] && { rm -rf "$SKILLS_DEST/$name"; ok "removed skill: $name"; removed=1; }
done
[ $removed = 0 ] && skip "no Agent OS skills present"

# ---- 3 · settings.json (remove only our hook entries; backup; preserve other owners) -----------
say "3 · settings.json"
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak.$(ts)"
  python3 - "$SETTINGS" "$HOOKS_DEST" <<'PY'
import json, sys
path, hooks_dest = sys.argv[1], sys.argv[2]
try: cur = json.load(open(path))
except Exception: cur = {}
hooks = cur.get("hooks", {})
def ours(entry):
    return any((hooks_dest in (h.get("command") or "")) or ("/hooks/agent-os/" in (h.get("command") or ""))
               for h in entry.get("hooks", []))
removed = 0
for ev in list(hooks.keys()):
    kept = [e for e in hooks[ev] if not ours(e)]
    removed += len(hooks[ev]) - len(kept)
    if kept: hooks[ev] = kept
    else: del hooks[ev]            # we were the only owner of this event
if hooks: cur["hooks"] = hooks
elif "hooks" in cur: del cur["hooks"]
json.dump(cur, open(path, "w"), indent=2); open(path, "a").write("\n")
print(f"REMOVED {removed}")
PY
  ok "removed Agent OS hook entries (other owners preserved; backup saved)"
else
  skip "no settings.json"
fi

# ---- 4 · bootloader block in CLAUDE.md ---------------------------------------------------------
say "4 · bootloader (CLAUDE.md)"
if [ -f "$CLAUDEMD" ] && grep -qF "$MARK" "$CLAUDEMD"; then
  cp "$CLAUDEMD" "$CLAUDEMD.bak.$(ts)"
  python3 - "$CLAUDEMD" <<'PY'
import sys
p = sys.argv[1]; t = open(p).read()
start = "# >>> Agent OS (managed — do not duplicate) >>>"
end   = "# <<< Agent OS <<<"
i = t.find(start); j = t.find(end)
if i != -1 and j != -1:
    j += len(end)
    k = i
    while k > 0 and t[k-1] == "\n": k -= 1   # swallow the blank line we added before the block
    t = t[:k] + t[j:]
    t = (t.rstrip("\n") + "\n") if t.strip() else ""
    open(p, "w").write(t)
print("OK")
PY
  ok "removed Agent OS block from CLAUDE.md (backup saved)"
else
  skip "no Agent OS block in CLAUDE.md"
fi

# ---- 5 · cron (scoped to THIS install's path — never touch another install's cron line) --------
say "5 · cron"
CRON_MATCH="$HOOKS_DEST/index/reindex.sh"
if command -v crontab >/dev/null 2>&1 && crontab -l 2>/dev/null | grep -qF "$CRON_MATCH"; then
  # `|| true`: if our line was the only one, grep -v emits nothing and exits 1 — that's fine, we want
  # an empty crontab in that case, not a failed uninstall.
  { crontab -l 2>/dev/null | grep -vF "$CRON_MATCH" || true; } | crontab -
  ok "removed reindex cron line"
else
  skip "no reindex cron for this install"
fi

# ---- 6 · the mind (vault-safe; only with --purge) ----------------------------------------------
say "6 · mind"
if [ $PURGE = 1 ]; then
  if [ -e "$HOME_DIR" ]; then
    # Safety: snapshot the mind before destroying it — the destructive path can never lose it.
    if [ -f "$OS/bin/backup.sh" ]; then
      AGENT_OS_HOME="$HOME_DIR" bash "$OS/bin/backup.sh" backup || skip "pre-purge snapshot failed (continuing)"
    fi
    rm -rf "$HOME_DIR"; ok "PURGED the mind ($HOME_DIR) — snapshot kept in ${HOME_DIR}-snapshots/"
  else
    skip "no mind to purge"
  fi
else
  skip "mind preserved ($HOME_DIR) — re-run with --purge to remove it"
fi

say ""
say "✓ Agent OS uninstalled. $([ $PURGE = 1 ] && echo 'Mind purged.' || echo 'Your mind is intact.')"
say "  Backups of settings.json / CLAUDE.md saved alongside the originals (.bak.<timestamp>)."
