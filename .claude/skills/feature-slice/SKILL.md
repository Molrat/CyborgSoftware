---
name: feature-slice
description: Add a feature to the API end to end — status check, migration, stored functions, the five layer projects, DI registration, the screen from the kit, tests, a look at it in the browser, and the doc update that closes it. Use when adding any new feature, entity, table, or endpoint group to a .NET API in this repo, or when asked to build the next slice of a roadmap phase.
user-invocable: true
---

# /feature-slice — a vertical slice, front to back

A feature is a **vertical slice**, not a layer. Build it whole, in one pass.
Structure rules: [backend-patterns.md](../../../docs/architecture/backend-patterns.md);
what already exists, and which feature is the worked example to copy:
[02-backend-structure.md](../../../docs/architecture/02-backend-structure.md).
(The first feature built becomes that example — name it there when it lands.)

**Adding a feature is additive.** A new folder, five projects, no edit to an
existing feature. If a change forces you to reopen a working feature to bolt on
a branch, stop and reach for an abstraction instead.

## 0. Before writing anything

**Run `/spec-check` on everything this slice sits on.** Building on a `[SPEC]`
substrate as though it exists fails silently.

**Check what is undecided.** `grep -rn "\[OPEN\]" docs/product` for this area,
and [docs/product/OPEN-QUESTIONS.md](../../../docs/product/OPEN-QUESTIONS.md).
If the slice needs a product decision that is not written down: add it there and
**ask**. Do not resolve it by picking something reasonable.

**Check for new dependencies.** A package, service or container the slice needs
that is not already approved is proposed to the user with alternatives first
(root `CLAUDE.md` rule 3) — not installed and mentioned afterwards.

**State the scope before building it** — which entities, which endpoints, what
is deliberately deferred. Get agreement on that, not on the code.

## 1. Schema

Next `V###__description.sql` in `db-migrations/migrations/`. Never edit an
applied one — a hook will refuse it, and
[04-persistence.md](../../../docs/architecture/04-persistence.md) says why.
Follow the data-isolation rule the persistence doc records for this system
(e.g. `tenant_id UUID NOT NULL` on every application table, if it is
multi-tenant). Put a header comment saying *why* the shape is what it is.

## 2. Stored functions

One per file, `sp_<table>_<verb>`, in `db-procedures/procedures/<table>/`.
Any isolation parameter (`p_tenant_id`, if the system has one) comes first and
is filtered on, in the function — not the repository, not the service. Every
file ends with its `GRANT EXECUTE ... TO ${APP_USER}`. Explicit column lists.

## 3. The five projects

```
<Feature>/
  <Api>.<Feature>.Domain/        entities, value objects, invariants — pure, in business terms
  <Api>.<Feature>.Interfaces/    I*Repository, I*Service — in Domain types, never a wire or row shape
  <Api>.<Feature>.Data/          Dapper, calls sp_* by name, maps rows into Domain types
  <Api>.<Feature>.Services/      orchestration, role checks, transactions
  <Api>.<Feature>.Controllers/   transport only — owns request/response classes, maps both ways
```

Domain touches no database, HTTP, file access, logging, configuration or JSON.

