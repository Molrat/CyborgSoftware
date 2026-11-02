---
name: verify
description: Run this repo's tests through run-tests.ps1 and read the result correctly — a layer SKIPPED for a missing prerequisite is not a layer that passed. Use when asked to run tests, verify a change works, check whether anything broke, or confirm the tree is green before a commit, a gate, or a handoff.
user-invocable: true
---

# /verify — run the tests, and read them honestly

[`run-tests.ps1`](../../../run-tests.ps1) is the entry point for all five layers.
Prefer it over hand-rolled `dotnet test`. Full description:
[docs/TESTING.md](../../../docs/TESTING.md).

## The trap this skill exists for

**A skipped layer is not a passing layer.** The script skips any layer whose
prerequisites are missing and still exits 0:

| Missing | Silently skips |
|---|---|
| No test projects under a `tests/<layer>/` folder | that layer |
| Docker not running | component, e2e **and** browser |
| The stack's Caddy container not up | e2e **and** browser |
| `containers/frontend/package.json` | frontend |

So "I ran the tests and they passed" can mean "I ran the unit tests, and the
four layers that touch a database, an HTTP pipeline and a browser never
executed." Never report green without saying which layers actually ran.

**A stale stack is a third trap, for e2e and browser.** Both run against the
containers that are *up*, not the code on disk: after a change, `docker compose
up -d --build` first, or the browser layer passes against yesterday's build.

**A browser test marked `test.fail()` is a known defect, not a pass.** It names
its `D-xxx`; Playwright counts it as passing while it keeps failing, and as an
error the moment the defect is fixed — remove the mark in that change.

## Procedure

**1. Pick the narrowest run that covers the change.**

```powershell
.\run-tests.ps1 -Unit -Frontend                                   # fast loop, no Docker
.\run-tests.ps1 -Component -NoBuild -Filter "FullyQualifiedName~<Feature>"
.\run-tests.ps1                                                   # everything available
```

**2. Read the output for SKIPPED, not just for failures.** Count the layers that
ran. If a layer needed for this change was skipped, either start its
prerequisite (`docker compose up -d`) and re-run, or say plainly that it was not
covered.

**3. On failure, fix at the lowest layer that can see the bug** — and a bug fix
ships with the test that would have caught it. If a component test fails for
something a unit test could have caught, the unit test is the missing one.

**4. Do not assert the same behaviour twice.** If the change is already covered
at a lower layer, do not add a higher-layer test for it.
[docs/TESTING.md](../../../docs/TESTING.md) fixes which layer owns what, and
`ACCEPTANCE.md` binds each scenario to exactly one.

## Report like this

> `.\run-tests.ps1` — **unit 138 ✓, frontend 279 ✓. Component and e2e SKIPPED
> (Docker not running).** The change touches `OrderRepository`, which only
> the component layer exercises, so it is not actually covered. Start the stack
> and re-run before treating this as green.

State what ran, what did not, and whether what did run was enough for *this*
change. Those are three separate facts.

## Conditions that are not your change

Check these before debugging; they look like a regression you just caused.
Known ones are recorded in [docs/DEBT.md](../../../docs/DEBT.md) — add one there
when you find it, so the next run does not debug it again.

- **`npm ci` may be stale.** If the frontend layer dies with
  `ERR_MODULE_NOT_FOUND`, `node_modules` is behind `package.json`; run `npm ci`
  in `containers/frontend` and re-run. That is an environment fault, not a test
  failure, and it must not be reported as one.
- **A layer that exits 1 while every test passes.** Vitest can report all tests
  passed and then fail on an unhandled rejection (a page's `onMounted` outliving
  its test, for instance). Read the summary line, not just the layer status, and
  say exactly what failed rather than reporting a red layer or a green one.

## Leave the doc true

[docs/TESTING.md](../../../docs/TESTING.md) states per-layer counts and names
every test project. If your run contradicts it — a project it does not list, a
count off by more than a handful, a gap in *What this system does not cover yet*
that is now closed — **fix the document in the same change**, including the
`<!-- test-inventory: ... -->` line that
[`check-testing-inventory.sh`](../../hooks/check-testing-inventory.sh) checks at
commit time. That hook will ask you at `git commit` anyway and prints the
corrected line; doing it here is the same work done while you still have the
numbers in front of you.

This is not tidiness. The cold `tester` agent reads that document *first* to
decide which layer owns a behaviour and what is already covered. A stale one
sends it to write tests that exist, or to skip a layer that is real.
