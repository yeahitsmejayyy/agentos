# .proc — Home

Index / Map of Content for your **standards library** — the *producing half* of the Agent OS.
Sibling to `.mem`: where `.mem` answers **"what do I know?"** (recall), `.proc` answers
**"how do I build?"** (recall **or** materialize). Same Markdown-and-frontmatter shape, same local
index engine — a separate, **publishable / open-sourceable** store.

> **`memory_type: procedural`.** Every note here is procedural memory — craft, not facts. That's the
> axis that has no home in `.mem`; this store is its home. See `../memory/home.md` for the two-axis model.

## The fidelity ladder — prose → working software
A standard lives on a spectrum. The further down, the less the agent has to interpret — and
interpretation is where slop comes from. A standard **graduates** up the ladder *with continuity*:
the prose note becomes the module's README. Nothing is thrown away.

| `kind` | What it is | Materializable? |
|---|---|---|
| `principle` | a plain-English rule (*"TanStack Table for all data grids"*) | no — recall only |
| `pattern` | a convention with detail, maybe a snippet | no — recall only |
| `module` | real, finished code **with its own tests** | **yes** — install the code |
| `scaffold` | a whole starting point (e.g. the Skelly templates) | **yes** — install the project |

## Two access modes
- **Recall** — inject the standard as guidance (read the convention). Same as `.mem`.
- **Materialize** — install the actual artifact into a project. **`.mem` never does this.** Flagged by
  `materializable: true` on modules/scaffolds. *The materialization installer is deferred (Part B); the
  flag is described and set now.*

## A module ships its own oracle
When a component graduates to a `module`, **its tests come with it** (`modules/<name>/tests/`). So a
module is the standard **and** its verifier in one package: the code defines what "good" is, the tests
prove a given attempt meets it. That bundled oracle is what closes the producing loop and kills slop.

## Start empty, grow by promotion
You can't author good standards in the abstract — they're **mined from real work**. This store ships
**near-empty** (`standards.md` seed + templates). Entries arrive through a **gated promote gesture**
("Will I reach for this again?"), the producing-half mirror of memory consolidation. Proposed, never
automatic. The `promote-standard` skill (Phase 4) performs it; auto-nomination is deferred (Part B).

## `.proc` note frontmatter
```yaml
memory_type: procedural
kind: principle | pattern | module | scaffold   # the fidelity ladder
title: ...
date: 2026-06-11T19:04:48Z                       # ISO 8601 UTC
tags: [...]
status: active | archived
materializable: false                            # true for modules/scaffolds (installable code)
```

## Layout
- **`standards.md`** — the seed file: principles, day one (near-empty).
- **`patterns/`** — conventions that outgrew one line. `_index.md` + `_template/pattern.md`.
- **`modules/`** — promoted code + its tests. `_index.md` + `_template/` (README + `src/` + `tests/`).
- **`scaffolds/`** — full starting points. `_index.md` + `_template/scaffold.md`.

Design spec: agents repo `.r/explainers/standards-library-explainer.md` (written as `.lib`; renamed
`.proc` here to match the cognitive-type ontology). Two-axis migration: `.loops/agent-os/o_migration-plan_06112026.md`.

<!-- mem-links:start (auto-maintained — edit above this line) -->
## Map
- [[patterns/_index|patterns]]
- [[modules/_index|modules]]
- [[scaffolds/_index|scaffolds]]
<!-- mem-links:end -->
