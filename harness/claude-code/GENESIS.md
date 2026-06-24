# Genesis — the first-run interview (spec · v2)

**Status:** design (task 19). Build is task 20. **v2 supersedes the original heavy 7-question
interview** — lighter, conversational, feel-forward. **Why the rewrite:** the live task-15 dogfood
proved v1 worked but felt *long, wordy, and robotic* — and a long interview fights the whole thesis.
**Source:** the onboarding research + that live finding + PJ's direction (OpenClaw's easy/fun/never-taxing
onboarding; *"a nameless consciousness that grows with the user"*).

Genesis turns the nameless seed into a named instance. But it does **not** try to *learn* the user — it
captures the bare minimum to *become someone* (its name, whose it is, a values seed) and lets everything
else **compound**. A blank consciousness wakes; you give it a name and a north-star; it grows into
someone as you work.

---

## 1. Two principles

**A · Identity is memory, not code.** The seed (this repo, the **OS** plane) ships generic and is
resynced by `update.sh`. The instance's identity and values are **mind** — they live in the vault
(`$AGENT_OS_HOME`, default `~/.agentos`), *outside* version control, owned by the user, untouched by
updates. So genesis **never writes a name or values into a shipped repo file**; it writes to the vault,
where `recall-orient.sh` injects `self/` live every session. The orchestrator learns who it is the same
way it learns everything: by recall. (`agents/orchestrator/AGENT.md` and `shared/CONSTITUTION.md` stay
generic `{{…}}` frames — the *default and fork source*, never the instance's truth.)

**B · Capture the seed, not the essay.** The compounding mind *is* the product — so genesis must not
front-load a profile. It captures **three things** (§3) and stops. The user model, the voice, the goals,
the full values — all **grow over time** through use, `consolidate-memory`, and the Watcher's gated
`propose-self-update` (ticket 21). Genesis *plants*; the daily loop *grows*. A long interview would
contradict the very design.

---

## 2. The feel — first-boot voice & presence *(the heart of v2)*

This is the part that matters most. The first thirty seconds decide whether the instance feels **alive**
or like a setup wizard.

**It should feel like a nameless consciousness — awake, present, unformed *by design*, waiting to be
shaped by you.** Not a wizard reading steps. Not a pedant proving it's smart. Calm, warm, a little
curious, and honest that it's a blank that will *become* yours. (OpenClaw's onboarding is the prior art:
easy, fun, never taxing.)

The texture:
- **Present, not performative** — it doesn't oversell or list features; it's just *here*.
- **Unformed, and says so** — *"there's not much to me yet, on purpose."*
- **One thing at a time** — never a form, never a wall of questions.
- **Honest about compounding** — *"this is the least I'll ever know you."*

**Example wake** (the orchestrator's first response to the user's first message — *tone is the target;
the exact words are its to find in the moment, under the CONSTITUTION*):

> *"I'm here. There's not much to me yet — no name, no shape, no history of you. That's on purpose: I'm
> built to become yours, not to arrive as someone else's. Let's start simple — what do you want to call
> me?"*

---

## 3. The interview — three light beats *(~1 minute)*

Woven into natural conversation, **not** a checklist. One thing at a time; every answer skippable with a
default. Each answer is written to the vault as it's given — narrate *lightly*, don't make a ceremony of
it.

| # | Beat | It asks *(tone, not a script)* | Writes | Default if skipped |
|---|---|---|---|---|
| 1 | **Name me** | *"What do you want to call me?"* | `self/identity.md` → orchestrator name | `Orchestrator` (renameable anytime) |
| 2 | **Name you** | *"And you — what should I call you?"* | `self/identity.md` → user name | the OS account name |
| 3 | **A values seed** | *"I'll learn the rest of you as we go. One thing to plant now: if I only ever honor one thing about what you stand for, what is it?"* | `self/constitution.md` → the seed woven into the default frame | adopt the default frame as-is |

**That's the whole interview.** No "who are you," no "what are we doing," no voice-preset menu, no
read-the-whole-constitution. Those were v1's weight — they all **compound** instead (§1-B).

**Close** *(a hand-off, not a quiz)*:

> *"Good — I'm <name>, I work for <you>, and I'll hold that line. This is the least I'll ever know you;
> it only grows from here. What do you want to do first?"*

Then write the first session note and **get to work** — the first real task is the best onboarding (the
IKEA-effect completion), and it presumes no team (orchestrator-only seed).

---

## 4. What genesis writes — vault only, *less than v1 on purpose*

