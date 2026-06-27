#!/bin/bash
# Agent OS — mind backup & restore. The mind (~/.agentos) is the precious, accrued part of an instance;
# snapshots live OUTSIDE it (~/.agentos-snapshots/) so they survive a reset or `uninstall --purge`.
# MVP: timestamped tarballs, minus the rebuildable index. (git-backed versioning + offsite push is a v2.)
#
# Usage:  backup.sh backup             create a snapshot
#         backup.sh restore [name]     restore the latest snapshot (or a named one); confirms on overwrite
#         backup.sh list               list snapshots, newest first
# Env:    AGENT_OS_HOME (mind), AGENT_OS_SNAPSHOTS (snapshot dir), AGENT_OS_SNAPSHOT_KEEP (default 10),
#         AGENT_OS_YES=1 (skip the overwrite confirmation, for scripting/CI)
set -uo pipefail
HOME_DIR="${AGENT_OS_HOME:-$HOME/.agentos}"
SNAP_DIR="${AGENT_OS_SNAPSHOTS:-${HOME_DIR}-snapshots}"   # sibling of the mind → survives --purge
KEEP="${AGENT_OS_SNAPSHOT_KEEP:-10}"
say(){ printf '%s\n' "$*"; }
die(){ printf '✗ %s\n' "$*" >&2; exit 1; }

do_backup(){
  [ -d "$HOME_DIR" ] || die "no mind to back up at $HOME_DIR"
  mkdir -p "$SNAP_DIR"
  local stamp out
  stamp="$(date -u +%Y-%m-%dT%H-%M-%SZ)"     # colons are unsafe in filenames
  out="$SNAP_DIR/mind-$stamp.tar.gz"
  # archive the mind's contents, excluding the rebuildable index (works on BSD + GNU tar)
  tar -czf "$out" -C "$HOME_DIR" --exclude='*/.index' --exclude='*/.index/*' . \
    || die "tar failed"
  say "✓ snapshot → $out ($(du -h "$out" 2>/dev/null | cut -f1 | tr -d ' '))"
  # prune to the last $KEEP
  local n; n=$(ls -1t "$SNAP_DIR"/mind-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')
  if [ "${n:-0}" -gt "$KEEP" ]; then
    ls -1t "$SNAP_DIR"/mind-*.tar.gz | tail -n +$((KEEP+1)) | while read -r old; do
      rm -f "$old"; say "  • pruned: $(basename "$old")"
    done
  fi
}

do_list(){
  if ls "$SNAP_DIR"/mind-*.tar.gz >/dev/null 2>&1; then
    ls -1t "$SNAP_DIR"/mind-*.tar.gz | sed 's#.*/##'
  else
    say "(no snapshots in $SNAP_DIR)"
  fi
}

do_restore(){
  local snap="${1:-}"
  if [ -z "$snap" ]; then
    snap="$(ls -1t "$SNAP_DIR"/mind-*.tar.gz 2>/dev/null | head -1 || true)"
  elif [ ! -f "$snap" ]; then
    snap="$SNAP_DIR/$snap"     # accept a bare filename
  fi
  [ -n "$snap" ] && [ -f "$snap" ] || die "no snapshot to restore (looked in $SNAP_DIR)"
  if [ -e "$HOME_DIR" ] && [ -z "${AGENT_OS_YES:-}" ]; then
    printf "  Restore %s OVER %s? [y/N] " "$(basename "$snap")" "$HOME_DIR"
    read -r ans; case "$ans" in y|Y|yes) ;; *) die "aborted" ;; esac
  fi
  mkdir -p "$HOME_DIR"
  tar -xzf "$snap" -C "$HOME_DIR" || die "restore failed"
  say "✓ restored $(basename "$snap") → $HOME_DIR"
  say "  (run \`agentos reindex\` to rebuild the search index)"
}

cmd="${1:-}"; [ "$#" -gt 0 ] && shift
case "$cmd" in
  backup)  do_backup ;;
  restore) do_restore "${1:-}" ;;
  list)    do_list ;;
  *) echo "usage: backup.sh {backup | restore [name] | list}" >&2; exit 1 ;;
esac
