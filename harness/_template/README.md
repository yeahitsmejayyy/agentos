# Harness Adapter — Template

Checklist for wiring Agent OS to any new harness. Every harness has *some* event-hook surface, so a new adapter only needs to satisfy these roles:

- [ ] **Capture floor** — on session end (and before context compaction), write a raw session note to the vault's `sessions/`. Deterministic; must not depend on model judgment.
- [ ] **Rich summary** — a skill/command the model runs to write the structured session note.
- [ ] **Orientation recall** — on session start, inject `home.md` + `self/` into context.
- [ ] **Per-prompt recall** — before each turn, inject relevant memory (grep MVP, or a memory provider).
- [ ] **Consolidation** — a periodic sweep that distills sessions → durable buckets and proposes promotions (propose-you-approve).
- [ ] **Skill path** — point the harness at the canonical `/skills` (sync/symlink).
- [ ] **Vault path** — point the harness at the memory vault (`AGENT_OS_MEM`).

Reference adapters: `../claude-code/` (built), Hermes (see repo `.r/memory-hooks-and-triggers.md`).
