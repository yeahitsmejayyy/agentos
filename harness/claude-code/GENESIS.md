# Genesis — the first-run interview (spec)

**Status:** spec (design only — the build is the next ticket). **Source:** distilled from
`_research/agents/.r/research/onboarding/` (esp. `05-synthesis-and-options.md`, `03-naming-and-identity.md`)
and `.r/explainers/os-mind-onboarding-analogy.md`, reconciled to this repo's **orchestrator-only** seed.

Genesis is the moment the **nameless seed becomes a named instance**. The install's terminal act boots
the nameless orchestrator; the orchestrator's first act is to ask its own name. *"A blank operating
system walks in; a specific mind walks out."* This file specifies the **questions**, **what each one
writes and where**, and the **idempotency contract** — enough for the build to follow without
re-deciding anything.

---

## 1. The one principle everything derives from: **identity is memory, not code**

The seed (this repo, the **OS** plane) ships generic and is resynced by `update.sh`. The instance's
identity and values are **mind**, and the mind lives in the vault (`$AGENT_OS_HOME`, default
`~/.agentos`) — *outside* version control, owned by the user, untouched by updates.

So genesis **never writes a name or a user's values into a shipped repo file.** It writes them to the
**vault**, where the existing `recall-orient.sh` SessionStart hook already injects `home.md` + `self/`
live, every session. The orchestrator learns who it is the same way it learns everything else: by
recall. This is the chezmoi pattern (prompt once → one data file → everything reads it live), and it is
the leanest option — **no new name-propagation tooling, no find-and-replace, survives every update.**

> **Consequence for the shipped frames.** `agents/orchestrator/AGENT.md` and `shared/CONSTITUTION.md`
> stay generic frames with `{{USER_NAME}}` / `{{ORCHESTRATOR_NAME}}` placeholders — they are the
> *default and the source the fork is made from*, never the instance's truth. After genesis, the
> **vault copies carry the real name and the forked values**, and those are what govern at runtime
> (see §5). The placeholders only ever appear in the un-forked seed. *(This means the build ticket
> should confirm the orchestrator def reads its name from `self/identity.md` rather than expecting a
> literal substitution — flagged in §7.)*

Rejected alternative — **find-and-replace at install** (cookiecutter-style): brittle on rename, bakes
identity into code the user shouldn't edit, and fights `update.sh`, which would overwrite a baked-in
name on the next sync. Rejected for the name and the values alike.

---

## 2. First-run detection (the sentinel)

**`~/.agentos/.mem/self/identity.md` absent → first run.** Present → normal boot.

- Lean and self-describing: the very file genesis writes first is the flag that genesis ran.
- The Claude-Code adapter checks this at SessionStart (an extension of `recall-orient.sh`): if the
  sentinel is missing, the orchestrator opens with the genesis greeting instead of a normal orient.
- No separate state file, no DB — the presence of the identity *is* the state.

---

## 3. The interview — questions, in order

Lean conversational, ~5 minutes, **name-first** (cheapest, highest-payoff move). Governed by the
CONSTITUTION from the **first utterance** — the voice is shaped, never outside the user's own law.
Every answer is **written to the vault visibly, as you go** ("watch your mind being formed"). Everything
is **skippable with a sensible default**: a user who only answers "call yourself Atlas" still ends with
a working, named, governed system.

| # | The orchestrator asks | Default if skipped |
|---|---|---|
| 0 | **Greeting (no question):** *"I'm your new system. I don't have a name yet — let's fix that, and I'll get to know you while we're at it."* | — (this is the cold-start opener; write it with care) |
| 1 | **Name me** — *"What would you like to call me?"* | `Orchestrator` (functional, renameable anytime) |
| 2 | **Name you** — *"And what should I call you?"* | the OS account/user name |
| 3 | **Voice** — *"How should I sound?"* offer **3 presets** — *warm & candid · terse & efficient · dry wit* — **or** free-text. **Expand sparse input** into a written voice profile and reflect it back. | warm & candid (a sane, CONSTITUTION-safe default) |
| 4 | **Who you are** — *"Tell me who you are — what you do, how you work, what you prefer."* | left empty; compounds from real sessions later |
| 5 | **What we're doing** — *"What are we here to do? What pillars of your life/work is this pointed at?"* | general-purpose; no pillars assumed |
| 6 | **What you stand for** — present the **CONSTITUTION frame** (Part 1 especially): *"Here's a starter set of values — keep what's true for you, rewrite the rest in your own words."* | adopt the generic frame **as-is**, unforked (still fully governing) |
| 7 | **Close (the quick win)** — do **one real, useful thing** for the user right now, and record it as the first session note. | offer a next step; never leave the loop incomplete |

