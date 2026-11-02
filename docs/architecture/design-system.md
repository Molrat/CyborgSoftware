# Design System

How every screen gets its look and its behaviour rules **by construction rather
than by instruction**: design tokens, a kit of components, screen templates that
carry the UX requirements, and automatic checks that refuse a screen built any
other way. The behaviour rules themselves are
[../product/UX-REQUIREMENTS.md](../product/UX-REQUIREMENTS.md); this document is
how they and the visual rules are made to hold.

| Section | Status |
|---|---|
| Tokens, the kit, the templates, the checks, the `/kit` catalogue | `[SPEC]` — decided; built with the first screen, so no screen is ever built without it |
| The look, signed off by a person on `/kit` | Not yet |

Markers are defined in [README.md](README.md#status-markers).

## Why

AI-built screens drift. An agent builds a screen by copying the nearest one and
picks values that look right locally; written guidance does not stop that. In
the project this setup was taken from, a survey of ~140 screen files built
without a kit found 18 different font sizes, ~15 different gaps, 146 hand-made
buttons, 8 files with their own primary button, 63 files colouring a status
themselves, and 3 different breakpoints. Colour alone held, because colour was
the one thing a shared stylesheet fixed.

**The principle: the right way is the only easy way, and the wrong way fails a
check.** That is why the kit and its checks arrive *with* the first screen
rather than after the tenth: retrofitting them means an exemption list and a
second look living beside the first.

## Building a screen — the rules

1. **Import from `@/kit` only.** No `<button>`, `<input>`, `<select>`,
   `<textarea>`, `<dialog>` or `<table>` in a screen; no headless-UI import
   outside `src/kit/`; no `style="…"`.
2. **A page is a `PageFrame`; whatever a screen loads goes through
   `AsyncContent`.** Further templates are added when a kind of screen recurs.
3. **Arrange with `Stack` and `Card`.** A screen's own CSS is for layout
   only, and only with tokens — every colour, size, spacing, radius, shadow and
   layer comes from `base.css`.
4. **Status through `StatusPill` or `Notice`** — never a colour set by the
   screen (`UXR-07`).
5. **Every word through the translation layer** (`UXR-05`).
6. **When the kit lacks something, the kit grows**: a new component or variant
   in `src/kit/`, with its Vitest test and its `/kit` entry, the screenshot
   re-recorded, and the change signed off on `/kit`. Never a one-off in a screen.
7. **New UI on an exempt screen goes in a new component** (which is checked), not
   into a file on the exemption list (which is not).
8. **Every browser journey calls `checkScreen(page)`** on each kit-built screen
   it reaches (`tests/browser/support/quality.ts`).

Component names below are unprefixed; the kit gives them one short project
prefix, chosen when it is built, so a kit component is recognisable at a glance
in a template.

## 1. Tokens — `src/styles/base.css`

The single source of every value; Stylelint refuses a raw one anywhere else.

| Kind | Tokens |
|---|---|
| Colour — brand, surface, text, border | `[OPEN]` — the palette is a product decision, made with the first screen |
| Text-safe status colours — at least 4.5:1 on white and on their own tint (`UXR-11`) | success, warning, danger, neutral, info — each a `-text` and a `-bg` token |
| A control's edge, 3:1 on white (WCAG 1.4.11) | `--control-border` |
| Type — inputs and body text never below `md` (`UXR-27`) | `--text-xs` 0.75 · `sm` 0.875 · `md` 1 · `lg` 1.25 · `xl` 1.5 · `2xl` 2 rem |
| Weight, line height | `--weight-regular` 400 · `strong` 600 · `bold` 700; `--leading-tight` 1.25 · `normal` 1.5 |
| Spacing — `--space-2` is the least gap between touch targets (`UXR-29`) | `--space-1` … `-7`: 0.25 · 0.5 · 0.75 · 1 · 1.5 · 2 · 3 rem |
| Touch | `--touch-target` 44px (`UXR-08`) |
| Layers, motion, widths | `--z-sticky` · `overlay` · `popover`; `--duration` 150 ms; `--page-max` 80rem; `--measure` 75ch (`UXR-38`) |
| Breakpoints — `min-width` only, smallest screen first | 40rem (beyond a phone), 64rem (a landscape tablet), 80rem (a desktop with room for an extra column). Touch sizing keys on `(pointer: coarse)`, not on width |

The token names carry the same project prefix as the components. The scales are
a proven starting point; they are confirmed when `/kit` is signed off.

## 2. The kit — `src/kit/`

A top-level folder beside `shared/`; screens import from `@/kit`
(`src/kit/index.ts`). Every component is dumb or layout in the
[frontend-patterns](frontend-patterns.md#component-responsibilities) sense and
takes the words it shows as props; the kit's own fixed wording is the `kit`
locale bucket. Every component with behaviour has a Vitest test beside it; the
purely visual ones are covered by `/kit`'s screenshot and accessibility scan.

The target set — built as the screens need them, not all at once:

| Group | Components | Carries |
|---|---|---|
| Actions | `Button` — `variant` primary · secondary · quiet · danger; `busy`; `icon`, `iconOnly`; `to` makes it a link; **no `disabled`, only `disabledReason`**, shown beside it. `Menu` — secondary actions behind one button | `UXR-13`, `-17`, `-18`, `-24`, `-30`, `-34` |
| Form | `Form` (actions last, primary last; ignores a second submit while busy; `focusFirstError()`), `Field` (the frame: label, hint, error, markers), `TextInput`, `NumberInput` (unit beside, comma or point, shown back as read), `Textarea`, `Select` and `DateInput` (native, for the device's own picker), `Combobox` (type to narrow; `emptyText` required), `Checkbox`, `RadioGroup` | `UXR-13`, `-21`, `-22`, `-25` … `-28`, `-33` |
| Status | `StatusPill` (`label` required, an icon per tone), `Notice` (an error is `role="alert"` and stays), `SaveIndicator` | `UXR-07`, `-14`, `-37` |
| Containers | `Card` (title, count, `attention` tone), `Stack` (column or wrapping row, a spacing step between), `Dialog`, `Confirm`, `Tabs`, `Table` (`caption` and `emptyText` required) | `UXR-12`, `-23`, `-28`, `-33`, `-35` |
| Icons | `Icon` — hand-drawn 24 × 24 paths in `icons.ts`; decorative unless given a `label` | — |

**A headless UI library supplies behaviour only** — focus trapping and return,
Escape, arrow keys, screen-reader roles — to `Dialog`, `Confirm`, `Tabs`, `Menu`
and `Combobox`, and only inside `src/kit/`. A select and a date are native on
purpose: on a touch device the device's own picker beats anything drawn on the
page. The pure decisions (number parsing, async view state, status tone) are
framework-free files with their own tests.

Smart pieces built from the kit that own state are **feature** components, not
kit components.

## 3. Templates

In `src/kit/templates/`, exported through `@/kit` with the components.

| Template | Carries |
|---|---|
| `AsyncContent` | Takes the `AsyncState<T>` every store slice has; **`emptyText` is required** (`vue-tsc` refuses a screen without one). Loading shows after 300 ms with its space kept. The error classes read as [UX-REQUIREMENTS.md](../product/UX-REQUIREMENTS.md#errors-and-recovery) says: 401 *signed out*, with *sign in again* returning to this page (a retry could only fail again); 403 and 404 with the way back to the start; anything else offers the screen's `retry`. **`refused`** — a role-gated page turning the caller away itself ([frontend-patterns](frontend-patterns.md#hiding-is-a-courtesy-never-a-control)) — reads exactly as the 403. Never the server's own message |
| `PageFrame` | A page: the one `h1`, also the browser tab's title; one `primaryAction` slot, after a `secondaryActions` slot; an optional way back |

## 4. The checks

Only these rules — not a general or formatting lint
(`containers/frontend/eslint.config.js`, `stylelint.config.js`).

| Check | Rule | Refuses |
|---|---|---|
| Raw values | Stylelint `color-no-hex`, `color-named`, `function-disallowed-list` (`rgb` … `oklch`), `property-disallowed-list` (`font-family`, `font`), `declaration-property-value-allowed-list` (font size, weight, line height, gap, padding, margin, radius, shadow, z-index → their tokens) — everywhere but `base.css` | Any value not from the tokens |
| Status colour | Stylelint override: the status colour tokens outside `src/kit/` | A screen colouring a status itself |
| Breakpoints | `media-feature-name-allowed-list`, `media-feature-name-value-allowed-list` | A fourth breakpoint, or `max-width` |
| Raw controls | `vue/no-restricted-html-elements` outside `src/kit/` | A hand-made control |
| Inline style | `vue/no-static-inline-styles` (a bound `:style` stays allowed) | Values that dodge Stylelint |
| Bare text | `vue/no-bare-strings-in-template` | A hardcoded string (`UXR-05`) |
| Library containment | `no-restricted-imports` — the headless UI library outside `src/kit/` | A screen bypassing the kit |
| Required parts | `vue-tsc` — `emptyText`, `label`, `caption`, `title` are required props | A screen without its empty state, label or name |
| Accessibility | `@axe-core/playwright` through `checkScreen` — WCAG 2.2 AA, failing on serious and critical | Missing labels, contrast, roles |
| Phone defects | `checkScreen` at phone width: the page laid out no wider than the screen's real width (Playwright's viewport — not `innerWidth`, which a phone browser widens to fit an overflowing page), no control outside it unless in a frame that scrolls on purpose | `UXR-10`'s phone half |
| Visual drift | `toHaveScreenshot` of `/kit`, desktop and phone (`tests/browser/journeys/design-system.spec.ts-snapshots/`) | An unintended change to any kit component |

**Where they run** — four places, so no skipped step lets a violation through:

| When | How | Effect |
|---|---|---|
| Every edit an agent makes | `.claude/hooks/check-edited-file.sh` runs ESLint and Stylelint on the frontend file just written | The violation goes back to the agent before it moves on |
| Every `/verify` | `npm run lint` in `run-tests.ps1`'s frontend layer; `checkScreen` and the screenshot in the browser layer | The whole tree |
| Every deploy | `npm run build` is `vue-tsc --noEmit && npm run lint && vite build` | A tree that breaks a rule does not build; the running stack stays as it was |
| Every commit | `.claude/hooks/check-kit-exemptions.sh` | Asks the user before the exemption list grows or a lint config changes |

Screenshot baselines are per platform; the development machine's pair is the
reference until CI runs the browser layer.

**The ratchet.** `containers/frontend/kit-exemptions.json` lists files the
checks skip. It starts **empty** and should stay that way: it exists for a file
the user decides to exempt, recorded in [../DEBT.md](../DEBT.md). Both lint
configs read it. A file leaves it when it moves onto the kit; the commit guard
asks before it grows.

## 5. People and agents

- **`/kit`** — signed-in, linked from no menu, outside the app bar on purpose.
  Every kit component in every state on fixed sample content. What a person
  signs off **once**, instead of the look of every screen; what the screenshot
  check photographs.
- **`reviewer`** reads this document and `UX-REQUIREMENTS.md` for any diff
  under `containers/frontend/src/`.
- **`/look`** judges a kit-built screen's look against `/kit`.
- **The bar for a new screen** ([../roadmap/README.md](../roadmap/README.md),
  `/define-next`, `/feature-slice`): built from the kit and templates only.
- What no check can see — whether a dashboard shows what to do now, whether a
  list needs search — stays with `reviewer` and the gate (the **review** rows
  of [UX-REQUIREMENTS.md](../product/UX-REQUIREMENTS.md)).

## Packages

The set proven in the project this setup was taken from. **Proposed, not yet
approved for this repository** — confirmed with the user, at exact versions,
when the kit is first built (root `CLAUDE.md` rule 3), and this table then
records the approval.

| Package | In | Shipped to users | For |
|---|---|---|---|
| `reka-ui` | frontend `dependencies` | yes | Dialog, confirm, tabs, menu, combobox behaviour inside the kit |
| `vue-i18n` | frontend `dependencies` | yes | The translation layer (`UXR-05`, `-06`) |
| `eslint` | frontend `devDependencies` | no | The template checks |
| `eslint-plugin-vue` | frontend `devDependencies` | no | `no-restricted-html-elements`, `no-bare-strings-in-template`, `no-static-inline-styles` |
| `vue-eslint-parser` | frontend `devDependencies` | no | Peer of `eslint-plugin-vue` |
| `typescript-eslint` | frontend `devDependencies` | no | Parses `<script setup lang="ts">` |
| `stylelint` | frontend `devDependencies` | no | The value checks |
| `postcss-html` | frontend `devDependencies` | no | Lets Stylelint read `<style>` inside `.vue` |
| `@playwright/test` | `tests/browser` | no | The browser layer |
| `@axe-core/playwright` | `tests/browser` | no | The accessibility scan |

Not proposed: Storybook or Histoire (the catalogue is a route), Tailwind, a
styled component library, an icon package.

| Instead of | Considered | Rejected because |
|---|---|---|
| Own kit on a headless library | A styled library (PrimeVue, Vuetify), themed | Its look leaks through the theme, it is heavy, and a major version can replace its theming wholesale. Reconsider if dense data tables dominate and matching a bespoke design stops mattering |
| Own kit on a headless library | Tailwind (+ shadcn-vue) | Fixes the value scale only — duplicated components survive as class strings |
| A headless library | Hand-written dialog, menu, combobox behaviour | Focus and keyboard handling is where AI-written accessibility bugs concentrate |
| ESLint, Stylelint | A grep script | Cannot parse templates or scope a rule to a folder |

Node: the current LTS, the same version on the development machine and in the
frontend image.
