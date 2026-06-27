# The Watcher loop (spec)

**Status:** spec (design only — the build is the next ticket). **Pairs with:** `AGENT.md` (who the
Watcher is). **Source:** distilled from `_research/agents/.r/architecture/envisioned-os/watcher.md` +
`eagle-eye.md` §6 + `loops-and-the-producing-layer.md`, reconciled to this repo. This file answers the
question the `AGENT.md` leaves open: *how does the Watcher actually run, talk to the user, and turn
findings into changes — without ever mutating the system silently?*

> The one line: the Watcher finds patterns while you're away, writes them as full-fidelity proposals
> into a **sovereign inbox** (it never reaches out — your next session's recall surfaces them), batches
> them into a **calm digest** with a narrow **urgent valve**, lets you **approve / modify / reject /
> snooze** in-loop where the mutation is safe, and **learns from every decision** so its bar climbs
> toward the things you actually say yes to.

---

## 1. Two jobs, kept separate (the design problem)

The Watcher runs on a slow cadence **outside** the working loop, so it arrives at its best findings *at
a moment the user isn't there.* That asynchrony hides two jobs — conflating them is the trap:

| Job | What it is | Where it must live |
|---|---|---|
| **Notification** | "I noticed something worth your time." | cheap, ambient |
| **Proposal + approval** | the full finding, its evidence, and the act of saying *yes* — which **mutates the OS** | sovereign, in-loop, reversible |

The loop below keeps them apart: notification is a passive count surfaced by recall; the proposal and
its approval happen in-loop, against a real working tree, where the change is previewable and
reversible.

---

## 2. The loop

```
OBSERVE ─▶ DETECT ─▶ §4 BOUNDARY TEST ─▶ PROPOSE (gated, → inbox) ─▶ DECIDE ─▶ LEARN
   ▲                                                                              │
   └──────────────────────── the bar tunes per kind ◀────────────────────────────┘
```

- **Downstream** (Watcher → user): observe → detect → test → propose.
- **Upstream** (user → Watcher): decide → learn → the bar adjusts. *Every decision is itself an
  observation* — this is what makes the Watcher *grow* rather than merely *run*.

---

## 3. What it observes (and what each becomes)

It reads the mind (the `.mem` vault — sessions, decisions, what recurs) and the shape of the work. Six
signal classes, each mapped to a gesture:

| Signal it watches for | Proposal kind | Lands as |
|---|---|---|
| The same component/convention reused across sessions | **promote-standard** | a `.proc` module (+ its tests) via `promote-standard` |
| Repeated manual work that fits a single-purpose worker | **add-agent** | a new RISEN `AGENT.md` in the team (`propose-agent`) |
| A repeated multi-step gesture | **add-skill** | a new skill the orchestrator/workers can invoke |
| **Drift** — work or direction pulling away from the CONSTITUTION or the foundation-and-scope boundary | **realign** | a flagged proposal naming the drift + a course-correction (no artifact; the change is *the user's attention*) |
| **A durable thing learned about the user**, not yet in their profile | **propose-self-update** | a gated update to `self/PROFILE.md` (the user model) |
| **A value or hard line the user has durably, clearly shown** | **propose-constitution-update** | a gated update to `self/CONSTITUTION.md` (Part 1 values / Part 3 non-negotiables) |

The first three *grow the system*; the fourth *holds the line* on it — the same "hold the line" the
orchestrator owns at the task altitude, raised to the system-evolution altitude. The last two *grow the
self*: **propose-self-update** curates `self/PROFILE.md` (the user model), and **propose-constitution-update**
grows `self/CONSTITUTION.md` (the user's law — Part 1 values, Part 3 non-negotiables). Both are what let
**genesis stay light** — capture a seed at first run (just a name + one value), then let the model *and* the
law accrue through use rather than a long up-front interview. Drift proposals are how the Watcher guards
against the system (or the user) quietly violating its own law or scope.

---

## 4. The bar — silence is a feature

A pattern qualifies for a proposal only after it **recurs past a threshold across distinct sessions**
(default: **observed ≥ 3 times in ≥ 2 sessions**; drift fires on a single *clear* contradiction of the
CONSTITUTION). Below the bar, the Watcher stays silent.

**Then every candidate must pass the foundation-and-scope §4 boundary test — all six, or it is dropped:**

1. **Real present need** — something actually being done requires it (not "cool / newly discovered").
2. **Serves the core purpose** — deepens orchestration-against-durable-memory, not a new purpose smuggled in.
3. **Lives at the edge** — a skill / worker / config / adapter, no stable-core rewrite.
4. **Leanest version** — the simplest thing that meets the need.
5. **Keeps the invariants** — portable, locale-neutral, sovereign, least-privilege, no-slop.
6. **Earns its complexity** — value clearly exceeds the surface area it adds.

The Watcher runs this test *itself*, in the proposal, and shows its reasoning per gate. A proposal that
can't show all six passing never reaches the inbox. *(This is the structural anti-feature-creep gate —
the Watcher is the one agent whose whole job is growth, so it is held to the strictest scope discipline.)*

**Which bar applies to which kind.** The §4 test gates the three *system-growth* kinds (`promote-standard`,
`add-agent`, `add-skill`) — the anti-feature-creep gate for adding to the OS. The other three aren't system
additions, so they have their own bars: **`realign`** fires on a *clear* CONSTITUTION/scope contradiction;
**`propose-self-update`** fires only when something about the user is *durable, true, and worth keeping the
profile high-signal* — curate the user model, never bloat it; **`propose-constitution-update`** fires only on
a value or hard line *durably and clearly demonstrated* (repeated, not a passing mood) — it touches the law
all agents answer to, so it carries the **highest bar** and the most careful review.

---

## 5. Cadence — calm digest, narrow urgent valve

- **Slow and reflective, not per-prompt.** Pattern-over-weeks. The per-prompt memory hooks are
  *plumbing*; the Watcher's proposals are *counsel* — different job, different frequency, different agent.
- **Digest by default** — qualifying proposals batch into a periodic memo ("three things I noticed this
  week"): one calm review session, not a stream of pings.
- **Urgent valve, deliberately narrow** — a proposal may jump the queue only if confidence **and** value
  are *both* high. Everything else waits for the digest. (This narrowness is the main thing to tune.)
- **Trigger mechanism (build decision, lean-first):** v1 is a **user-invoked `/watch` gesture** (run
  ad-hoc or from cron) that does one observation pass and writes any qualifying proposals to the inbox —
  the same propose-never-auto, manual-first posture as `promote-standard`, with `consolidate-memory`'s
  auto-nomination as the v2 precedent. **Autonomous scheduling (every Nth session / weekly cron) is
  deferred** to v2 once the bar has proven itself against real sessions.

---

## 6. The channel — a sovereign inbox, pure pull

**The Watcher never reaches out. It writes to an inbox; the user finds it on their terms.**

```
Watcher  ──writes──▶  memory/agents/watcher/inbox/   (pending proposals, full fidelity)
                                  ▲
recall-orient.sh (SessionStart) ──┘ counts + surfaces "N proposals waiting"
user opens session ─▶ reads ─▶ decides in-loop
```

- **No new transport.** Reuses the existing SessionStart recall surface — the inbox count is one more
  thing recall already does (orient you), not a channel to build and secure.
- **Sovereignty by construction.** Proposals are distilled from the user's own memory; nothing leaves
  the machine. (This is why external push — email/DM — is **rejected**: it would publish the user's mind
  to a third-party server *and* wire a disk mutation to an untrusted channel. If reach-when-away is ever
  truly needed, the only sanctioned form is a content-free **doorbell** that still forces the user
  back in-loop to read and decide — a pointer, never the payload.)
- **Where it lives:** `memory/agents/watcher/inbox/` — the Watcher's private agent space (per the
  `.mem/agents/<agent>/` convention; first real use of per-agent memory — see task 13). Pending
  proposals are **episodic**; once decided they become a decision record (§8) — **semantic** — which can
  promote to the shared `decisions/` bucket when the lesson is reusable.

---

## 7. Anatomy of a proposal (the build's file format)

One file per proposal in `inbox/`. It leads with evidence and ends with a previewable change — never a
vague nudge. Build target:

```markdown
---
memory_type: episodic
type: watcher-proposal
date: <ISO-8601-UTC>
kind: promote-standard | add-agent | add-skill | realign | propose-self-update | propose-constitution-update
status: pending          # pending | approved | modified | rejected | snoozed
confidence: low | med | high
urgent: false            # true only if confidence AND value are both high
tags: [watcher, proposal]
---
# <one-line pattern headline>

**Pattern:** the recurring thing noticed, in one line.
**Evidence:** which sessions/dates it appeared, how many times (so the user can judge salience).
**Proposal:** the concrete change — e.g. "add a `scheduler` worker".

**Boundary test (§4):** ① need … ② core purpose … ③ edge … ④ leanest … ⑤ invariants … ⑥ earns it —
each shown passing, with one line of why.

**Diff preview:** the actual artifact it would write (the `AGENT.md` / module skeleton / the drift +
correction) — see the change before it lands.

**Gate:** approve · modify · reject · snooze
```

---

## 8. The gate — four doors, never silent

The Watcher proposes; it never acts. Every proposal has exactly four exits:

- **Approve** → run the matching gesture (`promote-standard`, the new `propose-agent`, etc.). The
  mutation happens **in-loop against a real working tree**; the diff preview becomes the actual write,
  and for a `.proc` module its tests run as the oracle that proves it's good.
- **Modify** → adjust, then approve. The **highest-signal door**: the user accepted the *intent* but
  corrected the *shape*. Capture *what* changed, not just *that* it was approved.
- **Reject** → archived **with a reason**. A reasonless no teaches nothing; a reasoned no is half the
  upstream loop.
- **Snooze** → "not now," not "no" — returns to the inbox to re-surface on a later cadence.

> The **Uatu line:** unlike the Marvel Watcher, ours may *intervene* — but only ever by asking. No exit
> mutates the OS without the user's explicit yes, in-loop.

---

## 9. The upstream loop — decisions train the bar

Each decision is captured as a signal; the accumulation becomes a model of the user's taste that feeds
back into the bar, **per kind**:

```
decision (approve/modify/reject + reason) ─▶ episodic note (memory/agents/watcher/) ─▶ taste model ─▶ bar
                                                                                           │
                                          the bar raises/lowers per kind ◀─────────────────┘
```

Concretely: if `add-agent` proposals are rejected several times running, the Watcher **raises the bar
for that kind** — fewer, surer agent proposals — while leaving `promote-standard` untouched. A reasoned
rejection sharpens it faster than a bare no; a *modify* sharpest of all. Over weeks the proposals
converge on what the user actually says yes to. A decision that taught a durable lesson promotes to the
shared `decisions/` bucket — same machinery as the rest of the mind. **(v1 may capture the signals and
defer the automatic bar-tuning to v2 — record the decisions first, learn from them second.)**

---

## 10. Built vs. to-build (no overclaiming)

- ✅ **Reuse (exists):** the `recall-orient.sh` SessionStart surface the inbox count piggybacks on; the
  `memory/agents/<agent>/` private-space convention; the gated-gesture pattern (`promote-standard`) and
  its propose-never-auto contract; the episodic→semantic promotion arc a decision rides.
- 🔵 **Build (task 11):** the `/watch` observation pass; the `inbox/` store + recall-side count/surface;
  the proposal file format (§7); the `propose-agent` gesture; the four-door gate handling; capturing
  decisions for the taste model (auto-tuning deferred to v2).

---

## 11. Portable vs. Claude-Code-specific

| Portable (OS plane — any harness) | Claude-Code-specific (this adapter) |
|---|---|
| The loop, the six signal classes, the §4 gate, the bar | The recall-side "N proposals waiting" surface in `recall-orient.sh` |
| The proposal file format + the four-door gate semantics | The `/watch` gesture + the gate gestures as `skills/` |
| The sovereign-inbox + pure-pull principle | Any cadence wiring (cron / event hook) if/when v2 autonomy lands |
| The upstream taste-loop design | — |

---

## 12. CONSTITUTION mapping

- **Sovereignty:** the inbox is local; proposals are distilled from the user's mind and never leave the
  machine; external push is refused by design.
- **Guard the irreversible / least privilege:** approval (a disk mutation) is in-loop, previewable,
  reversible; nothing fires from an untrusted channel.
- **No yes-men / propose-never-auto:** the Watcher only ever proposes; the four-door gate is the user's.
- **Lean-first:** v1 reuses the recall surface and the gated-gesture pattern; `/watch` is manual before
  autonomous; auto-bar-tuning is deferred.
- **Truth over comfort:** the **drift / realign** signal exists precisely to surface unflattering truths
  about the system drifting from its own law — the Watcher must name drift, not smooth it over.

---

## 13. Open items for the build (task 11)

1. **Inbox surfacing in `recall-orient.sh`** — count pending proposals and emit "N waiting" (cheap,
   alongside the existing orient).
2. **The `/watch` gesture** — a skill that does one observation pass (read recent `.mem`, apply the bar +
   §4 test, write qualifying proposals to `inbox/`).
3. **The gate gestures** — how approve/modify/reject/snooze are invoked, and how `approve` hands off to
   `promote-standard` / the new `propose-agent`.
4. **First write of per-agent memory** — `memory/agents/watcher/` is the inbox's home; this is the first
   real exercise of that bucket (coordinate with task 13).
5. **Defer to v2:** autonomous cadence (scheduled `/watch`) and automatic bar-tuning. v1 = manual pass,
   capture decisions, learn-by-hand.

---

## 14. Verification (task 12 — proved end-to-end)

**Method:** a staged proof in a **sandbox** (throwaway vault + vault `.proc`, so the live mind and the
real seed are never touched — `scratchpad/prove_watcher.sh`). The proposal is **genuine**, mined from
this project: the staged throwaway-`$HOME` proof-harness was re-authored 4× across tasks 07/09/11/12 — a
real `promote-standard` candidate that passes all six §4 gates. **11/11 checks passed.**

The loop, proven in order:
- **Observe → Propose:** the Watcher writes a gated proposal to its inbox — and at the propose stage
  **nothing in the OS mutates** (no artifact written, real seed `git status` unchanged).
- **Surface:** `recall-orient.sh` counts it → "1 proposal waiting" (pure-pull).
- **Approve → Applied:** the gate runs the `promote-standard` gesture in-loop — the scaffold lands in the
  **vault** `.proc/scaffolds/` (a promoted standard is the user's, not shipped in the seed), the proposal
  is archived `approved` in `decided/`, and the decision is captured as a taste signal.
- **No-mutation guarantee:** the real seed repo is untouched end-to-end; the gesture fires **only** on the
  explicit approval, never before.

**Note / follow-up:** the proof *applied* the promotion only in the sandbox. The genuine proposal it
surfaced — promote the proof-harness pattern into a real `.proc` scaffold — is left for the user's actual
gate, exactly as the propose-never-auto contract demands.