**Decide first whether the feature holds business logic or is a plain record**
([backend-patterns.md](../../../docs/architecture/backend-patterns.md#who-adapts-to-whom)).

Controllers inject **service interfaces**, never concrete types, and read as a
list of `await service.X(...)` with no business decisions in them. Role names
come from `<Api>.Shared/Auth/Roles.cs`; which combination an action needs is
feature-local, in the feature's own internal `RoleGuard`.

## 4. Wire it up

Four things, and the fourth is the one that gets missed:

1. `.csproj` references following `Domain <- Interfaces <- {Data, Services, Controllers}`: Domain and
   Interfaces reference `<Api>.Shared` only; Data, Services and Controllers add
   `<Api>.Shared.Infrastructure`
2. the five projects added to the `.sln`
3. an `Add<Feature>Feature()` registration called from `Program.cs`, in its own
   commented block
4. **`AddApplicationPart(typeof(<Feature>Controller).Assembly)`** — without it the
   build is green and every route 404s

## 4a. The screen — from the kit

The screen is built from `@/kit` and nothing else
([design-system.md](../../../docs/architecture/design-system.md#building-a-screen--the-rules)):
a `PageFrame`, `AsyncContent` for everything it loads, `Stack`/`Card` to arrange
it, and the kit's buttons, fields, pills, dialogs and tables. Open `/kit` in the
running app to see every piece. **Do not copy an existing screen's markup or
CSS** if it is on `kit-exemptions.json`.

Put every decision in the framework-free layer
([frontend-patterns.md](../../../docs/architecture/frontend-patterns.md#state-management--the-core)),
a store as its reactive face, and a page that only calls actions and renders.
Mark a protected route `meta.requiresAuth`.

The checks run at every edit (the hook), in `/verify` and in the deploy build.
When one refuses something, build it from the kit; when the kit lacks the
piece, **add it to `src/kit/`** — a component or variant, its Vitest test, its
`/kit` entry, and the re-recorded screenshot
(`npx playwright test design-system --update-snapshots`), which the gate then
signs off. Never quiet a rule or grow the exemption list; the commit guard asks
the user about both. New UI on an exempt screen goes in a new component.

## 5. Tests

Unit for domain logic (`new` it up, no DI, no DB). Component for the HTTP + real
Postgres path. No service-layer mocking. Do not assert the same behaviour at two
layers. Then run **`/verify`** and report which layers actually ran.

**A browser journey, when the slice adds a path a person must be able to
walk** — a new screen reached from an existing one, a new step in a flow, or a
hand-off between two roles. Add or extend one in `tests/browser/journeys/`,
seeded through `tests/browser/support/`, naming the gate rows it saves, and add
it to the journey table in [TESTING.md](../../../docs/TESTING.md) ⑤. One journey
per path, not per rule — rules stay at the layers below. **The journey calls
`checkScreen(page)`** (`tests/browser/support/quality.ts`) on each kit-built
screen it reaches: the accessibility scan, and at phone width the check for
sideways scroll and controls off-screen. A commit that adds a screen with no
journey change is stopped and asked about (`check-browser-journey.sh`).

Dispatch the **`tester`** agent for the adversarial half — data isolation, role
refusal, boundary dates, concurrency, the error envelope. It works from
[ACCEPTANCE.md](../../../docs/product/ACCEPTANCE.md) rather than from what you
wrote, which is the only way it can find what you missed.

## 6. Look at it in the app — this is not optional either

Rebuild the stack and run **[`/look`](../look/SKILL.md)** on every screen the
slice added or changed: as each role that uses it, through the definition's
*What a person can do* and the gate's rows, on a desktop and on a phone-sized
screen. A kit-built screen with a phone problem is fixed in the slice. Compare
its look with `/kit`. Fix what it finds before going on, and report the walk —
path, screenshots, console — with the slice. Green tests on a screen nobody has
seen is how a gate walk turns into a bug hunt.

## 7. Close the slice — this is not optional

The slice is finished when the docs say what it decided, not when it compiles:

- [docs/architecture/README.md](../../../docs/architecture/README.md#where-the-system-stands)
  — update *Where the system stands*, including any marker this slice moved from
  `[SPEC]` to `[PARTIAL]` or `[BUILT]`
- [02-backend-structure.md](../../../docs/architecture/02-backend-structure.md)
  — add the feature to the feature table (its kind, its edge, what it holds),
  and anything it moved into `Shared`
- [03-frontend-structure.md](../../../docs/architecture/03-frontend-structure.md)
  — the screen and its route
- any `[OPEN]` marker this slice resolved, deleted from both registers
- a scoped `CLAUDE.md` beside a new area, if something there bites — and its
  row in the root `CLAUDE.md`

This is the only thing carrying a decision into the next slice, which starts
with none of this conversation's context.

A `PreToolUse` hook asks about this at `git commit` when a new feature area has
no `docs/architecture/` change beside it.

## 8. Have it reviewed

Dispatch the **`reviewer`** agent on the finished diff. It starts cold and reads
the architecture doc before your code, so it can see what the slice failed to do
rather than why it is reasonable. Fix what it finds, or say why not.
