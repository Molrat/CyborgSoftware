---
name: gate
description: Write or walk a roadmap phase gate — copy the template BEFORE the code is written, check preconditions, walk the numbered checks, record results. Use when starting a roadmap phase, closing one, or when asked to write, prepare, or walk a manual test gate.
user-invocable: true
---

# /gate — the human checkpoint between phases

A gate is the one control the roadmap actually specifies, and its value depends
entirely on *when* it is written:

> A gate written after the work is a description of what was built.
> A gate written before it is a specification.

Template: [docs/roadmap/gate-template.md](../../../docs/roadmap/gate-template.md).
Sub-phases: [docs/roadmap/phases/](../../../docs/roadmap/phases/). Acceptance
scenarios that gates bind to: [docs/product/ACCEPTANCE.md](../../../docs/product/ACCEPTANCE.md).

## Starting a phase — write the gate first

1. Copy the template into the gate section of the sub-phase's own file.
2. Fill the checks **before any code exists**, from
   [ACCEPTANCE.md](../../../docs/product/ACCEPTANCE.md) and the product docs —
   not from what you plan to build.
3. Each check is **one observable behaviour**, written so a person who did not
   build the feature can perform it without asking questions. "Works correctly"
   is not a check. "Assign the task to a colleague; it appears on their
   dashboard without a second action by you" is.
4. If a check cannot be written because the behaviour is undecided, that is an
   `[OPEN]` question, not a vague check. Log it and ask.

## Walking a gate

**Preconditions first — all of them, honestly.** A gate walked on a stale build
proves nothing.

- `/verify` — and say which layers actually ran; a skipped layer is not a pass
- `docker compose build` succeeds
- `docker compose up -d` — one-shot containers exit 0, services running
- architecture docs updated for everything the phase changed
- no `TODO`, commented-out code, or stubbed implementation in the phase's files
  (`git diff <phase-start>..HEAD` then grep it)

Dispatch the **`tester`** agent while preparing a gate: it derives what must be
true from [ACCEPTANCE.md](../../../docs/product/ACCEPTANCE.md) and the gate's own
checks rather than from the built code, so it finds the rows that would fail
before a person walks them.

**Pre-walk it in the browser — every row, before the person sees it.** Run
[`/look`](../look/SKILL.md) through the gate's *Setup* and then each check in
order, as the account the row names. Per row, record the agent's verdict beside
it — *looks right*, **looks wrong** (what was seen, screenshot), or *cannot be
judged in a browser* (a PDF's content, an email, a judgement of wording) — and
fix every **looks wrong** that the phase built before handing over. The
pre-walk is the agent's look, never the row's result: the *Pass* column stays
empty for the person. What it buys is a walk that finds nothing an agent could
have found, and a person who knows which rows to look at hardest.

**Then walk the checks in order** and record the real result per row. A check
that cannot be performed is not a pass — mark it and say why.

## What this skill will not do

**It does not mark a gate passed.** The gate is a person walking the table —
that is the entire point of a checkpoint between phases, and it is why the
template says "a person who did not build the feature."

Prepare the gate, verify the preconditions, pre-walk it, report what the tester
and the pre-walk found, and hand it over — to the user per
[/talk-to-human](../talk-to-human/SKILL.md#walking-a-gate). If every precondition
holds, say the gate is *ready to walk*, not that it passed.
