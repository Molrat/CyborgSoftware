# UX Requirements

The non-negotiable behavioural properties of every screen, written so each can be
verified rather than admired. These are the requirements that get quietly
dropped under delivery pressure, which is why each one names how it is checked.

They are design standards, not product behaviour — Nielsen's usability
heuristics, WCAG 2.2 level AA, and the established guidance on forms, touch and
feedback. Where one meets a product question (what may be undone, which list
needs paging), the product question is still asked, per root `CLAUDE.md` rule 1.
The design system ([../architecture/design-system.md](../architecture/design-system.md))
carries most of them: a screen built from the kit gets a **kit** row for free,
and a **lint** row cannot be broken without the build failing.

> **The decision rule**
> If a normal action can be done in fewer clicks without losing safety,
> traceability, or correctness, choose the shorter route.

That rule settles most UX arguments before they start. A wizard and a wide menu
are both longer routes wearing a helpful face.

## Verification

| Method | Meaning |
|---|---|
| **e2e** | Asserted in `tests/e2e/`. |
| **component** | Asserted in a backend component test or a Vitest component test. |
| **review** | Checked by a person at the roadmap gate, and by the `reviewer` agent. Structural properties a test cannot see. |
| **kit** | Built into a component or template of the design system: a screen built from the kit cannot leave it out. |
| **lint** | Refused by the design system's ESLint or Stylelint rules — at every edit, in `/verify`, and in the deploy build. |
| **browser** | Asserted on every screen a browser journey reaches (`tests/browser/support/quality.ts`): axe, and the phone check. |

---

## The route

| ID | Requirement | Verified |
|---|---|---|
| `UXR-01` | A person's start screen shows primarily **what they must do now** — not a summary of everything that exists. | review |
| `UXR-02` | One primary action per screen or card, wherever practical. | review · kit |
| `UXR-03` | From any incomplete or invalid item, the person can reach the place it is fixed in one action. A warning the person cannot act on is a defect. | component |

## Saving and data safety

| ID | Requirement | Verified |
|---|---|---|
| `UXR-04` | Nothing a person typed is lost silently. Leaving with unsaved changes warns; a session that expires mid-task re-authenticates in place and returns to the same screen with the input intact; a refused save keeps what was typed. | component |

## Language

| ID | Requirement | Verified |
|---|---|---|
| `UXR-05` | **No user-facing string is hardcoded.** Every label, message, and empty state is a translation key from the first screen written. Adding a language is a translation file, not a code change. | component · lint |
| `UXR-06` | Dates, times, numbers, and units are formatted per locale, not per hardcoded pattern. | component |

> `[OPEN]` Which language the product ships in first, and which follow.

How translation is used:

| Rule |
|---|
| Locale files are **data**, one per language, loaded lazily. |
| Keys are namespaced by feature, mirroring `features/` — not one flat catalogue. |
| Translation lives in components and stores only. **Pure TypeScript stays translation-free**: validators and mappers return codes, and the layer that renders them resolves the text. |
| The chosen locale is per user and survives sign-out on that device. |

## Errors and recovery