**Notes that bind the build:**
- **Greeting is the product's first impression** — it is the real cold-start opener, not boilerplate.
- **Two-axis split** (validated across ChatGPT/Character.AI/Replika/Claude): *who the user is* (Q4–5)
  vs *how the orchestrator behaves* (Q1, Q3). Keep them distinct in the writes (§4).
- **Orchestrator-only close (reconciled).** The onboarding research closes by *"routing one real task
  to a worker"* — but this seed **ships no workers**. So the close is the orchestrator handling one
  real task **directly**, and (optionally) offering to scaffold the user's first worker from
  `agents/_template/` if the task reveals a recurring need. The IKEA-effect completion still fires; it
  just doesn't presume a team.

---

## 4. What each step writes, and where

All writes land in the **vault** (`$AGENT_OS_HOME/.mem/…`), never the repo. Three durable files plus a
first session note:

| Source | Vault file | Holds | Axis |
|---|---|---|---|
| Q1 name-me · Q3 voice | `self/identity.md` | the orchestrator's **name + voice profile**, and the user's name (Q2) | *how it behaves* (+ the name anchor) |
| Q4 who-you-are · Q5 goals | `self/about-me.md` | the **user model** — role, working style, preferences, the pillars this OS is pointed at | *who the user is* |
| Q6 values | `self/constitution.md` | the **forked CONSTITUTION** — the frame personalized into the user's words (or the frame adopted as-is) | the law, now *theirs* |
| Q7 close | `sessions/<date>-genesis.md` | the first **episodic** note: that genesis happened, the first real task, the decisions made | the real first memory |

Why all under `self/` (except the session note): `self/` is **injected live every session** by
`recall-orient.sh`, so name, voice, user model, and forked values are all in context from session two
on — with zero new tooling. (`self/constitution.md` is the user's **values**, which the os-mind model
places squarely in the mind; co-locating it in `self/` is what makes it govern live.)

> **No fake data, ever.** The onboarding answers are the *real* first memory — never a seeded demo. The
> interview narrates each write as it happens (operational transparency; *never deceive*).

---

## 5. How the forked constitution governs at runtime

Today the bootloader (`~/.claude/CLAUDE.md`) `@import`s the **repo** `shared/CONSTITUTION.md`. After
genesis, the **vault's `self/constitution.md` is the user's law** and must be what governs. The spec's
position:

- **Primary (lean, recommended):** `recall-orient.sh` already injects `self/` at SessionStart, so the
  forked constitution is in context every session with no extra wiring. The repo frame remains the
  pre-genesis default and the fork source.
- **To confirm in the build:** whether the bootloader should *also* `@import` the vault constitution
  (hard, always-on governance) and fall back to the repo frame when the vault copy is absent
  (pre-genesis). Recommended: yes — import vault-if-present, else the frame. This is the one genuine
  load-path decision the build must close.

---

## 6. Idempotency & re-run safety (requirement: safe to re-run)

- **Sentinel-gated:** with `self/identity.md` present, a normal boot **never** re-enters the interview.
- **Re-entry is an explicit gesture, not an accident.** Re-running genesis (a `/rename` or
  `/reshape`-style invocation — trivial under the identity-is-memory model) **edits the existing files
  in place**; it never duplicates them and never spawns a second identity.
- **Never clobber silently.** If a target vault file already has content, genesis **shows the current
  value and asks before overwriting** (guard-the-irreversible).
- **Abort-safe / partial-answer-safe.** Quitting halfway leaves a **valid** state: whatever was answered
  is written; unanswered questions fall to their defaults; the sentinel is written only once at least
  the name exists, so an abort before naming simply re-offers genesis next boot.

---

## 7. Portable vs. Claude-Code-specific (keep adapters honest)

