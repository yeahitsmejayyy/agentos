---
name: promote-standard
description: Promote a proven component (and its tests) from real work into the .proc standards library as a reusable module — the gated producing-half mirror of memory consolidation. Use when you say "I'll reach for this again" about something just built. Proposes the promotion; you approve. Never auto-nominates.
allowed-tools: Read Write Bash Grep
---

# promote-standard

The deliberate **promote gesture** that fills the standards library (`$AGENT_OS_PROC`, default `~/.proc`)
— the producing-half mirror of `consolidate-memory`. A standard is *mined from work you actually did and
liked*, never authored in the abstract. The gate question is simply: **"Will I reach for this again?"**

> Invoked manually (by you, or proposed by `consolidate-memory` when it spots a procedural item).
> **Auto-nomination is deferred (Part B)** — start with the explicit gesture, learn what recurs later.

## Climb the fidelity ladder
Promote to the rung the standard has actually earned — don't over-reach:
- **principle** → append a plain rule to `.proc/standards.md`. (recall only)
- **pattern** → a `.proc/patterns/<name>.md` note (convention + maybe a snippet). (recall only)
- **module** → a `.proc/modules/<name>/` package: real code **with its own tests**. (materializable)
- **scaffold** → a `.proc/scaffolds/<name>.md` describing a whole starting point. (materializable)

Most promotions worth this skill are **modules** — code + oracle. The steps below cover that case;
for a principle/pattern, just write the note with correct frontmatter and skip the `src/`+`tests/` copy.

## Steps (module promotion)
1. **Identify the source.** Find the component in the project being promoted, **and its tests** — a module
   that ships without its tests is not promoted (the tests are the bundled oracle).
2. **Pick the name** (`<name>`, kebab-case) and confirm `.proc/modules/<name>/` doesn't already exist
   (if it does, propose an update, not a clobber).
3. **Build the module dir** under `$AGENT_OS_PROC/modules/<name>/`:
   - `src/` — the component's code.
   - `tests/` — its tests (**required** — this is the oracle; never omit it).
   - `README.md` — the standard itself, with frontmatter:
     ```yaml
     memory_type: procedural
     kind: module
     title: <name>
     date: <run: date -u +%Y-%m-%dT%H:%M:%SZ>
     tags: [...]
     status: active
     materializable: true
     ```
     If a `patterns/` note already described this, carry its prose into the README (graduation with
     continuity — nothing thrown away).
4. **Update `.proc/modules/_index.md`** (or run `reindex.sh`, which maintains the `[[links]]` block).
5. **Propose, don't auto-commit.** Present the planned module dir + frontmatter to you and **wait for
   approval** before writing — same propose-not-overwrite discipline as `consolidate-memory`.

## Guardrails (CONSTITUTION)
- **Gated** — proposed, never automatic. You curate what graduates.
- **Tests are non-negotiable** for a module — the oracle is the point.
- **Never clobber** an existing standard; propose an update and flag the diff.
- **Materialization installer is Part B** — this skill *creates the standard*; installing it into a
  project comes later. Set `materializable: true` so it's ready when the installer exists.
