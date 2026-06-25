---
name: create-agent
description: Deliberately add a worker to your team — the human-run twin of the Watcher's add-agent proposal. Use when you already know a role you want ("set up a Researcher", "I want an agent that drafts release notes"). Walks the RISEN frame, scaffolds agents/<name>/AGENT.md from the template, and wires it under the orchestrator + CONSTITUTION. Same destination as add-agent; you're just the trigger instead of the Watcher.
allowed-tools: Read Write Bash
---

# create-agent

You are helping the user **deliberately add a worker to their team** — the explicit, power-user path. This
is the **deliberate twin of the Watcher's `add-agent`**: the Watcher *proposes* a worker when it notices a
recurring need; here the **user already knows** who they want and asks directly. Both doors lead to the same
room — one RISEN `AGENT.md`, scaffolded from the same `_template`, answering to the same CONSTITUTION. The
only difference is the trigger.

> **The invariant — never cross it.** The user always talks to **one orchestrator**, which **delegates** to
> single-purpose workers. You are adding a *worker beneath the orchestrator*, never a second orchestrator.
> And the seed ships an **empty roster on purpose**: this skill lets the user *author* their team — it never
> *ships* one. "Trivial to create" is not "shipped by default"; that line is the whole point.

## When to use
- The user says "set up a Researcher / Analyst / Builder", "I want an agent that …", "add a worker for …".
- Onboarding a power-user who arrives already knowing their team (the post-genesis "set them up now" path).
- **Not** for the Watcher's proposals — those flow through `watch-review` (the `add-agent` door).

## Where it lands — the MIND, by absolute path (never the cwd)
A **grown** agent lives in the **mind**, not the shipped repo. Its whole self — definition *and* memory —
goes in **`$AGENT_OS_MEM/agents/<name>/`** (`AGENT_OS_MEM` defaults to `${AGENT_OS_HOME:-~/.agentos}/.mem`).
Resolve that from the environment and write there **absolutely** — *never* an `agents/…` path relative to
the current directory. (Skipping this is the exact bug that scaffolds a worker into whatever repo you
happen to be standing in.) The shipped agents (orchestrator, watcher) define in the repo; everything you
*grow* defines here, portable with the mind. Confirm `$AGENT_OS_MEM/agents/_template/` exists first.

## Steps
1. **Name + role, lightly.** One worker, single-purpose. Get a name (kebab-case → the dir) and a one-line
   role. If they give only a name ("Researcher"), *draft* the RISEN from it and let them correct — don't
   interrogate. Keep it light, the way genesis is light.
2. **Fill the RISEN frame** from `agents/_template/AGENT.md`: **Role** (specific enough to rule out generic
   output), **Instructions** (the deliverable + the standard it's held to), **Steps** (the repeatable
   process), **End Goal** (why the work matters), **Narrowing** (tone / format / scope / never). Propose a
   complete draft; refine with the user rather than asking five questions.
3. **Single-purpose check.** If the role carries two jobs, split it — propose two agents or narrow to one.
   (A worker growing a second job is the signal to split — the orchestrator's own rule, applied at birth.)
4. **Scaffold — absolute path, never clobber.** Copy `$AGENT_OS_MEM/agents/_template/` →
   `$AGENT_OS_MEM/agents/<name>/`, then write the filled `AGENT.md` into it. The memory subdirs
   (`profile.md`, `skills/`, `scratch/`) come with the template — so the agent's definition and its
   memory share one portable folder. If `$AGENT_OS_MEM/agents/<name>/` already exists, show it and stop.
5. **Wire + close.** End the `AGENT.md` with the CONSTITUTION clauses this role most reinforces. No registry
   to edit — the orchestrator discovers its grown team by reading `$AGENT_OS_MEM/agents/*/AGENT.md` (the
   recall hook surfaces the roster at boot). Tell the user it's live and how to hand work to it.

## Hard rules (CONSTITUTION)
- **Confirm before writing** — preview the `AGENT.md`; nothing lands without an explicit yes.
- **One mechanism, two triggers** — scaffold into `$AGENT_OS_MEM/agents/<name>/` from the mind's
  `_template/`, *exactly* as `watch-review`'s `add-agent` does. Don't reinvent the scaffold; the only
  difference from the Watcher's path is who asked.
- **Single-purpose workers** — RISEN, one job each. If it sprawls, split it.
- **Never a second orchestrator** — workers live *beneath* the one orchestrator the user talks to.
- **Author, don't ship** — this grows *this* user's team; the seed's roster stays empty.
- **Least privilege** — give the worker only the scope its job needs, nothing more.
