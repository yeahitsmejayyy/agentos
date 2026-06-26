---
memory_type: semantic
type: self
title: watcher — profile
date:
tags: [agent, watcher]
agent: watcher
status: active
---

# watcher — profile

The Watcher's private memory home (per the `.mem/agents/<agent>/` convention). The Watcher observes the
system on a slow cadence and writes **gated proposals** here for the user to decide — it never mutates
the OS itself. See `agents/watcher/AGENT.md` (identity) and `agents/watcher/LOOP.md` (how the loop runs).

## Layout
- `inbox/` — pending proposals (full fidelity). Surfaced as a count at SessionStart; reviewed via `/watch-review`.
- `decided/` — the decision archive (approved / modified / rejected, each with a reason) — the taste signal.

Learned taste (what the user tends to approve vs reject, per kind) accrues here over time and tunes the bar.
