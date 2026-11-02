# Coding Standards

How code in this repository is written and organised. These rules are binding for
humans and AI agents alike. Architectural *shape* lives in
[architecture/](architecture/); this file is about the craft.

> `CLAUDE.md` and [`.github/copilot-instructions.md`](../.github/copilot-instructions.md)
> point at this file and must stay in sync with it. If a correction introduces a
> new general rule, add it here first, then make sure both agent files still
> point at the right section.

The rules a machine can check are checked —
[`.claude/hooks/check-edited-file.sh`](../.claude/hooks/check-edited-file.sh) at
every edit, the lint in `/verify` and in the deploy build. The rest are for
judgement, and the `reviewer` agent reads this file.

---

## General

- **File size**: keep files under 200 lines (frontend and backend). Split by responsibility rather than trimming.
- **Folder cohesion**: every file in a folder should be a sibling in terms of responsibility. Create subfolders when that breaks down.
- **Class/file cohesion**: if a file does several unrelated things, extract private helpers into a separate class/file.
- **Single Responsibility Principle**: each class, file, and function has one reason to change. If you can't describe a unit's purpose in one sentence, split it.
- **Composition over inheritance.** Prefer composing small pieces over deep / clever inheritance hierarchies. Use inheritance only where it genuinely models an "is-a" relationship.
- **Open/Closed Principle**: a unit should be open for extension but closed for modification. Add behaviour by plugging in new implementations (new strategy, new handler, new subclass), not by editing existing, working code. If a change forces you to reopen a stable class to bolt on a `switch`/`if` branch, reach for an abstraction instead.
- **Interface Segregation Principle**: keep interfaces small and client-focused. No consumer should depend on members it doesn't use. Prefer several narrow, role-based interfaces over one broad "kitchen-sink" contract, and split an interface when different callers only ever touch disjoint subsets of it.
- **Follow existing architecture.** If the task doesn't fit cleanly, **ask** before inventing a new pattern.
- **Architectural decisions** (new container, new cross-cutting pattern, new dependency) are discussed first, not implemented silently.
- **External libraries & software** (NuGet/npm packages, services, SDKs, CLI tools) are always discussed with the user before being added or wired in. Propose it, explain why it's needed and what alternatives you considered, and wait for approval before installing. Record the approval — package, exact version, what it is for, what was rejected — in the architecture doc for the area.
- **After changes**: update [architecture/](architecture/), add/update tests, update relevant docs.
- **Work carefully**: clean, structured, scalable. No half-finished implementations. No hacky solutions. No `TODO`, commented-out code, or stub left behind at a gate.

---

## Naming

Names are the cheapest documentation in the codebase. Spend on them.

- **Say what it is, not what it technically is.** `PublishedPriceLookup`, not `PriceHelper2`. Avoid `Manager`, `Util`, `Helper`, `Data2`, `Common` as the *whole* name — they describe a shape, not a responsibility.
- **No abbreviations** except ones already universal in the domain (`Id`, `Url`, `Db`, `Api`, `Sql`). `structureVersion`, not `structVer`.
- **A name that lies is worse than a vague one.** When a column, field, or type stops meaning what it says, rename it in the same change that broke the meaning — migration, stored functions and C# together.
- **Booleans read as assertions**: `isPublished`, `hasDraft`, `canEdit` — never `published` alone or `flag`.
- **Symmetry**: if one side is `Create`, the other is `Delete`, not `Remove`. Pick a verb set and hold it across the codebase.

## Comments

- Comment **why**, not **what**. The code already says what.
- The comments worth writing are the ones that record a decision, a constraint, or a trap: why a header must be forwarded verbatim, why a resolver order is forced, why an exception is swallowed.
- Delete comments that have gone stale rather than leaving them to mislead. A wrong comment costs more than no comment.
- XML doc comments (`/// <summary>`) on public interfaces and any non-obvious public method. Not on self-evident members.

## Errors

