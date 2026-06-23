---
memory_type: procedural
kind: principle
title: Standards — the seed file
date: 2026-06-11T19:04:48Z
tags: [standards, seed]
status: active
materializable: false
---

# Standards — the seed

The day-one home for **principles**: plain-English rules for how PJ builds. The lowest rung of the
fidelity ladder, highest flexibility. A principle that earns detail graduates to a `patterns/` note;
one that earns code graduates to a `modules/` package — **with continuity** (this prose becomes the
module's README).

> **Ships near-empty on purpose.** Real standards are *mined from work*, never authored in the
> abstract. Add a principle here only when you hit the moment — *"I'll want this again."* No real
> standards exist yet; the examples below are illustrative and commented out.

## Principles

<!--
Example shape (uncomment and replace with a real, earned principle):

### Package manager
We default to bun.

### Data grids
All data tables use TanStack Table, wrapped with sorting, pagination, column-resize, and a standard
empty state. → when this earns code, graduate to modules/data-table/.
-->

### Package manager
Default to **bun**. It's PJ's day-to-day choice — use it for installs, scripts, and runtime unless a
project says otherwise. Not dogmatic: pnpm, npm, and yarn are all fine when a repo, a teammate, or a
constraint calls for them. Bun is the default, not a mandate — match the project you're in.
