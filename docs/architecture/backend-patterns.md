# Backend Patterns

The rules every backend feature follows: how a feature is cut into layers, which
way the dependencies point, how features relate, and the cross-cutting
mechanisms (errors, optimistic concurrency, startup). They do not change when a
feature is added. **What the API actually contains** — the features, `Shared`,
and which exception lives where — is
[02-backend-structure.md](02-backend-structure.md).

| Section | Status |
|---|---|
| Feature × layer projects, dependency direction, the layers, who adapts to whom, between features, error envelope, optimistic concurrency, startup | `[SPEC]` — the rules are decided; no feature exists yet |

Markers are defined in [README.md](README.md#status-markers).

## Feature-first, layer-second

The API is organised **feature-first, layer-second**. Each top-level concern is
a *feature* — a sibling folder — and within a feature every layer is its own
`.csproj`:

```
<Feature>/
  <Api>.<Feature>.Domain/
  <Api>.<Feature>.Interfaces/
  <Api>.<Feature>.Data/
  <Api>.<Feature>.Services/
  <Api>.<Feature>.Controllers/
```

## Why per-layer projects and not folders

Compile-time enforcement of dependency direction. A Domain project *cannot*
reference HTTP types, a Data project *cannot* bypass Interfaces, a Controller
*cannot* reach into a sibling feature's internals — because the reference simply
isn't there. Folders rely on discipline; project references rely on the compiler.

```
Domain <- Interfaces <- { Data, Services, Controllers }
  |           |                      |
  v           v                      v
<Api>.Shared  <---------  <Api>.Shared.Infrastructure
```

Controllers depend only on **service interfaces**, never on concrete services or
repositories.

`Shared` is two projects for the first guarantee's sake: `<Api>.Shared` is
framework-free — errors, role names, cross-feature vocabularies and the
repository and data-access *interfaces*, with no package at all — and is all a
Domain or Interfaces project may reference. `<Api>.Shared.Infrastructure` holds
what needs the web application — middleware, Postgres access, JSON reading and
every implementation of a `Shared` interface — and only Data, Services,
Controllers and the host reference it.

## The layers

### Domain — the core

**Contains**: entities, value objects, domain services, calculations, business
invariants, validation rules with business meaning, pure transformations,
policies.

**Must not touch**: database, HTTP, EF Core, file access, queues, external APIs,
logging, SMTP, configuration, JSON. The domain stays pure so it can be
unit-tested by `new`-ing it up — and so that it changes only when the business
does ([*Who adapts to whom*](#who-adapts-to-whom)).

### Interfaces — the contracts

One `Interfaces` project per feature, holding every contract between that
feature's layers. Keep them narrow and role-based: no consumer should depend on
members it doesn't use.

The contracts speak the Domain's language: their arguments and results are
Domain types, plain values, or a read result the service defines for one
screen, named for what it is. Never a request or response body, a table row, or
a JSON document.

### Data — persistence

Repositories serve the service layer. SQL, Dapper, and storage calls stay hidden
behind the interface. A repository calls stored functions by name and maps the
result; it never builds SQL strings. It maps **into Domain types**: a row class,
where a row does not map straight onto one, lives here and goes no further, and
`jsonb` is converted here.

### Services — orchestration

Coordinates repositories, domain, transactions, external services,
authorization, and workflows. Ownership checks, status checks, and cross-resource
orchestration live here. **No heavy business rules** — those belong in Domain.

Authorization splits across this boundary rather than sitting wholly on one side:
the service performs the **role** check and loads what the decision needs, then
hands the loaded data to the domain, which decides any business-rule permission.
The domain never fetches what it judges. **Data isolation** (tenant or owner,
where the system has it) is neither — it is filtered in the stored function, on
every call ([04-persistence.md](04-persistence.md#data-isolation-is-a-schema-property)).

### Controllers — transport

A controller body should read as a list of `await service.X(...)` calls with no
business decisions in it. Model binding, delegate, return. It owns its request
and response classes and maps them to and from the service contract — the
response a screen needs is the controller's business, not the service's.

## Who adapts to whom

The business logic must change only when the business does. So the dependency
runs one way in **meaning**, not only in project references: the Domain owns its
types, the service contracts in `Interfaces` speak them, and the edges
translate. Nothing inward takes the shape of an HTTP body, a table row or a JSON
document, so a new column, a renamed field or a screen wanting one more value
changes an edge and a mapping, and no rule.

| Layer | Owns | Never holds |
|---|---|---|
| Domain | entities and values in business terms; closed sets as `enum`s; the rules | JSON, HTTP or database types; audit columns; `row_version`; fields a screen reads alongside |
| Interfaces | service and repository contracts in Domain types; a read result shaped for one screen, named for what it is | a type that is "the wire shape" or "the row"; `*Request`, `*Response`, `*Dto`, `*Row` |
| Controllers | request and response classes, and the mapping both ways | business decisions |
| Data | row classes, `jsonb` conversion, and the mapping into Domain types | business decisions |

- **Bookkeeping stays out of the entity.** `created_at`, `updated_by_user_id`
  and `row_version` describe the stored row. Where a screen shows one ("last
  changed") it travels in a read result. Where an edit needs `row_version`, the
  service takes it as an argument and returns it beside the entity, and the
  controller turns it into the `ETag`.
- **Closed sets are `enum`s; open vocabularies are data.** A set the code
  decides — a status, an outcome, a severity — is an `enum`, so a value nobody
  handles does not compile. A vocabulary that is reference data — a category a
  user or administrator can add to — stays a value read from data.
- **Content with no decided structure stays opaque.** Where the product has not
  decided what a block of content contains, the Domain carries it as a small
  value type that holds the content without reading it; `Data` converts it to
  and from `jsonb`; the controller passes it through. Giving one a structure is
  a product decision (root `CLAUDE.md` rule 1), not a refactor.
- **A repository contract may take `ISqlTransaction`.** Coordinating a
  transaction is the service's job (*Services*, above). It takes nothing else
  from the database.

**The direction holds for every feature. The modelling effort follows the
logic** — business types, `enum`s, bookkeeping kept out pay where there are
rules to protect, and are not worth their mapping where there are none:

| Kind | Is | What applies |
|---|---|---|
| Business logic | A feature with rules to protect — lifecycles, judgements, validity | All of the above |
| Plain record | Typed in, read back, no rule | The Domain type may mirror its row. Request and response classes still live in `Controllers` — it costs no extra type, since the service returns the Domain record |
| Plumbing | Moves bytes or messages without judging them | The direction only |

Which kind each feature is: the *Kind* column of
[02's feature table](02-backend-structure.md#the-features). A plain record that
gains a rule moves to the first row in the same change.

## Between features

**Adding a feature is additive.** A new feature folder, its projects, its
registration in the host and the `.sln`. No existing feature is edited. If a
change forces you to reopen a stable class to bolt on a branch, that is the
signal to reach for an abstraction instead
([../CODING-STANDARDS.md](../CODING-STANDARDS.md)).

**A feature never references another feature's projects.** When it needs a
fact another feature owns, it declares a narrow `*LookupRepository` in its own
`Interfaces` and implements it in its own `Data` by calling the owning
feature's stored function directly. The stored function is the shared contract;
the C# projects stay unconnected.

**A second consumer is the trigger for `Shared`, never the first.** A pure
algorithm, a helper or a lookup moves to `<Api>.Shared/<OwningArea>/` (its
implementation, if it touches storage, to `<Api>.Shared.Infrastructure/<OwningArea>/`)
when a second feature needs the identical thing — moving the one copy that
exists, not writing a second, and not before a second consumer is real. That
move is not an edit to the first feature in the sense of the rule above.

**`Shared` reads; it does not write another feature's rows.** Every
cross-feature type in `Shared` is a lookup. A cross-feature *write* is a new
pattern and is discussed first (root `CLAUDE.md` rule 3); if one is ever
allowed, it is recorded in [02](02-backend-structure.md) with the reason and
the condition that removes it.

**Role names are shared; role combinations are local.** The names live once, in
`<Api>.Shared/Auth/Roles.cs`. Which combination of them an action requires is
feature-local, in that feature's own internal `RoleGuard`; a feature needing a
different combination gets its own rather than widening a shared one.

## Error handling

Business code throws typed `ApplicationError` subclasses — `ValidationError`,
`NotFoundError`, `ForbiddenError`, `ConflictError`, plus feature-specific ones.
A single `ExceptionHandlingMiddleware` in `<Api>.Shared.Infrastructure/Middleware`
catches everything downstream and maps it to one envelope:

```json
{ "code": "email_already_in_use", "message": "Email already in use", "details": null }
```

The frontend parses that one shape. Endpoints never write
`BadRequest(new { message = "..." })` directly — that bypasses the envelope.
`code` is stable and machine-readable (the frontend translates it); `message` is
for logs and developers, never shown to a user as-is.

The middleware is registered **first**, before authentication, so it wraps
everything including auth failures.

> `[OPEN]` `[ApiController]`'s automatic model-validation `400` produces
> ASP.NET's own problem-details shape, not this envelope. Decide in Phase 0
> whether to suppress it (`SuppressModelStateInvalidFilter`) and map binding
> failures into the envelope, so the frontend parses one shape for every error.

## Optimistic concurrency on REST edits

Edits over REST are optimistic: a person overwriting another person's edit is
refused, not silently won. Every edit that adopts it takes this shape:

| Piece | Where | What it does |
|---|---|---|
| `row_version INTEGER NOT NULL DEFAULT 1` | the table | The token. |
| `rowVersion` returned by the service | Interfaces — **beside** the entity, never inside it, for a business entity | List rows carry it too, so a list-then-edit screen needs no extra read. |
| Strong `ETag: "<row_version>"` | single-resource `GET` and the `PUT` response, via a shared `RowVersionHeaders.SetETag` | The same token, HTTP-shaped. |
| `If-Match: "<row_version>"` required | `PUT`, via `RowVersionHeaders.ReadIfMatch` in the controller | Missing or unparseable → `400` `validation_failed`. The client skipped the protocol; no new error class. |
| Compare-and-increment in **one** statement | the `sp_*_update` function: `WHERE ... AND row_version = p_expected_row_version`, `SET row_version = row_version + 1` | Never a read-then-write in C#. |
| One `GetById` after every write | the service | It returns the fresh view on success; when the write matched zero rows it tells the cases apart — absent (or not visible to this caller) → `404`; present → `409` `stale_row_version` (`ConflictError`, `details.currentRowVersion`). A row the caller may not see therefore never reads as `409`, which would confirm it exists. |

The frontend sends the `rowVersion` it rendered as `If-Match` and, on `409`,
keeps what the person typed and offers to load the newest version — the only
path that discards their input.

Status transitions (`approve`, `start`, …) keep their own status guards
instead — a transition guards itself.

## Startup

`Program.cs` owns configuration and DI registration, and nothing else. It reads
as: shared infrastructure, then one block per feature — an
`Add<Feature>Feature()` extension method each, split across
`ServiceRegistration*.cs` files when one would pass the 200-line limit (a size
split, not a responsibility one). Lifetimes are explicit — `AddScoped` for
per-request work (repositories, services, the current-user accessor),
`AddSingleton` for stateless or cache-holding components.

Controllers live in their own assemblies, so each feature also needs
**`AddApplicationPart(typeof(<Feature>Controller).Assembly)`** — without it the
build is green and every route 404s.