Every error class, what the person sees, and what they can do about it. The
backend maps typed errors to one envelope
([../architecture/backend-patterns.md](../architecture/backend-patterns.md#error-handling));
this table says what the frontend does with it. `AsyncContent` carries the
screen-level rows ([design-system.md](../architecture/design-system.md#3-templates)).

| Class | Surface | Recovery |
|---|---|---|
| Validation | Inline, at the field | Correct it; focus goes to the first field in error |
| Not allowed (403) | A screen-level message, never a blank page | Back to the start |
| Not found, or not yours (404) | The same message for both — existence is not disclosed | Back to the start |
| Conflict (409, optimistic concurrency) | A message naming what changed | Load the newest version; what was typed is kept until the person discards it — never a silent overwrite |
| Network unavailable | A persistent, non-blocking indicator | Retry; nothing typed is lost |
| Signed out (401) | Re-authentication | Return to the same screen with input intact (`UXR-04`) |
| Anything else | The screen's own error, in words | Retry |

## Empty and first-run states

An empty state is a designed screen, not an absent one. It says what would be
here, and offers the action that puts something there. "Nothing to do" is
stated as a calm, positive state, not an error. `AsyncContent` refuses a screen
without one (`emptyText` is required).

## Accessibility and consistency

| ID | Requirement | Verified |
|---|---|---|
| `UXR-07` | **Status is never communicated by colour alone.** Every status carries text or shape as well. | component · kit · lint |
| `UXR-08` | Touch targets are at least 44 × 44 px on a touch device. | review · kit · lint |
| `UXR-09` | The same concept looks and reads the same everywhere: one status pill, one notice, one table. Consistency is a requirement, not a style preference. | review · kit · lint |

## Responsiveness

| ID | Requirement | Verified |
|---|---|---|
| `UXR-10` | Layouts are designed for the devices the product is used on, not one layout that stretches. On a phone a screen may be less convenient, but no screen shows a **visual defect** on one: nothing off-screen or cut off, no sideways scroll, nothing overlapping, every control reachable and tappable. | review · browser (the phone half) |

> `[OPEN]` **The primary device** for each kind of user (desktop, tablet, phone)
> — it decides which layout is designed first.

> `[OPEN]` **Latency thresholds.** "Fast" needs numbers before it can be tested:
> time to interactive on the start screen, and to save a record. Without them
> responsiveness can only be reviewed, never asserted.

---

## Professional baseline

### Accessibility — WCAG 2.2 AA

| ID | Requirement | Source | Verified |
|---|---|---|---|
| `UXR-11` | **WCAG 2.2 level AA is the floor for every screen.** Text contrast at least 4.5:1 (3:1 for large text, icons, and the edges of controls). | WCAG 2.2 AA | browser · kit |
| `UXR-12` | Everything works by keyboard alone, in a logical order, with a visible focus indicator. Focus is trapped only in an open dialog, which Escape closes and which hands focus back to what opened it. | WCAG 2.1.1, 2.4.3, 2.4.7 | kit · browser |
| `UXR-13` | Every control has a visible label tied to it; an icon-only control has an accessible name. | WCAG 1.3.1, 4.1.2 | kit · lint · browser |
| `UXR-14` | A status change the person did not cause — saved, failed — is announced to assistive technology, not only drawn. Errors at once; the rest politely. | WCAG 4.1.3 | kit |
| `UXR-15` | Motion is short and functional, and switched off for a person who asks their system to reduce motion. | WCAG 2.3.3 | kit · review |
| `UXR-16` | Text enlarged to 200 % (browser zoom) loses nothing: no content cut off or overlapping. | WCAG 1.4.4, 1.4.10 | review |

### Feedback — Nielsen 1, "visibility of system status"

| ID | Requirement | Source | Verified |
|---|---|---|---|
| `UXR-17` | Every action answers within 0.1 s — pressed, busy. Work that takes longer than about a second shows progress. A loading indicator appears only after 300 ms, so a fast answer does not flicker. | Nielsen; response-time limits | kit |
| `UXR-18` | An action in progress cannot be triggered twice: its button is busy and does nothing until the action finishes. | — | kit · component |
| `UXR-19` | An action whose result is not visible where the person is looking is confirmed in words — *Invitation sent*. | Nielsen 1 | review |
| `UXR-20` | The layout stays still while content loads: space is kept for it, so nothing the person is about to tap moves away. | Core Web Vitals (CLS) | kit · review |

### Errors and irreversible actions — Nielsen 5 and 9

| ID | Requirement | Source | Verified |
|---|---|---|---|
| `UXR-21` | An error message says what happened and what to do next, in plain language, next to where it happened — never a code, a stack trace or the server's own message. What the person typed is kept. | Nielsen 9; WCAG 3.3.1, 3.3.3 | kit · review |
| `UXR-22` | A field is checked when the person leaves it or submits — never on every keystroke while they are still typing. After a refused submit, focus is on the first field in error. | Form-design guidance; WCAG 3.3.1 | kit · component |
| `UXR-23` | Undo is preferred to asking first. An action that cannot be undone asks first: the question names the thing and the consequence, the confirm button names the action, it is styled as destructive, and focus starts on the safe choice. Which actions may be undone is a product question per action. | Nielsen 3 and 5 | kit · review |
| `UXR-24` | A control is never unavailable without saying why, beside it. | Nielsen 1 | kit |

### Forms and input

| ID | Requirement | Source | Verified |
|---|---|---|---|
| `UXR-25` | Labels sit above their fields and stay visible — a placeholder is never the label. An optional field is marked *(optional)*. | Form-design guidance; WCAG 3.3.2 | kit |
| `UXR-26` | The input fits the data: the numeric keypad for numbers, a comma or a point as decimal separator, the unit shown beside the field and never typed, the device's own date picker, a choice from a list rather than a typed code. A number is shown back as it was read. | Form-design guidance | kit |
| `UXR-27` | Text in an input, and body text, is at least 16 px — smaller makes iOS zoom the page on focus. | Platform guidance | kit · lint |
| `UXR-28` | What the browser can fill — e-mail, name, address — is marked for autocomplete. Opening a dialog or a form page puts focus on its first field. | WCAG 1.3.5 | kit · browser |

### Touch

| ID | Requirement | Source | Verified |
|---|---|---|---|
| `UXR-29` | Adjacent touch targets are at least 8 px apart, on top of `UXR-08`'s size. | WCAG 2.5.8; platform guidance | kit · review |
| `UXR-30` | Nothing depends on hover — no action or information reachable only by pointing at something, and no tooltip as the only carrier of meaning. A touch screen has no hover. | WCAG 1.4.13 | kit · review |

### Orientation and consistency — Nielsen 3, 4 and 6

| ID | Requirement | Source | Verified |
|---|---|---|---|
| `UXR-31` | Every screen says where the person is: one page title (h1) naming the thing, repeated in the browser tab. | Nielsen 6; WCAG 2.4.2 | kit |
| `UXR-32` | Back, reload and a shared link all work: the open tab, filters, search terms and the selected item live in the URL, so a reload returns to the same view. | Nielsen 3 | review · browser |
| `UXR-33` | The same action is in the same place everywhere: a page's primary action at the top right of its header (below the title on a phone); in a dialog or form the primary action last, cancel before it. | Nielsen 4 | kit |
| `UXR-34` | A button says what it does — a verb, usually with its object (*Save order*, *Send invitation*) — never *OK*, *Yes* or *Click here*. | Nielsen 2 and 4 | review |
| `UXR-35` | Numbers in tables are right-aligned in even-width digits; a quantity always shows its unit. | Data-display guidance | kit |
| `UXR-36` | A long list can be searched, sorted or paged — never an endless scroll with no way to find one row. Which does is decided per list. | Nielsen 7 | review |
| `UXR-37` | Nothing important exists only in a message that disappears by itself. An error stays until it is fixed or dismissed. | WCAG 2.2.1 | kit · review |
| `UXR-38` | Running text is at most about 75 characters per line. | Typography guidance | kit |
