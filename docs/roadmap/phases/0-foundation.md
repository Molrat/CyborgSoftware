---
id: "0"
title: Foundation
state: DRAFT
readiness: none
updated: 2026-11-02
---

# 0 — Foundation

**A sketch, not a definition.** `/define-next` turns this into a definition with
the user — every section of [the template](../subphase-template.md), the gate,
and a `readiness` verdict — immediately before it is built.

## The idea

Everything later sub-phases stand on, delivered as something a person can look
at and judge: **a person can open the app in a browser and sign off the look of
every building block a screen will be made from** — the `/kit` catalogue.

That keeps Foundation inside the full-stack rule ([README.md](../README.md#rules)):
the screen is real, it stays, and signing it off is the one decision about the
look that every later screen inherits
([design-system.md](../../architecture/design-system.md)).

## What it would establish

- The containers in [01-overview.md](../../architecture/01-overview.md), up with
  `docker compose up -d`, behind Caddy on one origin.
- The API skeleton: `Shared`, `Shared.Infrastructure`, the error envelope
  middleware, startup ([backend-patterns.md](../../architecture/backend-patterns.md)).
- The database with its migration and procedure containers and the privilege
  model ([04-persistence.md](../../architecture/04-persistence.md)).
- The SPA skeleton, the tokens, the first kit components and templates, the
  lint checks, and the `/kit` route.
- Every test layer with at least one real test, and `run-tests.ps1` reporting
  all five as run; the browser layer's `checkScreen` and `/kit` screenshot.

## Questions to settle when it is defined

- `/kit` is "signed in" in the design-system doc — Foundation has no sign-in
  yet. Is `/kit` open in Foundation and closed when authentication arrives, or
  does authentication come first? (`[OPEN]`)
- The colour palette and the component prefix (`[OPEN]`, design-system.md).
- The API's name and the container layout (`[OPEN]`, 02-backend-structure.md).
- Approval of the packages in design-system.md *Packages*, and the .NET, Node
  and Postgres versions (root `CLAUDE.md` rule 3).
- Multi-tenant or not (`[OPEN]`, 04-persistence.md) — not needed for
  Foundation itself, but cheaper to know before the first table.

## Gate 0 — Foundation

Not written — it is written when this sub-phase is defined, before any code.
