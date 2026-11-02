# Manual Test Gate — Template

Copy this into the gate section of the sub-phase's own file in [phases/](phases/)
when the sub-phase is defined, so the acceptance criteria are written **before**
the code is.

A gate written after the work is a description of what was built. A gate written
before it is a specification.

---

## Gate N — <sub-phase name>

**Preconditions** — all must hold before the gate begins:

- [ ] `.\run-tests.ps1` — every layer that exists passes, and none this sub-phase needs was skipped
- [ ] `docker compose build` succeeds
- [ ] `docker compose up -d` — all one-shot containers exit 0, all services running
- [ ] Architecture docs updated for anything this sub-phase changed
- [ ] No `TODO`, commented-out code, or stubbed implementation left in the sub-phase's files
- [ ] Pre-walked by an agent in the browser (`/look`, per `/gate`): every row's verdict noted, every *looks wrong* fixed

**Setup** — how to get to a testable state:

```
docker compose down -v      # if a clean database is needed
docker compose up -d
```

*Note any seed data or accounts the tester needs.*

---

### What does not belong in a gate

**Anything an automated test can assert.** A gate costs a person an afternoon;
a component test costs seconds and runs on every commit. If a check can be made
by sending a request and reading the response, it is a component test
([../TESTING.md](../TESTING.md) ② — the whole service in-process, real routing,
real middleware, real Postgres) and it does not belong here. A gate check
written as a `curl` command is almost always a test nobody wrote.

What is left is what no test can see: whether the thing on screen is the thing
the customer asked for, whether an error message means anything to the person
reading it, whether an empty state explains itself, whether the flow can be
completed by someone who did not build it. That is the whole reason a person
walks a gate — automated tests written from a misunderstanding pass happily.

**A gate that grew long is usually full of checks that should be tests.** Move
them.

### Checks

Each check is one observable behaviour. Write them so a person who did not build
the feature can perform them without asking questions.

| # | Action | Expected | Pass |
|---|---|---|---|
| N.1 | | | ☐ |
| N.2 | | | ☐ |

### Failure paths

The half that gets skipped, and where the bugs are. Every check here deliberately
does the wrong thing.

| # | Action | Expected | Pass |
|---|---|---|---|
| N.F1 | Submit the form with required fields empty | Inline validation, nothing saved | ☐ |
| N.F2 | Open another user's resource by its address | The same "not found" as a resource that does not exist; no data leaked | ☐ |
| N.F3 | Reload mid-task | State is as specified — either preserved or cleanly reset | ☐ |
| N.F4 | Interrupt the network during a save | User is told; work is not silently lost | ☐ |

### States

| # | State | Expected | Pass |
|---|---|---|---|
| N.S1 | Empty — no data yet | Purposeful empty state, not a blank table | ☐ |
| N.S2 | Loading | Specified feedback within the threshold | ☐ |
| N.S3 | Error | Message from the standard envelope, with a recovery path | ☐ |

---

### Result

**Date**:
**Tester**:
**Outcome**: PASS / FAIL
**Unchecked items**:
**Follow-up** *(fixed inside this sub-phase, then the gate re-runs from the top)*:

> A gate fails on any unchecked item. Partial passes do not carry forward — that
> is precisely the compounding-error problem gates exist to prevent.
