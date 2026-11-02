# Roadmap

How the product gets built: sub-phases with **manual test gates** between them.

The gates are the point. An AI agent can produce a great deal of
internally-consistent code that solves the wrong problem, and automated tests
written from the same misunderstanding will pass. A human looking at the running
software is the only check that catches that class of error, and it has to happen
before the next sub-phase builds on top of it.

| Document | Contents |
|---|---|
| [phases.md](phases.md) | The sub-phase index — what exists and what state each is in (generated) |
| [phases/](phases/) | One file per sub-phase: its definition, its state, its gate |
| [subphase-template.md](subphase-template.md) | The format a sub-phase is defined in |
| [gate-template.md](gate-template.md) | The checklist format each gate uses |
| [build-index.sh](build-index.sh) | Regenerates the index in `phases.md` from the files |

## Rules

**One sub-phase at a time.** A sub-phase is not started until the previous gate
has passed. No working ahead.

**A sub-phase is defined just before it is built, never earlier.** A definition
written three sub-phases ahead is a guess about a codebase that does not exist
yet. Sketch the shape as far forward as it stays useful; *define* exactly one at
a time, through `/define-next`, immediately before building it.

**A sub-phase is a whole feature, not a piece of one.** A planner, a review
queue, an admin screen — something a person can be handed and asked to use. Not
a dropdown, not a card, and not "the backend for X". If it cannot be stated in
one sentence as something a user does, it is either too small to be a sub-phase
or it is secretly two.

**A sub-phase is full-stack, and the screen is part of the feature.** Schema,
API and the real screen, in one slice. A backend-only sub-phase is refused — it
cannot be gated, so it cannot be finished.

**Never build an intermediate UI to exercise an API.** A page that exists to
prove an endpoint works is not a step towards the feature; it is a test written
in the most expensive possible medium, and it has to be thrown away. Verifying
request and response is the component layer's job
([../TESTING.md](../TESTING.md)) — the whole service in-process, real routing,
real middleware, real Postgres — and Swagger covers the rest. A sub-phase whose
frontend is a harness is mis-scoped, not nearly done.

**The bar for that screen is functional, usable, and built from the design
system's kit** ([../architecture/design-system.md](../architecture/design-system.md)).
It works end to end; it is assembled from `@/kit` and its templates only, so it
looks and behaves like every other screen and carries the UX requirements the
kit builds in; it passes the design-system checks and, in its browser journey,
`checkScreen` at desktop and phone width. When the kit lacks something, the kit
grows in the same sub-phase. "Functional" is not licence to ship something
provisional — the screen a user gets is the screen that stays.

**A gate is a human sitting in front of the running application.** Not a test
report, not a description of what was built, not a screenshot. The stack is up,
and a person clicks through the checklist.

**A gate fails on any unchecked item.** Fixes happen inside the sub-phase that
owns them; the gate is then re-run from the top. A partially-passed gate is a
failed gate.

**Every sub-phase ends green.** Every test layer that exists passes before the
gate is even attempted. See [../TESTING.md](../TESTING.md).

## Sub-phase states

Every sub-phase carries exactly one of five states, recorded in **one place** —
its own file, in frontmatter. Not here, and not in a hand-maintained table
anywhere else. A status written down twice is a status that will eventually
disagree with itself.

| State | Means | What moves it on |
|---|---|---|
| `DRAFT` | Named, sketched at most. Not defined well enough to hand to anyone. | `/define-next`, ending in a `readiness` verdict of READY |
| `READY` | The `readiness` agent checked the definition and found nothing missing. Safe to build. | Implementation starts |
| `BUILDING` | Being written now: schema, then API, then UI; tests; architecture docs. | Every test layer green **and** the gate written |
| `BUILT` | Code done, tested, gate written — and **nobody has walked it**. | A person walks the gate |
| `COMPLETE` | A person walked the gate against the running application, and it passed. | — |

**`BUILT` is the state a roadmap loses work in.** Built-but-unwalked work looks
finished and is not verified, and if it shares a name with work still being
written, it accumulates unnoticed — several sub-phases deep before anyone counts.
That is why it has its own state, and two rules follow:

- **`BUILT` is not a kind of done.** Nothing may be built on top of a sub-phase
  that is still `BUILT` unless the user explicitly chooses it, recorded in both
  sub-phase files — and then both gates are walked together. `/continue` offers
  the walk before any new work while any sub-phase sits there.
- **A sub-phase cannot reach `BUILT` without its gate.** The gate is written at
  the *start*, from the definition — see [gate-template.md](gate-template.md).
  A gate written afterwards describes what was built instead of specifying it.
  Work with no gate that stopped is `BUILDING`, not `BUILT`.

## Sub-phase anatomy

```
  ┌─────────┐   /define-next    ┌─────────┐    implement    ┌──────────┐
  │  DRAFT  │ ────────────────► │  READY  │ ──────────────► │ BUILDING │
  └─────────┘   readiness says  └─────────┘                 └────┬─────┘
                     READY                                       │
                                         layers green + gate     │
                                                                 ▼
  ┌──────────┐    gate passes    ┌───────┐
  │ COMPLETE │ ◄──────────────── │ BUILT │ ◄── nothing is built on top of here
  └──────────┘  a human, in the  └───────┘
                  running app         │
                                      └── fails ──► fix inside this sub-phase,
                                                    re-walk the gate from the top
```

## Ids

A sub-phase id is a number that sorts in build order under `sort -V`: `0`,
`1`, `1.1`, `1.2`, `2`. Group related sub-phases under a shared prefix when a
larger capability is delivered in several whole features. Ids are never reused.

## Current state

Each sub-phase records its own state, in the frontmatter of its own file under
[phases/](phases/). That is the only place it is written by hand.

[phases.md](phases.md) shows all of them in one table so a person can see the
roadmap at a glance — but that table is **generated** from those files by
[build-index.sh](build-index.sh), never edited directly. Rerun the script after
any state change; if the table and a file disagree, the file is right.
