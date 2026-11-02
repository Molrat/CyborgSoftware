---
name: spec-check
description: Resolve whether a concern is [BUILT], [PARTIAL] or [SPEC] in this repo, checking the docs against the actual code. Use BEFORE writing code that builds on an existing feature, table, screen, role, or cross-cutting mechanism — and whenever an architecture doc might be describing the target system rather than what exists.
user-invocable: true
---

# /spec-check — is this real, or is it spec?

`docs/architecture/` describes the **target** system. Every section carries
`[BUILT]`, `[PARTIAL]` or `[SPEC]`. Writing code against a `[SPEC]` section as
though it exists is the most expensive mistake available in this repo: it
compiles, it reviews clean, and it is wrong in a way nothing detects.

This skill answers one question — *does the thing I am about to build on
actually exist today?* — in about a minute.

## Procedure

**1. Read the summary table first.**
[docs/architecture/README.md](../../../docs/architecture/README.md#where-the-system-stands)
— *Where the system stands*. It is the single roll-up of what exists.

**2. Read the marker on the specific section**, in the doc that owns the
concern (`01` overview, `02` backend, `03` frontend, `04` persistence, the
`*-patterns.md` files, `design-system.md`). A section marker is narrower and
wins over the summary table.

**3. Do not stop at the docs — confirm against the tree.** Docs drift: a
feature ships while the doc still describes the system without it. Cheap
confirmations:

| Concern | Confirm with |
|---|---|
| A backend feature | `ls containers/*/api/src/` |
| A table or column | `grep -rn "<table>" containers/*/db-migrations/migrations/` |
| A stored function | `ls containers/*/db-procedures/procedures/<table>/` |
| Isolation on a table | does its `sp_*` take the isolation parameter (`p_tenant_id`, if any) first? |
| A frontend area | `ls containers/frontend/src/` |
| A kit component | `ls containers/frontend/src/kit/` |
| A role check | `grep -rn "Roles\." containers/*/api/src/` |

**4. If the doc and the tree disagree, the tree is the truth** — and the doc is a
bug. Say so, and fix it as part of whatever work follows (root CLAUDE.md rule 4).

## Report like this

> **`orders` — `[PARTIAL]`.** The table (`V003`), its four `sp_order_*`
> functions and the full feature slice exist. Nothing *consumes* its status for
> invoicing yet, because invoicing does not exist. Safe to read and write
> orders; not safe to assume an order's status gates anything.

Name what is safe to build on and what is not. A bare `[PARTIAL]` helps nobody.

## When the answer is `[SPEC]`

Stop before writing. Then either:

- **State the assumption explicitly** and continue, if the work is still useful
  under it — e.g. "writing this repository as though the function filters on
  the owner, which it does not yet; the function must be changed first."
- **Ask**, if proceeding either way would produce throwaway code.

Never quietly build the missing substrate as a side effect of another task. That
is how a `[SPEC]` decision gets made by accident.
