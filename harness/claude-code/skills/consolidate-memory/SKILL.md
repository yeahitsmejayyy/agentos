---
name: consolidate-memory
description: Distill recent raw session notes into durable memory and propose promotions. Use end-of-day or on request to keep the vault high-signal. Proposes changes for approval; never overwrites silently.
allowed-tools: Read Write Bash Grep
---

# consolidate-memory

The periodic consolidation sweep over the memory vault (`$AGENT_OS_MEM`, default `~/.mem`).

## Steps
1. Read recent notes in `sessions/` (these are `memory_type: episodic`).
2. Identify durable items and route them by **cognitive type** (the primary axis):
   - **`semantic` → `.mem`** (durable facts & identity). Set `memory_type: semantic`, then file by topic:
     - decisions / lessons → `decisions/`
     - reusable facts / findings → `knowledge/`
     - project updates → `projects/<project>/`
     - preference / working-style updates → `self/`
   - **`procedural` → `.proc`** (how-to / craft — "this is how I build X"). Do **not** write it into `.mem`;
     instead **propose a `.proc` promotion** and hand off to the `promote-standard` skill (it extracts the
     component + its tests, sets `kind` + `materializable`, updates the `_index`). PJ approves.
3. Dedupe, merge near-duplicates, mark stale notes `status: archived` (never delete).
4. **Flag conflicts** — if new info contradicts an existing note, surface it; never silently overwrite.
5. **Propose** a batch of durable writes (`.mem`) + procedural promotions (`.proc`) + project→global
   promotions (moved + linked, single-home-by-scope). **Wait for PJ's approval** before committing —
   nothing is auto-written.

Everything maps to the CONSTITUTION: truth-seeking, honesty, least-privilege, guard-the-irreversible.
