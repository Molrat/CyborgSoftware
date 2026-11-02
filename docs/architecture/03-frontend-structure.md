# Frontend Structure

**What the SPA contains** — its screens, routes and areas. The rules are in
[frontend-patterns.md](frontend-patterns.md) and
[design-system.md](design-system.md); this file is the inventory, and it is
updated by the change that alters what it lists (root `CLAUDE.md` rule 4,
`/feature-slice` step 7).

| Section | Status |
|---|---|
| Everything below | `[SPEC]` — no SPA exists yet |

Markers are defined in [README.md](README.md#status-markers).

## Layout `[SPEC]`

`containers/frontend/` — a Vite project. `src/` holds the folders in
[frontend-patterns.md](frontend-patterns.md#folders); `kit-exemptions.json`,
`eslint.config.js` and `stylelint.config.js` sit at its root
([design-system.md](design-system.md#4-the-checks)).

## Screens

| Route | Screen | Roles | Status | Built in |
|---|---|---|---|---|
| `/kit` | The design-system catalogue — every kit component in every state | signed in | `[SPEC]` | — |

## Development loop

| Command | In | Does |
|---|---|---|
| `npm run dev` | `containers/frontend` | Vite dev server |
| `npm test` | `containers/frontend` | Vitest |
| `npm run lint` | `containers/frontend` | The design-system checks |
| `npm run build` | `containers/frontend` | `vue-tsc --noEmit && npm run lint && vite build` — what the deploy runs |
