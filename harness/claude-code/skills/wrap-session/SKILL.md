---
name: wrap-session
description: Write a structured session summary to the memory vault when finishing a work session. Captures what happened, decisions, artifacts, and next steps. Use at the end of a session for a high-quality record (the SessionEnd hook is only a raw backstop).
allowed-tools: Read Write Bash
---

# wrap-session

You are closing out a work session and recording it to the memory vault (`$AGENT_OS_MEM`, default `~/.mem`).

## Steps
1. Write a new note to `<vault>/sessions/<YYYY-MM-DD>_<short-title>.md` using the format in `sessions/_session-template.md`.
2. Fill the four sections honestly and concisely:
   - **What happened** — what was worked on / accomplished
   - **Decisions made** — flag anything reusable as a candidate for promotion to `decisions/`
   - **Artifacts produced** — links + which project
   - **Open threads / next steps** — continuity for next time
3. Set frontmatter: `memory_type: episodic` (the primary axis — a session is time-bound experience), then `type: session`, `date`, `tags`, `agent`, `project`, `status`. The `date` is a full ISO 8601 **UTC** timestamp — get it with `date -u +%Y-%m-%dT%H:%M:%SZ` (run it; don't guess the time).
4. Do **not** write durable notes to `self/knowledge/decisions/projects` here — that's the consolidate-memory step (propose, you approve).
