# Architecture

**How the system is built.** These documents describe the *target* system — the
one [../product/](../product/) specifies — not a snapshot of what compiles today.
Where the running code already matches, that is marked. Where it does not, that
is marked too, because a document that describes an intention as though it were
a fact costs a debugging session to discover.

Read [01-overview.md](01-overview.md) first; the rest goes deeper on one concern
each. The `*-patterns.md` files and `design-system.md` are the general rules and
change rarely; the numbered structure files describe what this application has
built on them.

| Document | Covers |
|---|---|
| [01-overview.md](01-overview.md) | System shape, the stack, container conventions, non-goals |
| [backend-patterns.md](backend-patterns.md) | The rules every backend feature follows: feature × layer projects, dependency direction, who adapts to whom, between features, errors, optimistic concurrency, startup |
| [02-backend-structure.md](02-backend-structure.md) | What the API contains: its features, `Shared`, the exceptions |
| [frontend-patterns.md](frontend-patterns.md) | The rules every screen follows: folders, component roles, the state layer, the API layer, text, hiding is a courtesy |
| [design-system.md](design-system.md) | How screens get one look and the UX requirements by construction: tokens, the kit, templates, the checks that refuse anything else |
| [03-frontend-structure.md](03-frontend-structure.md) | What the SPA contains: its screens and routes |
| [04-persistence.md](04-persistence.md) | Migrations, stored functions, the two-container pattern, data isolation, privileges |

Add a numbered document when a cross-cutting concern earns one — authentication,
authorization, file storage, background work — and a row here.

## Status markers

Every section that describes something not uniformly real carries one of three
markers. They mean exactly this and nothing softer:

| Marker | Means |
|---|---|
| **`[BUILT]`** | Running in this repo today. The described behaviour can be observed by starting the stack. |
| **`[PARTIAL]`** | Exists, but not in the shape the target needs. The section says what changes. |
| **`[SPEC]`** | Designed, agreed, **not written**. No code corresponds to it yet. |

A document with no marker at the top is uniformly `[BUILT]`. A `[SPEC]` section
is not a wish list — it is a decision already made, waiting for a
[roadmap](../roadmap/phases.md) sub-phase to reach it.

## Where the system stands

One row per concern: what is built, what is not, and where the detail lives.
How each part got here is in its roadmap sub-phase
([../roadmap/phases.md](../roadmap/phases.md)) — this table says only where
things stand. **Update it in the same change that makes it untrue** (root
`CLAUDE.md` rule 4).

| Concern | Status | Not built yet | Detail |
|---|---|---|---|
| Containers — Caddy, the API, Postgres with its migration and procedure containers, the frontend build | `[SPEC]` | everything | [01](01-overview.md) |
| Backend feature × layer structure, error envelope, startup | `[SPEC]` | everything | [backend-patterns](backend-patterns.md) · [02](02-backend-structure.md) |
| Optimistic concurrency on REST edits | `[SPEC]` | everything | [backend-patterns](backend-patterns.md#optimistic-concurrency-on-rest-edits) |
| Persistence — migrations, stored functions, privilege model | `[SPEC]` | everything | [04](04-persistence.md) |
| Data isolation — tenant or owner filtering in every function | `[SPEC]` — whether the system is multi-tenant is undecided | everything | [04](04-persistence.md#data-isolation-is-a-schema-property) |
| Authentication and roles | `[SPEC]` — not yet designed | everything | — |
| Frontend — folders, component roles, state layer | `[SPEC]` | everything | [frontend-patterns](frontend-patterns.md) · [03](03-frontend-structure.md) |
| Design system — tokens, kit, templates, checks | `[SPEC]` | everything | [design-system](design-system.md) |
| Test layers and `run-tests.ps1` | `[PARTIAL]` — the runner exists; no test project does | every layer | [../TESTING.md](../TESTING.md) |
| CI/CD | `[SPEC]` | everything | [../CI-CD.md](../CI-CD.md) |

## The rule this section exists to enforce

Every new capability is added as a **new feature folder**, front to back, without
editing what is already working. If a change forces you to reopen a stable class
to bolt on a branch, that is the signal to reach for an abstraction instead — see
[backend-patterns.md](backend-patterns.md#between-features) and
[../CODING-STANDARDS.md](../CODING-STANDARDS.md).

Truly cross-cutting concerns — authentication, data isolation — are the
deliberate exception: they are enforced in shared infrastructure and in the
database rather than per feature, and the document that owns each says why.
