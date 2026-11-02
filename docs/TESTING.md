# Automated Testing

The purpose of this system is narrow and specific: **make it impossible to break
existing behaviour without a red test.** Every rule below serves that goal.

Current state: **5 layers designed, 0 test methods.** No test project exists yet;
the first sub-phase that builds code creates the layers it needs. Run them with
[`run-tests.ps1`](../run-tests.ps1), which skips a layer with no projects.

Every count in this document is **test methods** — one `[Fact]`/`[Theory]`, or
one frontend `it()`/`test()`, or one browser journey `test()`. A `[Theory]`
expands into several cases at run time, so an actual run reports more than these
numbers. Methods are what the tree can be counted for without Docker, which is
what makes them checkable —
[`check-testing-inventory.sh`](../.claude/hooks/check-testing-inventory.sh)
recounts them on any commit that touches tests and asks when this document has
drifted. Keep the inventory line below in step with the prose.

<!-- test-inventory: unit=0 component=0 e2e=0 frontend=0 browser=0 projects= -->

**Last verified**: never — there is nothing to run yet. Each verified run adds a
dated line here: which layers ran, how many passed, what was skipped and why.

---

## The pyramid

Three .NET layers, a frontend layer, and a browser layer on top. Each answers a
different question, and the same behaviour is asserted at exactly one of them.

| Layer | Question it answers | Location | Prerequisite |
|---|---|---|---|
| **① Unit** | Is this pure rule correct? | `tests/unit/` | none |
| **② Component** | Does this service behave when its DB and HTTP pipeline are real and everything external is faked? | `tests/component/` | Docker |
| **③ E2E** | Does the whole stack actually compose? | `tests/e2e/` | stack up (`cyborgsoftware-caddy`) |
| **④ Frontend** | Do stores, adapters and pure logic behave? | co-located in `containers/frontend/src/` | npm |
| **⑤ Browser** | Can a person complete a critical journey, in a real browser, on the real stack? | `tests/browser/journeys/` | stack up, npm, Chrome |

```
        ▲  fewer, slower, broader
        │
   ⑤ browser ──────  Chrome driving the SPA on the stack ③ uses
        │
   ③ e2e ──────────  Caddy + API + DB
        │
   ② component ────  one service in-process, real Postgres
        │
   ① unit ─────────  no I/O at all
   ④ frontend ─────  Vitest + happy-dom, then the design-system lint
        │
        ▼  more, faster, narrower
```

The intended shape: e2e and browser are a thin cap, and the bulk sits in
component and frontend.

### ① Unit — `tests/unit/`

Pure. No I/O, no `WebApplicationFactory`, no DB, no DI graph. `new` up the class
and assert. Milliseconds per test; run on every save.

Target: domain classes, value objects, pure helpers, framework-agnostic logic.
One project per production project whose internals you test
(`<Api>.<Feature>.Domain.Tests`).

### ② Component — `tests/component/`

One project per backend container. The whole service runs in-process via
`WebApplicationFactory<Program>`.