- **No `try`/`catch` clutter in business code.** Let exceptions bubble to the middleware.
- Business code throws typed `ApplicationError` subclasses (`ValidationError`, `NotFoundError`, `ForbiddenError`, `ConflictError`, and feature-specific ones). A single exception-handling middleware maps them to the standard error envelope ([backend-patterns.md](architecture/backend-patterns.md#error-handling)).
- Never `return BadRequest(new { message = "..." })` from a controller. That bypasses the envelope the frontend parses.
- **A swallowed exception must be justified in a comment**, and must log. The sanctioned shape: a side effect that must not fail the main action — e.g. sending a confirmation email after the record it confirms is already durably saved.

---

## Backend (C# / .NET)

- **C# 12 primary constructors for DI.** `public sealed class FooService(IBar bar) : IFooService` — reference the parameter as `bar`, no `_bar` field. When the constructor needs to compute a value, keep the primary constructor and use a field initializer: `private readonly TimeSpan _ttl = TimeSpan.FromHours(config.GetValue<int?>("Key") ?? 1);`. The underscore prefix applies to explicit fields, never to primary-constructor parameters.
- **`sealed` by default.** Unseal only when something actually derives.
- **Nullable reference types are on and `TreatWarningsAsErrors` is on.** Don't suppress; fix. `WarningsNotAsErrors` is reserved for documentation warnings (`CS1591`) and known-noisy analyzer ids, and each entry needs a comment.
- **Records for values, classes for behaviour.** `sealed record` for a value; a class when it owns operations.
- **`CancellationToken ct` is the last parameter** of every async method that does I/O, and it is always passed through.
- **Dapper, no ORM.** SQL lives in stored functions; the repository calls them by name and maps the result. No SQL string-building in services or controllers.
- **Domain projects stay pure**: no database, HTTP, EF Core, file access, queues, external APIs, logging, SMTP, configuration, or JSON types, and no reference to a project that brings them in. If a domain class needs a clock or a token generator, it takes it as a parameter.
- **The business logic never adapts to the edges; the edges adapt to it** — request/response classes in `Controllers`, row classes in `Data`, closed sets as `enum`s, JSON only at the edges: [backend-patterns.md](architecture/backend-patterns.md#who-adapts-to-whom).
- **Culture and time zones are explicit.** An ASP.NET image on Alpine runs with invariant globalization — no ICU, no time-zone database — so a named culture (`CultureInfo.GetCultureInfo("nl-NL")`) or an IANA zone lookup throws there and nowhere on a developer's Windows machine. Set `InvariantGlobalization` in the test projects too, so it fails in tests, and decide deliberately which "today" the business means.

## Frontend (TypeScript / Vue)

- **`<script setup lang="ts">`** for every component. No Options API.
- **A component does exactly one of**: layout (arrange children), smart (touch a store), or dumb (props in, events out). Never two.
- **State flows down, changes flow up.** Avoid two smart components on one leaf-to-root path.
- **Extract non-Vue logic into pure TypeScript.** API clients, mappers, validators, parsers, business rules, and transport adapters live as plain `.ts` so they're testable without mounting anything ([frontend-patterns.md](architecture/frontend-patterns.md#state-management--the-core)).
- **Asynchronous state is state.** Every async slice in a store exposes `{ data, isLoading, error }`. Consistent shape, no ad-hoc `loadingUsers` / `usersError` pairs.
- **No `any`.** `unknown` plus a narrowing check where a type genuinely isn't known.
- **Screens are built from the design system's kit** — `import { … } from '@/kit'`, never a raw `<button>`, `<input>`, `<select>`, `<textarea>`, `<dialog>` or `<table>`, never the headless UI library outside `src/kit/`. A page is a `PageFrame`, loaded data goes through `AsyncContent`. When the kit lacks something, the kit grows. Rules and reasons: [architecture/design-system.md](architecture/design-system.md#building-a-screen--the-rules); refused by ESLint and Stylelint at every edit, in `/verify` and in the deploy build.
- **Scoped styles, tokens only**: every colour, font size, weight, spacing, radius, shadow and layer is a custom property from `src/styles/base.css`; a screen's own CSS is for layout. No utility-class framework.
- **No user-facing string is hardcoded** — every word goes through the translation layer ([UX-REQUIREMENTS.md](product/UX-REQUIREMENTS.md#language)).

## SQL

- **One stored function per file**, named `sp_<table>_<verb>`, in `db-procedures/procedures/<table>/`. Parameters `p_`, locals `v_`.
- **Schema changes are versioned migrations** (`V###__description.sql`), append-only. Never edit an applied migration — add the next one. A hook refuses the edit.
- **Every function ends with its `GRANT EXECUTE ... TO ${APP_USER}`.** The app user has execute rights and no DDL rights.
- **Explicit column lists.** No `SELECT *` in a function that returns a table.
- **A changed function signature drops the old one** in the same file. Full conventions: [architecture/04-persistence.md](architecture/04-persistence.md).