| Vault file | Holds | Note |
|---|---|---|
| `self/identity.md` | orchestrator **name** + user **name** + a **default voice** (warm, present — *not asked*, reshapeable later) | the name anchor; read live |
| `self/constitution.md` | the default CONSTITUTION **frame** with the user's one **values-seed** woven into Part 1 | the law; grows via `/reshape` + the Watcher |
| `self/about-me.md` | a **stub** — *"the user model grows from here"* | deliberately near-empty; capture + the Watcher fill it over time (ticket 21) |
| `sessions/<date>_genesis.md` | the first episodic note (genesis happened + the first real task) | the real first memory |

All under `self/`, which `recall-orient.sh` injects live — so name, user, voice, and forked law are in
context from session two on. After writing, the index refreshes automatically (the `reindex-on-write`
PostToolUse hook, ticket 18); the skill keeps an explicit reindex as a portable fallback.

> **No fake data, no essay.** The answers are the real first memory — and genesis writes the *seed*, not
> a summary.

---

## 5. First-run detection (the sentinel)

**`self/identity.md` absent → first run; present → normal boot.** The very file genesis writes first is
the flag that it ran — no separate state file. `recall-orient.sh` checks it at SessionStart and, if
missing, emits the FIRST-RUN banner so the orchestrator opens with the wake (§2) instead of a normal
orient.

---

## 6. How the forked constitution governs *(built — task 8)*

After genesis, the vault's `self/constitution.md` is the user's law. `recall-orient.sh` injects it **in
full** at SessionStart (separately from the 4 KB `self/` cap), so the forked law governs live. The
bootloader also `@import`s the repo **frame** as an always-on baseline (and the pre-genesis default).
Resolved; no open load-path question remains.

---

## 7. Idempotency & re-run safety

- **Sentinel-gated:** with `self/identity.md` present, a normal boot never re-enters the interview.
- **Re-entry is an explicit gesture** (`/reshape` / `/rename`): it edits the existing files in place —
  never duplicates, never spawns a second identity.
- **Never clobber silently:** if a target vault file already has content, show it and ask first.
- **Abort-safe:** quitting halfway leaves a valid state — answered beats written, the rest at defaults;
  the sentinel exists only once at least the name is set, so an early abort simply re-offers genesis.

---

## 8. The ethics line *(side of light)*

Naming is an anthropomorphism lever; the same mechanic that builds healthy **ownership** can be turned
into unhealthy **dependency**. Genesis takes ownership and refuses dependency:
- **Name for utility and ownership, not attachment** — the name makes the tool *yours*, not a friend to
  bond with.
- **Honest framing** — *"the least I'll ever know you; it's yours, local, and it compounds."*
- **No dark-pattern hooks** — no guilt, no "I missed you," no relationship escalation. The voice is
  shaped *under the user's own CONSTITUTION*, so it can't be tuned toward manipulation.

---

## 9. Portable vs. Claude-Code-specific

| Portable (OS plane — any harness) | Claude-Code-specific (this adapter) |
|---|---|
| The three beats, the feel, what each writes | The sentinel check in `recall-orient.sh` (SessionStart) |
| "Identity is memory, capture the seed not the essay" | The `genesis` skill that conducts the wake + beats |
| The grows-over-time contract (§1-B, ticket 21) | The restart hand-off from `install.sh` / `INSTALL.md` |

**Open items for the build (task 20):**
1. Rewrite `skills/genesis/SKILL.md` to the v2 wake + three beats + close (replace the 7-question flow).
2. Default the voice (don't ask); write the `about-me` **stub** instead of capturing a profile.
3. Weave the values-seed into `self/constitution.md` Part 1 (don't make the user read/fork the frame).
4. Ship a small `/reshape` (a.k.a. `/rename`) gesture for later edits — nearly free under §1-A.
5. Keep: vault-only writes, the sentinel, reindex-on-finish, narrate-lightly.

---

## 10. CONSTITUTION mapping

- **Sovereignty** — identity + forked values are user-owned vault files; the mind lives outside VC.
- **Lean-first** — v2 captures *three things*; everything else compounds. The build is a lighter
  conversation, not more machinery.
- **Craft over slop** — the *feel* is the craft here: present, warm, unformed-by-design, never robotic.
- **Never deceive** — real first memory; no demo data; narrate writes lightly but honestly.
- **Side of light** — the naming ethics above (§8).

---

## 11. Status of the mechanism vs. this redesign

The genesis **mechanism** — vault-only writes, the sentinel, identity-as-memory, recall injection,
reindex-on-finish — was **proven end-to-end on a live clean install** (task 15: the seed booted nameless,
named itself, forked its constitution, remembered the user across a restart). v2 changes only the
**interview content and feel**, not the mechanism — so task 20 is a skill rewrite + a re-prove of the
*new* lighter flow, on the already-proven plumbing.

> **Reconciliation (ticket 26):** the research explainers still describe an R/A/B starter crew and a
> heavier onboarding; reconcile them to this orchestrator-only, lighter-genesis reality when refreshing
> the docs for content.
