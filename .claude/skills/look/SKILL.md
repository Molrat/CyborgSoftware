---
name: look
description: Look at the running app in a real browser (the Playwright MCP tools, mcp__playwright__*) — log in as a role, walk a screen or a gate's rows, and report what was actually seen, with screenshots and console errors. Use after building or changing any screen, before handing a gate to a person, when a bug is reported on a screen, and whenever the question is "does it actually work in the app".
user-invocable: true
---

# /look — see it in the app, not just in the tests

Tests prove what they assert. Looking proves what a person will meet: the
screen loads, the button is where the gate says, the wording reads right,
nothing throws in the console, it fits a phone. **No screen is finished, and no
gate is ready to walk, until an agent has looked at it.** It costs minutes and
saves the person walking the gate from finding what a look would have found.

The browser is set up in [`.mcp.json`](../../../.mcp.json); its settings and
limits are in [TESTING.md](../../../docs/TESTING.md#looking-at-the-app-in-a-browser--not-a-test-layer).
It reaches `https://localhost` and the local mail catcher only — never a
production domain.

## 1. Make sure you are looking at today's code

The browser sees the containers that are running, not the tree.

```bash
docker compose up -d --build      # after any change to the code being looked at
```

**No `mcp__playwright__*` tools in this session?** They load at session start,
after the user has approved the project's server once. Say so plainly — "the
browser tool is not loaded; restart Claude Code to enable it" — and do the rest
of the work. Never report a screen as looked-at when it was not.

## 2. Get accounts with the right roles

```bash
cd tests/browser
npx playwright test -c tools.config.ts -g "<scenario>"
```

`tests/browser/tools/accounts.spec.ts` seeds accounts and the data a scenario
needs through `support/seed.ts`, and prints the emails, the password and what
exists. Every run makes fresh data, so nothing you click affects anyone else's.
Need a state no scenario gives? Build it **through the screens** as the right
role — that is looking too — or add a scenario to `tools/accounts.spec.ts`
through the API. Never insert rows.

(Until `tests/browser/` exists, register through the app itself, and add the
seeding scenario in the slice that builds the first journey.)

**If logging in ends that user's other sessions**, use one account per browser
at a time. For a hand-off between two people, log in as one, look, log out,
then the other.

## 3. Walk it as the person would

Navigate, click and type through the screens with the browser tools, as the
role the gate or the definition names. Along the way:

- **Snapshot before acting** (`browser_snapshot`) — act on what is on the
  screen, not on what the code says should be.
- **Screenshot what matters** (`browser_take_screenshot`) — each state a person
  would check, and every problem. They land in `.playwright-mcp/` (git-ignored).
- **Read the console** (`browser_console_messages`) at the end of each screen.
  An error there is a finding even when the screen looks right.
- **Reload** after anything that should persist; it is how "saved" is checked.
- **Every screen on a phone too — always.** After the desktop walk,
  `browser_resize` to 390 × 844 and walk the same screens again: everything
  reachable, nothing cut off, no sideways scroll (`document.documentElement.scrollWidth`
  against `window.innerWidth`), the main actions usable. Screenshot each.
  No screen may show a visual defect on a phone
  ([UX-REQUIREMENTS.md](../../../docs/product/UX-REQUIREMENTS.md#responsiveness)).
- **What a phone problem becomes** depends on the screen. On a screen built
  from the kit it is a defect, fixed in the slice. On one still on
  `containers/frontend/kit-exemptions.json` it goes in the debt entry that
  covers that file, reported to the user in the same look — not fixed in the
  slice unless a gate row asks for phone width or the screen cannot be used at
  all. A function that is broken is fixed regardless of screen size.
- **Judge a kit-built screen's look against `/kit`** — the signed-off
  catalogue: the same buttons, fields, pills and spacing, and one primary
  action. Report a difference; it means something was built beside the kit.
  On an exempt screen judge function, not polish.
- **Try one wrong thing** per form — an empty required field, a double click on
  save. A person walking the gate will.

## 4. Report what was seen

Two reports, in two registers. **To the user**: follow
[/talk-to-human](../talk-to-human/SKILL.md#reporting-what-you-saw-in-the-app) —
purpose first, what a person would have seen, each problem with what you did
about it, no tool names. **The record** — in the slice report or beside the
gate row — per screen or per gate row:

| | |
|---|---|
| **Path** | role, and the clicks from login |
| **Seen** | what the screen showed, plainly, with the screenshot file |
| **Verdict** | *looks right* / **looks wrong** — what, and what was expected / *cannot be judged in a browser* (and why) |
| **Console** | clean, or the errors |

Never "it works" without the path and the screenshot behind it.

## 5. What a finding becomes

- **A defect in what was just built** → fix it now, then add the test that
  would have caught it at the lowest layer that can see it
  ([TESTING.md](../../../docs/TESTING.md), *Rules*), and look again.
- **A defect in older code** → [DEBT.md](../../../docs/DEBT.md) with a trigger,
  or a `test.fail()` journey naming it if only the browser can show it.
- **Behaviour nobody decided** → [OPEN-QUESTIONS.md](../../../docs/product/OPEN-QUESTIONS.md)
  and ask (root CLAUDE.md rule 1). Do not fix it by picking something.

## What looking is not

- **Not a gate walk.** An agent's look never marks a gate row passed; the gate
  is a person who did not build the feature (`/gate`). The look is what makes
  the walk short.
- **Not a saved test.** Nothing here re-runs. A path a person must always be
  able to walk becomes a journey in `tests/browser/journeys/` (`/feature-slice`
  step 5).
