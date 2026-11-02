# CyborgSoftware — Development Rules

This file is a **router**, not a rulebook. The rules themselves live in
[docs/](docs/). This says which document answers which question, and states the
few rules that bind every task regardless of which file is open.

> [.github/copilot-instructions.md](.github/copilot-instructions.md) is a pointer
> to this file, not a duplicate. Rules that apply to one area only live in a
> `CLAUDE.md` beside that area — see *Scoped rules* at the bottom. If a
> correction introduces a general rule, it goes in
> [docs/CODING-STANDARDS.md](docs/CODING-STANDARDS.md), which is the single
> source for how code is written.

## Where things are documented

| Need | Read |
|---|---|
| How code must be written | [docs/CODING-STANDARDS.md](docs/CODING-STANDARDS.md) |
| System shape, containers, routing | [docs/architecture/01-overview.md](docs/architecture/01-overview.md) |
| How a backend feature is built — layers, dependency direction, between features | [docs/architecture/backend-patterns.md](docs/architecture/backend-patterns.md) |
| What the API contains — features, `Shared`, exceptions | [docs/architecture/02-backend-structure.md](docs/architecture/02-backend-structure.md) |
| How a frontend screen is built — folders, component roles, the state layer | [docs/architecture/frontend-patterns.md](docs/architecture/frontend-patterns.md) |
| **How a screen looks and behaves** — the kit every screen is built from, its checks | [docs/architecture/design-system.md](docs/architecture/design-system.md) · [docs/product/UX-REQUIREMENTS.md](docs/product/UX-REQUIREMENTS.md) |
| What the SPA contains — screens, areas | [docs/architecture/03-frontend-structure.md](docs/architecture/03-frontend-structure.md) |
| Schema, migrations, stored procs | [docs/architecture/04-persistence.md](docs/architecture/04-persistence.md) |
| The testing system | [docs/TESTING.md](docs/TESTING.md) |
| Seeing a change in a real browser | `/look` · [docs/TESTING.md](docs/TESTING.md#looking-at-the-app-in-a-browser--not-a-test-layer) |
| Build, test, and deploy pipeline | [docs/CI-CD.md](docs/CI-CD.md) |
| What to build, in what order | [docs/product/](docs/product/) · [docs/roadmap/](docs/roadmap/) |
| **What is still undecided** | [docs/product/OPEN-QUESTIONS.md](docs/product/OPEN-QUESTIONS.md) |
| **What is built wrong** | [docs/DEBT.md](docs/DEBT.md) |
| **What already exists** | [docs/architecture/README.md](docs/architecture/README.md#where-the-system-stands) |

---

## The rules that bind everywhere

### 1. The product is not fully specified

Do not invent product behaviour to fill a gap. If a task needs a decision that is
not written down, add it to
[docs/product/OPEN-QUESTIONS.md](docs/product/OPEN-QUESTIONS.md) and **ask**.
`[OPEN]` markers in [docs/product/](docs/product/) list what is known to be
undecided (`grep -rn "\[OPEN\]" docs/product`); a plausible guess against one of
them produces code that looks right, reviews clean, and encodes a decision
nobody made.

### 2. The architecture docs describe the target system, not the build

Every section in [docs/architecture/](docs/architecture/) carries `[BUILT]`,
`[PARTIAL]`, or `[SPEC]`. **Check the marker before implementing against a
section.** Building on a `[SPEC]` substrate as though it exists is the most
expensive mistake available here, because it fails silently rather than at
compile time. **`/spec-check` resolves this in a minute**, and checks the docs
against the tree rather than trusting either alone.

### 3. Architectural decisions and dependencies are discussed first

A new container, a new cross-cutting pattern, a new NuGet or npm package, a new
service — proposed with alternatives and approved before it is wired in, never
added silently. Full rule in
[docs/CODING-STANDARDS.md](docs/CODING-STANDARDS.md).

### 4. A change is not finished until the docs say what it decided

Update [docs/architecture/](docs/architecture/) — including the status markers
and the *Where the system stands* table — in the same change that makes them
untrue, and add or update the tests. This is not documentation hygiene: it is the
only thing carrying a decision from one piece of work to the next, because the
next piece of work starts with none of this conversation's context.
`/feature-slice` ends with these steps for this reason, and a commit hook asks
about it.

### 5. Questions to the user are asked in plain English, purpose first

The user is not up to speed with the code, does not use engineering jargon, and
holds limited domain knowledge. **Every question, option, explanation and gate
instruction addressed to them opens by saying what kind of question it is** — a
sub-phase to clarify, an architectural decision, a product rule nobody has
decided, a gate to walk, a problem to report — and is then written so they can
actually answer it.

This is a second register, deliberately. The documents in [docs/](docs/) stay
dense and precise; only the channel that talks *to the user* changes. An option
described without its consequence, or a choice handed over without a
recommendation, fails this rule even if every word in it is simple.

Full format, and the gate-walk protocol:
[.claude/skills/talk-to-human/SKILL.md](.claude/skills/talk-to-human/SKILL.md).

---

## Skills

Repeatable procedures live in [.claude/skills/](.claude/skills/). Invoke one by
typing `/<name>`; they also apply themselves when the task matches.

| Skill | Use it when |
|---|---|
| `/continue` | **The entry point.** Resume the roadmap — walk a gate, resume a build, start a `READY` sub-phase, or define the next |
| `/spec-check` | Before building on anything that might be `[SPEC]` — rule 2 above |
| `/verify` | Running the tests; a **skipped** layer is not a passing layer |
| `/look` | Seeing a screen in the running app, in a real browser — after building one, and before any gate reaches a person |
| `/feature-slice` | Adding a feature to the API, front to back |
| `/gate` | Writing a phase gate (before the code) or walking one |
| `/define-next` | Defining the next sub-phase — one whole full-stack feature, just before building it |
| `/talk-to-human` | Asking the user anything — rule 5 above |

## Agents

Three cold agents live in [.claude/agents/](.claude/agents/). **Dispatch
`reviewer` and `tester` at the end of a slice and before a phase gate, and
`readiness` before a sub-phase is declared ready to build** — they are the
fourth control alongside the docs, the tests and the gate.

| Agent | Does |
|---|---|
| `reviewer` | Reads the diff against the architecture doc for the area it touches, and reports divergences. Read-only. |
| `tester` | Works from `ACCEPTANCE.md` and the gate to write cases that try to break the slice. |
| `readiness` | Judges whether a sub-phase definition is complete enough to hand to an implementer. `READY`, or what is missing. Read-only. |

They start cold, and that is deliberate: an agent that was not in the
conversation cannot rationalise a decision it did not make — which is exactly
why `readiness` must not be the same thing that wrote the definition. All three
follow one rule — **read the spec, not the code.** A verifier that reads the
implementation first ends up ratifying it, which is worse than no verifier
because it makes the gap look covered.

They verify; they do not decide. A gate is still a person walking the table.

## Hooks

[.claude/settings.json](.claude/settings.json) wires the checks in
[.claude/hooks/](.claude/hooks/). Each one no-ops until the area it watches
exists.

| Hook | When | Does |
|---|---|---|
| `block-applied-migration.sh` | Before an edit | Refuses an edit to an applied `V###__*.sql` |
| `check-edited-file.sh` | After an edit | The machine-checkable coding standards, and the design-system lint on frontend files |
| `frontend-related-tests.sh` | After an edit | Runs the Vitest tests related to the frontend file just written |
| `check-doc-handoff.sh` | `git commit` | Asks when a new feature area lands with no `docs/architecture/` change (rule 4) |
| `check-testing-inventory.sh` | `git commit` | Asks when `docs/TESTING.md`'s counts no longer match the tree |
| `check-browser-journey.sh` | `git commit` | Asks when a new screen lands with no browser journey change |
| `check-kit-exemptions.sh` | `git commit` | Asks when the design-system exemption list grows or a lint config changes |

---

## Scoped rules

Area-specific rules live next to the area and load when it is opened. Nothing
below repeats what a doc already says. Add a row — and the `CLAUDE.md` it points
at — when the area is created; a scoped file holds only *what bites here*, never
a copy of a doc.

| Working in | Also read |
|---|---|
| *(none yet)* | |
