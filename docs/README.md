# Documentation

Seven sections. Three are folders, four are single files.

| Section | What it is | State |
|---|---|---|
| [product/](product/) | What we are building and why — product description, workflows, acceptance scenarios, UX requirements, open questions | **not yet described** — the UX baseline is written; the product is not |
| [architecture/](architecture/) | How it is built — the target system, with every section marked `[BUILT]` / `[PARTIAL]` / `[SPEC]` | patterns written; nothing built |
| [roadmap/](roadmap/) | Sub-phases with manual test gates between them | no sub-phase defined |
| [CODING-STANDARDS.md](CODING-STANDARDS.md) | How code is written and organised | written |
| [TESTING.md](TESTING.md) | The automated testing system | designed; no tests yet |
| [CI-CD.md](CI-CD.md) | Build, test, and deployment pipeline | principles written; nothing built |
| [DEBT.md](DEBT.md) | What is built wrong | empty |

## How they relate

```
   product/  ─────────>  what to build
     │
     ├──> architecture/  ──>  how it is structured
     │         │
     │         └──>  CODING-STANDARDS.md  ──>  how it is written
     │
     ├──> roadmap/  ──>  in what order, with what human checks
     │
     └──> TESTING.md  ──>  how we know it still works
               │
               └──>  CI-CD.md  ──>  how that gets enforced and shipped
```

`product/` is the source. Everything else serves it. What remains undecided is
marked `[OPEN]` in place — `grep -rn "\[OPEN\]" docs/product` lists every one —
or recorded in [product/OPEN-QUESTIONS.md](product/OPEN-QUESTIONS.md).

## Start here

- **New to the codebase**: [architecture/01-overview.md](architecture/01-overview.md)
- **About to write code**: [CODING-STANDARDS.md](CODING-STANDARDS.md)
- **About to add a feature**: [architecture/backend-patterns.md](architecture/backend-patterns.md) · `/feature-slice`
- **Wondering what is undecided**: [product/OPEN-QUESTIONS.md](product/OPEN-QUESTIONS.md)
- **Wondering what already exists**: [architecture/README.md](architecture/README.md#where-the-system-stands)

## Conventions

Every document states its own status at the top when it describes something not
yet real. A document that describes an intention as though it were a fact is
worse than no document, because it costs a debugging session to discover.

In [architecture/](architecture/) this is formalised: documents describe the
**target** system, and each section carries `[BUILT]`, `[PARTIAL]`, or `[SPEC]`.
See [architecture/README.md](architecture/README.md#status-markers).

**State is written in one place.** A status recorded twice will eventually
disagree with itself — so a sub-phase's state lives only in its own file, the
roadmap table is generated from those files, and test counts live in one
machine-checked line in TESTING.md.