**Real**: own DB via [Testcontainers](https://dotnet.testcontainers.org/)
(migrations + procedures deployed at fixture init), real DI, real middleware,
real serialization, real routing.
**Faked**: external services only — email, object storage, third-party APIs —
swapped via `ConfigureTestServices`. Fakes are minimal; they are not contract
tests.

One Postgres testcontainer per test collection (collection-scoped fixture);
a reset truncates between test classes.

This is where the bulk of integration confidence lives. It catches stored-proc
signature mismatches, JSONB cast bugs, data-isolation and role checks,
controller validation, and middleware ordering — the failure classes that unit
tests structurally cannot see. A column rename is proven here: the C#, the
stored function, and the migration all have to agree or the suite goes red.

### ③ E2E — `tests/e2e/`

Smoke against the running compose stack via Caddy. Deliberately small — **~5–10
tests per suite** proving golden paths and the cross-cutting concerns that only
exist when everything is wired together: TLS termination, path routing,
same-origin cookies. That number is a ceiling, not a description.

Requires `docker compose up -d` and the dev DB port from
`docker-compose.override.yml`.

### ④ Frontend — co-located

Vitest + happy-dom. **Tests live next to their source** (`auth.test.ts` beside
`auth.ts`) — the Vitest convention, and what every Vue tool expects. They don't
ship: the Vite build only emits what's reachable from `main.ts` / `index.html`.

Stores and the API client run against a mocked `api` module; transport adapters
mock the transport. Components get mounted with `@vue/test-utils` only when their
behaviour is *interaction*, not markup.

**The layer also runs the design system's checks** — `npm run lint`, ESLint and
Stylelint ([architecture/design-system.md](architecture/design-system.md#4-the-checks))
— after Vitest, and fails on either.

Adversarial cases a shared mount would hide — a double submit, a slow response
landing after a newer one — get a file of their own (`*.doubleSubmit.test.ts`,
`*.errors.test.ts`), because the state they corrupt does not survive being
shared with a second case.

### ⑤ Browser — `tests/browser/`

Playwright Test driving the installed **Chrome** through the SPA, against the
same running stack ③ uses. Its own npm package; `run-tests.ps1 -Browser` runs
`npm ci` on first use. **It answers one question no other layer can: can a
person get through a critical journey?** Vitest + happy-dom has no real browser
storage, cookie jar, file chooser or second device; e2e has no browser at all.

**A journey, not a rule.** One test per path a person must be able to walk —
gate tables are the source, and each journey names the gate rows it saves.
Rules, labels, edge values and refusals stay below, where they are cheap and
exact; a journey asserts only what a person would look at.

| Journey | Gate | Crosses |
|---|---|---|
| *(none yet)* | | |

**How a journey is built** (`support/`):

- **Seeded by API, never by row.** `seed.ts` creates fresh data per test
  through the endpoints the SPA calls, so journeys share nothing and run in
  parallel. The only direct database read allowed is what no endpoint returns
  by design — e.g. an emailed token — and it goes through `docker exec … psql`.
- **One journey clicks the setup**; the others seed it, so a change to the setup
  screens breaks one test, not five.
- **"On the server" means a second browser context.** A fresh context has no
  local storage, so what it shows came from the server.
- **Wait on a condition, never a fixed sleep.**
- **An uncaught page error fails the test** (`support/ui.ts`).
- **Every kit-built screen a journey reaches gets `checkScreen(page)`**
  (`support/quality.ts`): axe at WCAG 2.2 AA, failing on serious and critical
  findings, and at phone width — against the screen's real width, not the
  widened layout a phone browser reports — no sideways scroll and no control
  outside the screen (a frame that scrolls on purpose excepted).
- **The `/kit` screenshot is the design system's reference** —
  `journeys/design-system.spec.ts-snapshots/`, one per size, per platform. An
  unintended change to a kit component fails it; a deliberate one re-records it
  (`npx playwright test design-system --update-snapshots`) and is signed off on
  `/kit`.
- **A known defect is `test.fail()` with its `D-xxx`** — it passes while the
  defect stands and errors the moment it is fixed, so the mark is removed in
  the fixing change. Never a skip: a skip says nothing when the bug goes.
- **Selectors are roles and visible text**, as a person reads the screen; no
  `data-testid` added to the app for this layer.
- **`tools/` is not tests.** `tools/accounts.spec.ts` (own config,
  `tools.config.ts`) only seeds accounts for `/look`; it is not counted and
  `run-tests.ps1` never runs it.

**Every journey runs twice** — Playwright projects `desktop` (1280 × 800) and
`phone` (390 × 844, touch, mobile layout) — because no screen may show a visual
defect on a phone. `--project=desktop` runs one size. An action that cannot land
in 15 s fails there (`actionTimeout`). Locale and time zone are fixed in the
config, whatever the machine's. **No retries**: a journey that passes on the
second try is a finding. Failures keep a trace and a screenshot in
`tests/browser/test-results/` (git-ignored): `npx playwright show-trace <path>`.

---

## Rules

- **New test? Default to unit.** Drop to component only if it needs the DB or the
  HTTP pipeline. Go to e2e only to prove the whole stack composes, and to
  browser only for a person's journey that needs a real browser on that stack.
- **No service-layer mocking.** Don't build elaborate mocks for orchestration
  code — exercise services through component tests, behind their real controllers
  and repositories.
- **No duplicated assertions across layers.** If a component test covers a 403,
  e2e doesn't.
- **No contract tests** while every service lives in this repo and deploys
  together. Revisit if services deploy independently.
- **A bug fix ships with the test that would have caught it**, at the lowest layer
  that can see it.
- **Red before green.** When fixing a reported bug, write the failing test first
  and watch it fail. A test that has never failed proves nothing.
- **Two implementations of one rule are tested by one shared fixture set.** If a
  rule ever has to run both in the browser and on the server, its cases live
  once as JSON data (`{ input, expected }`) and are run by *both* a Vitest
  runner and a .NET runner — one assertion that the two implementations agree,
  which no single layer can make. This is the one sanctioned exception to "no
  duplicated assertions".

---

## Running

```powershell
.\run-tests.ps1                 # every layer whose prerequisites are met
.\run-tests.ps1 -Unit -Frontend # fastest loop, no Docker needed
.\run-tests.ps1 -Component -NoBuild -Filter "FullyQualifiedName~<Feature>"
.\run-tests.ps1 -Browser        # the journeys; stack up
```

One journey, watching the browser: `cd tests/browser; npx playwright test
<name> --headed`.

Layers whose prerequisites aren't met are **skipped, not failed**: no Docker
skips component, e2e and browser; no `cyborgsoftware-caddy` skips e2e and
browser; no `containers/frontend/package.json` skips frontend; a layer folder
with no project skips that layer. **E2E and browser test the containers that are
running**, not the tree: rebuild (`docker compose up -d --build`) after a
change, or they pass against the last build. The script exits non-zero only on a
real failure, which is what makes it safe as a CI entry point — provided CI
asserts the prerequisites first ([CI-CD.md](CI-CD.md)).

Prefer it over hand-rolled `dotnet test` invocations.

---

## Looking at the app in a browser — not a test layer

[`.mcp.json`](../.mcp.json) wires the **Playwright MCP server** into Claude
Code: an agent can open Chrome, navigate the running app, click, type, read the
console and take screenshots. It exists so a slice is *seen* working in the real
app before the person walks its gate. **It is not the browser layer.** Nothing it
does is saved, counted or re-run; a defect found through it gets a test at the
lowest layer that can see it — a saved journey in ⑤ only when nothing lower can.

| Setting | Why |
|---|---|
| `--browser chrome` | Drives the installed Chrome; no Playwright browser download |
| `--isolated` | Profile in memory: every session starts logged out, with no browser storage left from the last one |
| `--ignore-https-errors` | Caddy's local certificate is self-signed |
| `--allowed-origins https://localhost;http://localhost:8025` | The local stack and the local mail catcher only — keeps it off any production domain. A guard against mistakes, **not** a security boundary (Playwright's own wording) |
| `--output-dir .playwright-mcp` | Screenshots land there, git-ignored |

Prerequisites are the e2e ones — the stack up, and rebuilt after a change.
[`.claude/settings.json`](../.claude/settings.json) enables the server
(`enabledMcpjsonServers`) and allows its tools (`mcp__playwright`), so looking
needs no prompt per click; the tools load at session start, so restart Claude
Code after changing `.mcp.json`.

**When it is used is not left to anyone remembering.** [`/look`](../.claude/skills/look/SKILL.md)
is the procedure; `/feature-slice` step 6 requires it on every screen a slice
adds or changes, `/gate` and `/continue` require a pre-walk of every gate row
before a person walks it, and `check-browser-journey.sh` stops a commit that
adds a screen without touching `tests/browser/journeys/`.

What a look reports: the path walked, under which role, what was seen
(screenshots), and any console errors — never "it works" without those.

---

## What this system does not cover yet

Tracked honestly so nobody mistakes green for complete. A gap in code that
already ships belongs in [DEBT.md](DEBT.md) as well, where a trigger can fire on
it; this list is the summary.

- **Everything** — no test project exists yet.
- **No load or performance testing**, and no thresholds to test against
  ([product/UX-REQUIREMENTS.md](product/UX-REQUIREMENTS.md#responsiveness)).
- **No mutation testing**, so coverage is trusted to be honest.
- **Nothing runs these tests but a person** until CI exists ([CI-CD.md](CI-CD.md)).
