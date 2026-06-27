---
memory_type: procedural
kind: module
title: <module name>
date:
tags: []
status: active
materializable: true
---

# <module name>

The standard, as code. This README is often the prose note this module **graduated from** — kept
with continuity. Materializing this module installs `src/` (and wires its deps) into a project.

## What it is
<!-- One paragraph: what this module provides and the slop it prevents. -->

## Layout
- `src/` — the code (the standard itself).
- `tests/` — **the bundled oracle.** A module isn't proven without it; conforming means building on
  the thing that already passes.

## Materialize
Run the `materialize` skill (engine: `materialize.sh <name> <target-dir>`): it copies this module's
`src/` + `tests/` into the target project, skipping anything already there. The bundled tests come with
it — run them to confirm the install conforms.

## Tests / oracle
<!-- What the tests assert — the definition of "good" this module guarantees. -->
