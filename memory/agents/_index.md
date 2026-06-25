# agents — Private Agent Memory

Each agent's own space. An agent reads the shared pool (self/projects/knowledge/decisions/sessions) and writes its private memory here. Copy `_template/` per agent (each worker as the team grows) as a real need appears.

This is also where a **grown** agent's **definition** lives — its `AGENT.md` (the RISEN spec) sits beside its memory, so the whole agent is one portable folder in the mind, outside the harness. (Shipped agents — the orchestrator and watcher — define their `AGENT.md` in the repo's `agents/`, since they're versioned with the seed; only their *memory* lives here. The dividing line is shipped-vs-grown = seed-vs-instance.)

Notes here are **`memory_type: semantic`** (the primary axis; the agent profile is durable identity);
`type: self` is the topic label. `scratch/` is ephemeral and not indexed.

Layout:
- `AGENT.md` — for a **grown** worker, its RISEN definition (written by `create-agent` / the Watcher's `add-agent`)
- `profile.md` — how the agent works, learned preferences, operating notes
- `skills/` — self-written / learned skills (markdown)
- `scratch/` — ephemeral working notes

## Recall scope (verified)

Per-agent memory has **three privacy tiers** — how each surfaces in recall (verified end-to-end):

| Tier | Always-load orient | grep fallback | semantic index |
|---|---|---|---|
| `scratch/` | excluded | excluded | **never indexed** — truly private |
| `profile.md` + `skills/` | excluded | excluded | **indexed** — discoverable on-demand |
| shared pool (self/projects/…) | injected | searched | indexed |

So an agent's `scratch/` is genuinely private (never recalled by anyone), while its `profile`/`skills`
are kept out of the cheap always-on surface but are **discoverable cross-agent** via on-demand semantic
recall (by design — so the system can surface "this agent already knows how to do X"). Nothing
per-agent ever leaks into the always-load shared injection.

<!-- mem-links:start (auto-maintained — edit above this line) -->
## Map
_(empty — notes will appear here as they're written)_
<!-- mem-links:end -->
