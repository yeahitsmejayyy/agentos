# Mind backup & restore — snapshots live outside the mind, round-trip the content, exclude the index, prune.
B="$SEED_ROOT/bin/backup.sh"
T="$(newtmp)"; MIND="$T/.agentos"; SNAP="$MIND-snapshots"
mkdir -p "$MIND/.mem/self" "$MIND/.mem/.index" "$MIND/.proc"
printf 'Cli-bot\n'  > "$MIND/.mem/self/IDENTITY.md"
printf 'rebuild\n'  > "$MIND/.mem/.index/index.db"

# backup → a snapshot lands in the SIBLING dir (outside the mind, so it survives --purge)
AGENT_OS_HOME="$MIND" bash "$B" backup >/dev/null 2>&1
if ls "$SNAP"/mind-*.tar.gz >/dev/null 2>&1; then ok "backup: snapshot lands outside the mind"; else no "backup: snapshot lands outside the mind"; fi

# the rebuildable index is excluded from the tarball
snap="$(ls -1 "$SNAP"/mind-*.tar.gz 2>/dev/null | head -1)"
absent "backup: excludes the rebuildable index" "$(tar -tzf "$snap" 2>/dev/null)" ".index"

# restore into a FRESH mind round-trips the content, not the index
FRESH="$T/restored"
AGENT_OS_HOME="$FRESH" AGENT_OS_SNAPSHOTS="$SNAP" bash "$B" restore >/dev/null 2>&1
contains "restore: round-trips the identity"      "$(cat "$FRESH/.mem/self/IDENTITY.md" 2>/dev/null)" "Cli-bot"
check    "restore: leaves the index out (rebuilt)" test ! -e "$FRESH/.mem/.index"

# prune to KEEP: pre-seed 3 old snapshots, back up once more with KEEP=2 → exactly 2 remain
P="$T/p"; PS="$P-snapshots"; mkdir -p "$P/.mem/self" "$PS"; printf x > "$P/.mem/self/IDENTITY.md"
for ts in 2020-01-01T00-00-01Z 2020-01-01T00-00-02Z 2020-01-01T00-00-03Z; do : > "$PS/mind-$ts.tar.gz"; done
AGENT_OS_HOME="$P" AGENT_OS_SNAPSHOT_KEEP=2 bash "$B" backup >/dev/null 2>&1
eq "backup: prunes to KEEP (=2)" "2" "$(ls -1 "$PS"/mind-*.tar.gz 2>/dev/null | wc -l | tr -d ' ')"

rm -rf "$T"
