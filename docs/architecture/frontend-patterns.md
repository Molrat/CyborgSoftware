# Frontend Patterns

The rules every screen and feature in the SPA follows: what each top-level
folder is for, what a component may do, where logic lives, and how text,
errors and permissions are handled. They do not change when a screen is added.
**What the SPA actually contains** — the screens, the routes — is
[03-frontend-structure.md](03-frontend-structure.md).

| Section | Status |
|---|---|
| Folders, component responsibilities, the state layer, the API layer, text, hiding is a courtesy | `[SPEC]` — the rules are decided; no SPA exists yet |

Markers are defined in [README.md](README.md#status-markers).

## Folders

Top-level folders inside `src/` are **siblings** — not nested:

| Folder | Holds |
|---|---|
| `pages/<page>/` | Route-level views, one per router entry. Pages compose features. |
| `features/<feature>/` | Self-contained feature components (smart + dumb + layout), droppable into any page. **Not** nested under pages. |
| `kit/` | The design system: the visual building blocks and screen templates every screen is built from, imported as `@/kit` ([design-system.md](design-system.md)). Dumb or layout only. |
| `shared/` | App-specific pieces reused across features that are not visual building blocks. |
| `stores/` | Pinia stores, one per durable concern. |
| `core/` | The screen-independent decisions — pure TS, no Vue, no Pinia. |
| `api/` | Pure-TS API client + per-resource request modules. |
| `types/` | Frontend mirrors of backend contracts. |
| `router/` | The route table and its guard. |
| `styles/` | Global tokens and baseline only — the one place a raw value is written. |

A feature is not owned by a page. It is a standalone unit that a page composes.

## Component responsibilities

A component does exactly **one** of these, never two:

1. **Layout** — arrangement of children.
2. **Smart** — connects to state (reads stores, dispatches actions).
3. **Dumb** — props in, events out, no state coupling.

**State flows down. Changes flow up.** Avoid two smart components on a single
leaf-to-root path — that is how you get two sources of truth for one screen. A
page that is one screen keeps one smart component.

A smart component connects to state; it does not *hold* any. Everything it knows
about the domain it asked a store for. See
[State management](#state-management--the-core) for where the line sits.

## Framework-agnostic logic

Extract anything that does not need Vue or Pinia into pure TypeScript: API
clients, mappers, validators, parsers, business rules, transport adapters. They
become testable without mounting anything.

Pinia stores stay — they are the reactive face of the state layer. The goal is
not to remove the store, it is to keep every *decision* the store calls into in
plain TS, where no framework can reach it.

## State management — the core

**The state layer is the application. The UI is a way to look at it.**

Not a metaphor: a complete, working frontend should exist below the components,
driven entirely by calling actions and reading state, and be tested that way.
Components render it. They do not extend it.

Three layers, and the middle one is thin on purpose:

| Layer | Holds | Framework |
|---|---|---|
| **The brain** — `core/`, `api/`, `types/` | What an action means, what is valid, what the state becomes, what the server is asked | none — not one file imports Vue |
| **The adapter** — `stores/` | Reactive state and the actions that mutate it, delegating every decision downward | Pinia, necessarily |
| **The UI** — `pages/`, `features/`, `shared/` | Interaction: what is on screen, what is focused, what the user is part-way through typing | Vue |

The portability is not in the adapter; it is in the brain, which has no
framework in it at all. A second UI reuses the brain whole and writes its own
thin adapter.

### The boundary of logic

One test, applied to any piece of logic:

> **Would it still be true with a completely different screen on top?**

Which items a list shows, when a local change may be trusted before the server
confirms it, what counts as a valid value, what an action does to state — **all
still true. All belong below the store line**, whatever folder they are in.

What is on screen, what is focused, which dialog is open, what the user is
part-way through typing, where a submit navigates to — **gone the moment the
screen closes. All belong in the component.**

A smart component's whole job is to call actions and render what comes back. A
composable may *compose* store actions and hold screen-local state; the moment it
decides something about the domain, that decision is in the wrong layer —
regardless of how many lines the file is, and a 200-line limit is never a reason
to move a decision upward.

The shape to copy: a page with no composable, a store, and every decision in a
Vue-free file under `core/`.

**`isLoading`, `error`, and status flags are state, not UI.** Every async slice
follows one shape:

```ts
interface AsyncState<T> {
  data: T | null;
  isLoading: boolean;
  error: ApiError | null;
}
```

Consistency here is what lets a generic loading/error template
(`AsyncContent`, [design-system.md](design-system.md#3-templates)) exist at all.

## The API layer

- **`api/client.ts` is the only `fetch`.** Each `api/<resource>Api.ts` is a thin
  set of calls over it, throwing `ApiError` (the backend's one error envelope,
  [backend-patterns.md](backend-patterns.md#error-handling)) on any non-2xx.
  A `404` that means "nothing saved yet" may come back as `null`, said so in
  that module's doc comment.
- **`put` takes headers**, so an edit can send `If-Match`
  ([backend-patterns.md](backend-patterns.md#optimistic-concurrency-on-rest-edits)).
- **`types/` mirrors the backend's contracts**, one file per area. Content the
  product gives no structure is typed `unknown` and rendered raw — never
  modelled on the client ahead of a product decision.

## Routing

- **Mark every protected route `meta.requiresAuth`.** The guard checks it, and
  only on routes that carry the flag. Without it the page loads signed-out and
  fails somewhere further in, which looks like a different bug.
- View state a person would expect to survive a reload or a shared link — the
  open tab, filters, search terms, the selected item — lives in the URL
  ([UX-REQUIREMENTS.md](../product/UX-REQUIREMENTS.md)).

## Text and translation

No user-facing string is hardcoded — see
[../product/UX-REQUIREMENTS.md](../product/UX-REQUIREMENTS.md#language).
Translation belongs in components and stores; pure TypeScript returns codes and
stays translation-free. Messages are **feature-scoped**, not central:
`features/<feature>/locales/<lang>.ts` sits with the components that use it, so
a feature carries its own strings in and out.

## Hiding is a courtesy, never a control

The frontend hides actions the user may not perform so screens stay calm, and
every one of them is independently refused by the server. Consequences for how
components are written:

- A hidden button whose endpoint would have allowed the call is a UI bug, not a
  security hole. A *shown* button whose endpoint refuses is the same kind of bug
  in the other direction — nothing is shown disabled without a reason attached.
- **Never gate on roles for anything the user's data depends on.** Per-record
  access is resolved server-side; the SPA cannot compute it, and a client-side
  approximation would drift from the server's rules the moment either changes.
- **A role-gated page guards itself**, not only its link: a direct URL visit
  reaches the route whether or not the link was shown, so the page renders its
  own "not allowed" message for a caller it refuses.

A 403 renders as a screen-level message with a way back, never a blank page.

## Tests

Tests sit next to their source (`auth.test.ts` beside `auth.ts`), not in a
mirror tree. They never reach `dist/` — the Vite build only emits what is
reachable from `main.ts` / `index.html`. Layer rules: [../TESTING.md](../TESTING.md) ④.
