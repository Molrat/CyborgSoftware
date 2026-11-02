# System Overview

A container-per-responsibility platform with strict isolation. This document
explains the shape of the system, why each container exists, and which seams are
load-bearing.

| Section | Status |
|---|---|
| The stack | Decided 2026-11-02 by the user: the same stack as the project this setup was taken from |
| Top-level shape, container inventory, routing, lifecycle | `[SPEC]` — nothing built; the container list is the starting shape, and adding to it is a decision (root `CLAUDE.md` rule 3) |

Markers are defined in [README.md](README.md#status-markers).

## The stack

| Layer | Choice |
|---|---|
| Frontend | Vue 3 SPA, TypeScript, Pinia, Vue Router, Vite; Vitest + happy-dom for tests |
| Backend | ASP.NET (C#), feature × layer projects ([backend-patterns.md](backend-patterns.md)) |
| Data access | Dapper calling PostgreSQL stored functions — no ORM ([04-persistence.md](04-persistence.md)) |
| Database | PostgreSQL |
| Edge | Caddy — TLS, SPA host, reverse proxy, one origin |
| Operations | Docker Compose; one-shot containers for migrations, procedures and the frontend build |
| Tests | xUnit (unit, component with Testcontainers, e2e), Vitest, Playwright ([../TESTING.md](../TESTING.md)) |

Exact package versions are approved and recorded when Phase 0 installs them
(root `CLAUDE.md` rule 3).

## Top-level shape `[SPEC]`

```
┌──────────────────────── Browser ────────────────────────┐
│               Vue 3 SPA · Pinia · Vue Router            │
└───────────────────────────┬─────────────────────────────┘
                            │  https (single origin)
                            ▼
                      ┌──────────┐
                      │  Caddy   │  TLS · SPA host · reverse proxy
                      └────┬─────┘
                           │  /api/*
                           ▼
                      ┌──────────┐
                      │   api    │  ASP.NET
                      └────┬─────┘
                           ▼
                      ┌──────────┐
                      │    db    │  PostgreSQL
                      └──────────┘
```

**Same origin, on purpose.** Caddy serves the SPA and proxies `/api/*`, so the
browser sees one origin: cookies need no cross-site settings, and there is no
CORS to configure or get wrong.

> `[OPEN]` Whether identity (users, sessions, roles) is a separate service with
> its own database, or a feature of the one API. Start with one API; split when a
> seam measurably hurts (*Non-goals*, below). Decided with the user before the
> first authentication sub-phase.

## Container inventory `[SPEC]`

| Container | Kind | Does |
|---|---|---|
| `caddy` | long-lived | TLS (`tls internal` locally), serves the built SPA from its mount, proxies `/api/*` |
| `api` | long-lived | The ASP.NET API |
| `db` | long-lived | PostgreSQL |
| `db-migrations` | one-shot | Applies versioned schema files, then exits 0 |
| `db-procedures` | one-shot | Redeploys every stored function, then exits 0 |
| `frontend` | one-shot | `npm run build` (type check, lint, Vite), copies `dist` to Caddy's mount, exits |
| `mailpit` | long-lived, development only | Catches outgoing email at `http://localhost:8025` |

## Container lifecycle conventions

| Type | `restart` | Notes |
|---|---|---|
| Long-lived | `unless-stopped` | API, DB, Caddy |
| Migrations | `no` | Exits 0 after applying versioned migrations |
| Procedures | `no` | Exits 0 after redeploying all functions |
| Frontend | `no` | Builds, copies to Caddy's mount, exits |

`depends_on` with `condition: service_completed_successfully` chains the one-shot
containers ahead of the services, so an API never starts against a half-migrated
database — and a frontend that fails its build leaves the running site as it was.

## Compose project identity

The project is named `cyborgsoftware`, and containers are `cyborgsoftware-*`
([`run-tests.ps1`](../../run-tests.ps1) looks for `cyborgsoftware-caddy`). Keep
the name distinct from every other compose project on the same machine: compose
keys volumes and container names off it, and a collision means one stack
silently adopts the other's database volumes.

## Local development

- `docker compose up -d --build` after a change, before e2e, the browser layer,
  or `/look` — they all see the running containers, not the tree.
- Development-only port mappings (the database on `127.0.0.1`, for the e2e
  layer's direct reads) live in `docker-compose.override.yml`, which is
  git-ignored; `docker-compose.override.example.yml` is its template.
- **Caddy's local certificate is self-signed.** Clicking through the browser
  warning is enough for pages, but not for a service worker's script fetch;
  trusting Caddy's local CA once per machine is what works:
  ```powershell
  docker cp cyborgsoftware-caddy:/data/caddy/pki/authorities/local/root.crt local-ca.crt
  certutil.exe -addstore -user -f Root local-ca.crt
  del local-ca.crt
  ```

## Non-goals

Kept out by design, not by omission:

- **No Kubernetes.** Docker Compose is the operational unit.
- **No ORM, no EF Core.** Plain SQL in stored functions, Dapper to call them.
- **No JWTs** unless a decision says otherwise. Server-side opaque session
  cookies are simpler and revocable.
- **No service splitting** until a seam measurably hurts.
- **No premature shared package.** Code is extracted the first time a second
  consumer needs it, not before.
- **No frontend state-framework swap.** Pinia is the state layer; extract pure TS
  logic *into* it, don't replace it.
