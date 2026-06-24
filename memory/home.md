# .mem — Home

Index / Map of Content for your memory vault. Orientation for humans **and** agents: what lives where.

Memory is organized along **two axes**. The **primary key is cognitive type** (`memory_type`) — the
*kind* of memory a note is. **Topic** (the old six buckets) is a **secondary view** layered on top —
folders for human navigation and a tag for filtering, *not* the organizing principle. A note's
**store** (where it lives) carries its privacy and lifecycle. Type first, topic second, store as address.

## Axis 1 — `memory_type` (the primary key; required on every note)
The cognitive nature of the note — the *noun*. A note has exactly one.

- **`working`** — the live context window. **Never stored**; the harness supplies it. Listed for completeness.
- **`episodic`** — time-bound experience: sessions, observations, raw captures. Lives in `.mem`.
- **`semantic`** — durable facts & identity: decisions, knowledge, the user model, agent profiles. Lives in `.mem`.
- **`procedural`** — how-to / craft: principles, patterns, modules, scaffolds. Lives in **`.proc`**.

> The three *stored* types are `episodic`, `semantic`, `procedural`. `.mem` holds the first two; `.proc` holds the third.

## Axis 2 — store (the address — privacy + lifecycle)
Derived from **which store the file lives in**, not a frontmatter field.

- **`.mem`** (this vault) — private, accrues over time. Holds `episodic` + `semantic`. Recall-only.
- **`.proc`** — publishable / open-source. Holds `procedural`. Can be recalled *or* materialized (install the module).
- **agent defs** (`agents/`) — versioned identities, not notes.
- **CONSTITUTION** (`shared/`) — versioned law, not a note.

## Topic — a secondary view (the six buckets)
The buckets survive as **navigation folders + topic tags**, layered on top of `memory_type` — not the primary key.
`memory_type` is genuinely orthogonal to topic (the subject "auth" can be a *semantic* note, a *procedural* note,
or an *episodic* one — topic can't predict type). Inside `.mem` the field is only *weakly* orthogonal to folder
(`sessions/` already implies episodic, the rest imply semantic); we carry it anyway so one uniform field serves
recall across **both** stores.

- **self/** — the user model: who you are, standards, preferences. [shared] · semantic
- **projects/** — one self-contained directory per project. [shared] · semantic
- **knowledge/** — external durable facts, cross-project & reusable. [shared] · semantic
- **decisions/** — your decisions & learnings, cross-project & reusable. [shared] · semantic
- **sessions/** — raw working log, time-ordered. The on-ramp; distilled upward over time. [shared] · episodic
- **agents/** — each agent's private memory (profile / skills / scratch). [own] · semantic

## Conventions
- **Atomic notes** — one idea per file.
- **Frontmatter on every note** — `memory_type` (primary axis: `episodic | semantic`), then
  `type, date, tags, agent, project, status`. `type` is **retained as the topic/bucket label** (now
  secondary) so existing notes and Obsidian queries keep working. `date` is a full ISO 8601 **UTC**
  timestamp (`2026-06-08T04:22:33Z`, from `date -u +%Y-%m-%dT%H:%M:%SZ`) — an auditable, sortable trail.
- **Single-home by scope** — project-scoped notes stay in the project; reusable lessons are promoted to `knowledge` / `decisions` (moved + linked, never copied).
- **Shared vs private** — self/projects/knowledge/decisions/sessions are the shared pool all agents read; `agents/<agent>/` is each agent's own space.

Design spec: agents repo `.r/memory/memory-vault-structure.md`. Two-axis migration: `.loops/agent-os/o_migration-plan_06112026.md`.

<!-- mem-links:start (auto-maintained — edit above this line) -->
## Buckets
- [[self/_index|self]]
- [[projects/_index|projects]]
- [[knowledge/_index|knowledge]]
- [[decisions/_index|decisions]]
- [[sessions/_index|sessions]]
- [[agents/_index|agents]]
<!-- mem-links:end -->
