# Sub-phase — Template

Copy to `phases/<id>-<slug>.md` at the **start** of `/define-next`, and fill it
in during that conversation. The `readiness` agent reads this file and nothing
else about the sub-phase — if a decision is not written here, it does not exist.

Do not copy this for a sub-phase you are not about to build. Definition is
just-in-time ([README.md](README.md)).

---

```
---
id: "1.2"
title: Planner workspace
state: DRAFT            # DRAFT | READY | BUILDING | BUILT | COMPLETE
readiness: none         # none | READY | NOT-READY — verdict of the last check
updated: 2026-11-02
---
```

## What a person can do when this is finished

One sentence, in the user's language, naming the actor and the outcome. *"A
planner can lay out a week of work and assign each job to a colleague."*

If this sentence cannot be written, this is not a sub-phase. It is either too
small (a control, not a feature) or it is two features wearing one name.

## In scope

The screens, the actions, the entities. Specific enough that "did we build it"
has a yes/no answer.

## Deliberately out of scope

**Required, not optional.** What a reasonable person would expect here and will
not get, and why. An empty *out* list means the boundary was never drawn.

## Determined by

The specification sections this is derived from — `docs/product/...`,
`docs/architecture/...`, acceptance scenarios in
[../product/ACCEPTANCE.md](../product/ACCEPTANCE.md). Enough that the next
person can check the reasoning rather than re-deriving it.

## Decisions this needed

Every product question that had to be answered before this could be defined,
with its answer and where the answer is recorded. Questions answered by the user
during `/define-next` are written into
[../product/OPEN-QUESTIONS.md](../product/OPEN-QUESTIONS.md) first, then cited
here.

Never resolved by picking something reasonable — root
[CLAUDE.md](../../CLAUDE.md) rule 1.

## What this is built on

Each thing this depends on, with its status marker **confirmed against the tree,
not the docs** (`/spec-check`). Anything `[SPEC]` or `[PARTIAL]` is a blocker,
not a note.

## Full-stack shape

Schema → API → **screen**. The screen is part of the feature, not a harness to
prove the API works; automated tests and Swagger do that job. Name the routes,
the stores, the kit components it uses — and any it adds — and the screens a
person will actually use.

## Debt folded in

Entries from [../DEBT.md](../DEBT.md) whose trigger this fires and the user chose
to take, or "none". Skipped ones are recorded on the entry, not here.

---

## Gate <id> — <title>

Copied from [gate-template.md](gate-template.md) and filled in **here, now**,
before any code is written. A sub-phase cannot reach `BUILT` without it.