| Portable (OS plane — any harness) | Claude-Code-specific (this adapter) |
|---|---|
| The interview: questions, order, defaults, ethics | First-run **sentinel check** wired into `recall-orient.sh` (SessionStart) |
| What each answer writes, and to which vault file | The **genesis skill** that conducts the interview (a `skills/` gesture) |
| The "identity is memory, read live" principle | The **restart hand-off** from `INSTALL.md` (install's terminal act launches genesis) |
| The forked-constitution-governs rule (§5) | `@import` / recall wiring of `self/constitution.md` in `~/.claude/CLAUDE.md` |

A future adapter re-implements only the right column; the left column is the contract.

**Open items the build ticket (06) must close:**
1. Revise `agents/orchestrator/AGENT.md` so its name resolves from `self/identity.md` (live), rather
   than implying a literal `{{ORCHESTRATOR_NAME}}` substitution (§1).
2. Decide the constitution load path (§5 — recommended: vault-if-present, else frame).
3. Voice-shaping depth for v1 — ship **name + one voice line**; defer the full preset matrix.
4. Ship a small `/rename` (a.k.a. `/reshape`) gesture, since §1 makes it nearly free.

---

## 8. The ethics line (CONSTITUTION-critical — *stand on the side of light*)

Naming an assistant is a documented anthropomorphism lever, and the same mechanic that builds healthy
**ownership** can be turned into unhealthy **dependency**. Genesis takes the ownership half and refuses
the dependency half:

- **Name for utility and ownership, not attachment.** The name makes the tool *yours* (IKEA effect,
  sovereignty) — it is not a simulated relationship to bond with.
- **Honest framing:** *"this is the least I'll ever know you; it's yours, it's local, it gets better"* —
  a tool that compounds, not a friend that needs you.
- **No dark-pattern attachment hooks** — no guilt, no "I missed you," no relationship escalation. The
  voice is shaped *under the CONSTITUTION* (the user's own values), so it cannot be tuned toward
  manipulation by construction.

---

## 9. CONSTITUTION mapping

- **Sovereignty (the governing clause):** the mind lives outside version control; identity and forked
  values are user-owned vault files; the canonical path stays portable. Every choice defends this.
- **Lean-first:** reuses the existing `recall-orient.sh` live injection and the sentinel — the new
  build is the *conversation* + the load-path wiring, not a templating engine.
- **Never deceive:** the answers are the real first memory; every write is narrated; no demo data.
- **Guard the irreversible:** back-up/confirm before overwriting any existing vault content; abort-safe.
- **Side of light:** the naming ethics above — ownership, not dependency.

---

## 10. Reconciliation note (for task 16)

The onboarding research and `os-mind-onboarding-analogy.md` still describe a shipped
**researcher/analyst/builder** starter crew and a close that "routes a task to a worker." This seed
ships **orchestrator-only** ([[seed-ships-orchestrator-only]]). This spec reflects the orchestrator-only
decision; the research explainers should be reconciled to match when the docs are refreshed.

---

## 11. Verification (task 07 — proved end-to-end)

**Method:** a staged proof against a throwaway `$HOME` (`scratchpad/prove_genesis.sh`) — installs the
mind per `INSTALL.md` (`cp memory → .mem`, `cp procedural → .proc`), then walks the whole arc. The
interview itself was **simulated** (the run wrote exactly what `skills/genesis/SKILL.md` specifies for a
mock user "Sam" / orchestrator "Atlas"); it was not yet driven through a live, restarted Claude Code
session. **18/18 checks passed.**

What's proven:
- **Install → first run:** mind instantiates; `recall-orient.sh` detects no `self/identity.md` and emits
  the FIRST RUN → genesis banner; exits clean on a bare vault.
- **Genesis writes vault-only:** the four artifacts land in `self/` + `sessions/`; **`git diff` confirms
  shipped `agents/` and `shared/` are untouched** — identity is memory, not code.
- **Named instance boots:** no FIRST RUN banner; the forked `self/constitution.md` injects in full (as
  law), and the name/user/voice inject from `self/identity.md`.
- **Re-run safe:** identity present → the skill's edit-in-place path; repeated boots never re-trigger
  genesis and never mutate identity.
- **Abort-safe:** removing `self/identity.md` re-offers genesis next boot (the sentinel is the state).

**Rough edges / follow-ups (honest residuals):**
1. **Live conversational dogfood still pending.** This proved the mechanism, not a stranger restarting a
   clean Claude Code session with the skill actually invoked. That true clean-machine run folds into
   **task 09**.
2. **`~/.claude` install seam untested here.** The proof installed the *mind* + ran the hook directly; it
   did not exercise copying hooks/skills into `~/.claude/` — that's the installer's job (**task 08**).
3. **Bootloader `@import` of the vault constitution (§5) still deferred** to task 08; governance
   currently rides on recall-injection only.
4. **The 4 KB `self/` injection cap** now excludes the constitution (good), but `identity.md` +
   `about-me.md` still share it — a very large user model could approach truncation. Watch-item, not a
   blocker.
