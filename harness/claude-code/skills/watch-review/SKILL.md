---
name: watch-review
description: Review the Watcher's pending proposals through the four-door gate — approve, modify, reject, or snooze. Approve runs the matching gesture in-loop (promote-standard / scaffold a new agent or skill) against a real working tree; nothing mutates without your explicit yes. Captures every decision as the Watcher's taste signal.
allowed-tools: Read Write Bash
---

# watch-review

You are walking the user through the Watcher's **inbox** — the gate where a proposal becomes a change, or
doesn't. The Watcher proposed; **the user decides.** Nothing mutates the OS without an explicit yes,
in-loop (the **Uatu line** — the Watcher may intervene only by asking).

## Resolve + list
- Vault: `MEM="${AGENT_OS_MEM:-${AGENT_OS_HOME:-$HOME/.agentos}/.mem}"`; inbox `$MEM/agents/watcher/inbox/`.
- List proposals with `status: pending` or `snoozed`. If none, say so and stop.

## For each proposal: present, then offer the four doors
Show the **pattern, evidence, the §4 boundary test, and the diff preview** — let the user decide fast and
well. Then take exactly one door:

- **Approve** → run the matching gesture **in-loop, against the real tree** (confirm the write first):
  - `promote-standard` → hand off to the `promote-standard` skill (writes the `.proc` module + its tests).
  - `add-agent` → scaffold `agents/<name>/AGENT.md` from `agents/_template/`, filled per the proposal (RISEN).
  - `add-skill` → scaffold `skills/<name>/SKILL.md` from the proposal.
  - `realign` → surface the drift and agree the correction with the user (no artifact — the change is the
    decision/attention itself).
  - `propose-self-update` → append/refine the learned fact in `self/about-me` (the user model). Confirm the
    wording with the user; keep the profile high-signal (curate, don't dump). This is the gesture that
    *grows the mind* — it's what lets genesis stay light.
  Set the proposal `status: approved`.
- **Modify** → adjust the proposal with the user, then approve the adjusted version. Record **what changed**
  (the highest-value taste signal). `status: modified`.
- **Reject** → record a **reason** (a reasonless no teaches nothing). `status: rejected`.
- **Snooze** → leave it; it re-surfaces on a later pass. `status: snoozed`.

## Capture the decision (the upstream taste loop)
Move each decided proposal from `inbox/` to `$MEM/agents/watcher/decided/` (keep rejected ones — the reason
is the signal). Append a one-line taste note: *kind + decision + reason*. If a decision taught a durable,
reusable lesson, propose promoting it to the shared `decisions/` bucket.

## Hard rules (CONSTITUTION)
- **Nothing mutates without the user's explicit yes** — in-loop, previewable, reversible (guard-the-irreversible).
- **Never auto-approve.** Even a high-confidence proposal waits for the door.
- **Reasoned rejections only** — the reason is half the loop.
- **Approve reuses the existing gesture** — hand off to `promote-standard`; scaffold agents/skills from their
  `_template`. Don't reinvent what already exists.
