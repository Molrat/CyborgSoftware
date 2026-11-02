# Open Questions

**What is still needed from humans before it can be built.**

Everything here blocks something: a spec section, an architectural decision, or a
roadmap sub-phase. Root `CLAUDE.md` rule 1: a decision that is not written down
is asked, never invented.

**How to use it**: when a question comes up, add it here before asking it. When
it is answered, write the answer into the entry with the date and who answered,
move the decision into the document that owns it, and cite the entry from the
sub-phase that needed it. Question numbers are never reused, so gaps in the
sequence are expected.

Status: `OPEN` · `ANSWERED` (with date and by whom) · `DEFERRED` (consciously
postponed, with a trigger for revisiting)

**This is not the only register.** `[OPEN]` markers throughout the documents in
[docs/](../) hold questions that belong closer to the thing they concern — run
`grep -rn "\[OPEN\]" docs` for the current list. An entry here and a marker
there may point at each other; when the answer arrives, both are resolved.

## Entry format

```
## Q1 — <the question, as a question> · `OPEN`

**Blocks**: what cannot be built or decided until this is answered.
**Context**: why it comes up, and what the documents already say.
**Options**: the real choices, each with what it costs and what it makes harder later.
**Recommendation**: which, and what would change it.
**Answer**: — (date, by whom, and the decision)
```

---

## Q1 — How does a visitor get in touch? · `OPEN`

**Blocks**: the first sub-phase — the contact part of the website.
**Context**: the product's first job is that a visitor can reach the two
developers ([README.md](README.md)). The draft shows a contact form and a
"book an intro call" button, neither connected to anything.
**Options**: (a) a form that emails the developers — needs the API and outgoing
mail; (b) a link to an external booking tool (e.g. a calendar scheduler) — no
backend, but a third-party service (root `CLAUDE.md` rule 3); (c) a plain email
address and phone number — nothing to build, least slick.
**Recommendation**: (a), with the address and phone shown beside it.
**Answer**: —

## Q2 — Which region, and which language first? · `OPEN`

**Blocks**: the site's copy; the `[OPEN]` language marker in
[UX-REQUIREMENTS.md](UX-REQUIREMENTS.md#language).
**Context**: the business is local with on-site meetings (user, 2026-11-02),
priced in euros. The draft is in English and names no place.
**Answer**: —

## Q3 — Is the cost of the AI included in the €80 per hour? · `OPEN`

**Blocks**: the pricing section's wording.
**Context**: the selling point is "you only pay for two senior developers". The
draft says the AI team is included; nobody has confirmed it, nor who pays for
hosting after launch.
**Answer**: —

## Q4 — Do the developers appear by name and photo? · `OPEN`

**Blocks**: the "who you work with" section. The draft uses placeholders.
**Context**: "direct contact with two senior developers" is a selling point,
and faces make it believable; fabricated people must not appear.
**Answer**: —

## Q5 — Do the developers edit the site's content themselves? · `OPEN`

**Blocks**: whether the site needs sign-in and an editing screen at all, which
decides how much of the planned stack it uses.
**Answer**: —
