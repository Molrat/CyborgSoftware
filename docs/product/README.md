# Product

**What we are building and why.** Everything else in [docs/](../) serves this
folder.

## What it is

The public website of CyborgSoftware, a small start-up that builds software for
small and medium-sized companies. The company is two senior developers running a
team of AI agents. The humans bring what the AI cannot: face-to-face, on-site
conversations with the client and its stakeholders, logical thinking, senior
experience and intuition, and the final responsibility for what ships. The AI is
the brute-force building and testing force. It takes well-defined features as
input and produces well-tested, full-stack, deployment-ready pull requests. On
big architectural decisions and third-party software, the AI asks the
developers.

The selling points the site must carry:

- **You pay for two senior developers, and nothing else.** A whole team of AI
  agents works in parallel behind them. No sales, no HR, no account managers:
  the client talks directly to the two developers.
- **Local, face to face.** A local business: the developers meet clients in
  person, on site. *(Stressed by the user, 2026-11-02.)* Which region is
  `[OPEN]`.
- **Fast.** An MVP in weeks, if it is not too complex.
- **Simple pricing.** The developers' hourly fee, €80 per hour.

The site must **show the symbiosis** between human and AI, not just state it.
Reference material on where the responsibilities lie:
`C:\projects\nodemo\docs\roadmap\stakeholder-presentation.html` (the process
diagram: the AI asks for input, checks it, builds and tests, asks for review,
fixes findings; the human says what to build, makes the big choices, and checks
the result in the running application).

**Look and feel**: extremely slick, professional, subtly animated. Style
reference: framer.com. *(Given by the user, 2026-11-02.)*

**Content**: the user has not written copy and asked for a complete-looking site
to be drafted and refined from there. Drafted copy is a proposal until the user
has seen it. A first visual draft was made on 2026-11-02 (a claude.ai artifact,
not code in this repository).

## Who uses it

| Who | Comes to | Device |
|---|---|---|
| **Visitor** — an owner, director or manager at a small or medium-sized company who needs software built | Understand the offer, the price and how working together goes, and decide whether to get in touch | `[OPEN]` — assumed desktop first, phone must be flawless |

`[OPEN]` Whether the two developers edit the site's content themselves (which
would need a sign-in and an editing screen) or content changes are code
changes. See [OPEN-QUESTIONS.md](OPEN-QUESTIONS.md).

## What a person must be able to do first

A visitor understands what CyborgSoftware offers, how the human–AI split works,
and what it costs, and can **get in touch with the developers**. How they get in
touch is `[OPEN]` — see [OPEN-QUESTIONS.md](OPEN-QUESTIONS.md).

## Documents in this folder

| Document | Holds |
|---|---|
| [OPEN-QUESTIONS.md](OPEN-QUESTIONS.md) | Every product decision still needed from a person, and the answers as they arrive |
| [ACCEPTANCE.md](ACCEPTANCE.md) | The end-to-end scenarios the product is accepted on, each bound to one test layer |
| [UX-REQUIREMENTS.md](UX-REQUIREMENTS.md) | How every screen must behave — the professional baseline, written as checkable requirements |

Add documents as the product needs them — workflows, the domain model, a
permissions matrix, a glossary — one concern each, and a row here.
