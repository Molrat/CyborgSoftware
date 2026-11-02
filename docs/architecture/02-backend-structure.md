# Backend Structure

**What the API contains** — its features, what `Shared` holds, and every
deliberate exception to [backend-patterns.md](backend-patterns.md). The rules
are there; this file is the inventory, and it is updated by the change that
alters what it lists (root `CLAUDE.md` rule 4, `/feature-slice` step 7).

| Section | Status |
|---|---|
| Everything below | `[SPEC]` — no API exists yet |

Markers are defined in [README.md](README.md#status-markers).

## Layout `[SPEC]`

```
containers/
  backend/
    api/
      src/
        <Api>.Host/                      Program.cs, configuration, DI
        <Api>.Shared/                    framework-free: errors, role names, interfaces
        <Api>.Shared.Infrastructure/     middleware, Postgres access, implementations
        <Feature>/                       one folder per feature, five projects each
    db-migrations/migrations/            V###__description.sql
    db-procedures/procedures/<table>/    sp_<table>_<verb>.sql
```

> `[OPEN]` The API's name (`<Api>` above) is fixed in Phase 0, with the
> container layout.

## The features

| Feature | Kind | Edge | Holds |
|---|---|---|---|
| *(none yet)* | | | |

*Kind* is business logic, plain record, or plumbing
([backend-patterns.md](backend-patterns.md#who-adapts-to-whom)). *Edge* is how
the outside world reaches it — REST routes, a background worker, nothing.

**The worked example.** Once the first feature exists, name it here: it is the
slice `/feature-slice` tells the next one to copy.

## `Shared`

| Area | Project | Holds | Moved there by |
|---|---|---|---|
| *(none yet)* | | | |

A row is added when the second consumer moves something here
([backend-patterns.md](backend-patterns.md#between-features)).

## Exceptions

Every deliberate departure from [backend-patterns.md](backend-patterns.md), with
the reason and the condition that would remove it. None yet.

## Optimistic concurrency — where adopted

| Resource | Adopted |
|---|---|
| *(none yet)* | |
