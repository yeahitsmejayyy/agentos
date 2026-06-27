#!/bin/bash
# Agent OS — materialize a .proc module/scaffold's CODE into a project. The producing-half counterpart to
# recall: recall injects a standard as *guidance*; materialize installs the actual *artifact* — a module's
# `src/` + its bundled `tests/` (the oracle), or a scaffold's starting point. Recall-only entries
# (principle / pattern) have no code to install. Never overwrites existing files.
#
# Usage:  bash materialize.sh <name> <target-dir>
#   <name>        a module or scaffold under $AGENT_OS_PROC (modules/<name> or scaffolds/<name>)
#   <target-dir>  where to install (created if missing); existing files are skipped, never clobbered
set -uo pipefail
PROC="${AGENT_OS_PROC:-${AGENT_OS_HOME:-$HOME/.agentos}/.proc}"
NAME="${1:-}"; TARGET="${2:-}"
say(){ printf '%s\n' "$*"; }
die(){ printf '✗ %s\n' "$*" >&2; exit 1; }
[ -n "$NAME" ] && [ -n "$TARGET" ] || die "usage: materialize.sh <name> <target-dir>"

# locate the artifact — modules first, then scaffolds
SRCDIR=""; KIND=""
for k in modules scaffolds; do
  if [ -d "$PROC/$k/$NAME" ]; then SRCDIR="$PROC/$k/$NAME"; KIND="$k"; break; fi
done
[ -n "$SRCDIR" ] || die "not found in .proc: '$NAME' (looked in modules/ and scaffolds/)"

# must be flagged materializable — the doc carries the frontmatter (README.md, or the one .md for scaffolds)
DOC="$SRCDIR/README.md"; [ -f "$DOC" ] || DOC="$(ls "$SRCDIR"/*.md 2>/dev/null | head -1)"
[ -n "$DOC" ] && grep -qiE "^materializable:[[:space:]]*true" "$DOC" \
  || die "'$NAME' is not materializable (recall-only). Set 'materializable: true' to install its code."

mkdir -p "$TARGET"
installed=0; skipped=0
put(){ # put <abs-src-file>
  local f="$1" rel dest
  rel="${f#$SRCDIR/}"; dest="$TARGET/$rel"
  if [ -e "$dest" ]; then say "  • skip (exists): $rel"; skipped=$((skipped+1)); return; fi
  mkdir -p "$(dirname "$dest")"; cp "$f" "$dest"; say "  + $rel"; installed=$((installed+1))
}

if [ "$KIND" = "modules" ]; then
  for sub in src tests; do
    [ -d "$SRCDIR/$sub" ] || continue
    while IFS= read -r f; do put "$f"; done < <(find "$SRCDIR/$sub" -type f 2>/dev/null)
  done
else  # scaffold: the whole starting point, minus the .md doc(s)
  while IFS= read -r f; do
    case "$f" in *.md) continue;; esac
    put "$f"
  done < <(find "$SRCDIR" -type f 2>/dev/null)
fi

say ""
skipnote=""; if [ "$skipped" -gt 0 ]; then skipnote=", $skipped skipped (already present)"; fi
say "✓ materialized $KIND/$NAME → $TARGET ($installed file(s)$skipnote)"
if [ "$installed" -eq 0 ] && [ "$skipped" -eq 0 ]; then
  say "  (nothing to install — this artifact has no code yet)"
fi
exit 0
