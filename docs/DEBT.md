# Technical Debt

Code that is **built and working, and built wrong**. One file, because the list
should stay short enough to read.

## What belongs here, and what does not

| It is | Goes to |
|---|---|
| Built, working, and wrong — a decision in the wrong layer, a shortcut that held, a pattern that drifted | **Here** |
| A product question nobody has answered | [product/OPEN-QUESTIONS.md](product/OPEN-QUESTIONS.md) |
| A design worked out but never built | a `[SPEC]` section in [architecture/](architecture/) |
| A feature not built yet | [roadmap/phases.md](roadmap/phases.md) |

Debt is *built wrong*, not *not built*. Everything else has a home already, and
a debt list that accepts anything becomes a place to put things instead of a
place to fix them.

**Missing coverage for code that already ships belongs here**, and it is the one
case where that rule needs saying out loud, because it reads at first like *not
built*. It is not: the feature exists, runs, and is relied on — what was skipped
is the verification, which is a shortcut that held. A test for a feature nobody
has built yet is a different thing and belongs to that feature's sub-phase. The
distinguishing question is whether the code is in use today; if it is, its
untested paths are debt. Gaps described only in prose — in
[TESTING.md](TESTING.md)'s "does not cover yet" list, say — get an entry here
too, because no trigger fires on prose and `/continue` never looks there.

## Urgent, or ordinary

Entries are not a queue and are not worked in the order they arrived. They split
in two, decided by one question asked when the entry is written:

> **Does this cause harm while nobody touches it?**

**Urgent** — yes. Bad data can be written today, a signal is dead, a release is
blocked. An urgent entry has **no trigger**, because waiting for someone to
wander past the area is exactly the wrong behaviour when the damage is already
accruing. [`/continue`](../.claude/skills/continue/SKILL.md) names every urgent
entry, every run, until it is gone.

**Ordinary** — no. It costs future effort and nothing else. Trigger-based, fixed
inside work that opens that code anyway, and the order genuinely does not matter.

**A person answers that question, not the system.** Judging consequence is what
each entry's *what it costs* paragraph exists for, and automating it would be
guessing. Promote or demote an entry whenever the judgement turns out wrong —
and say why in the entry, since a demotion is itself a decision.

## The rules

**Every entry names a trigger, never a date** — unless it is urgent, which has
none by definition. A trigger is a piece of work that will happen anyway and
cannot sensibly happen without also fixing this. "The next sub-phase that
touches the orders screen" fires, because one will. "Q4" expires quietly and
nobody notices.

**An entry is picked up by being offered, and the user decides.** When
[`/define-next`](../.claude/skills/define-next/SKILL.md) scopes a sub-phase that
fires a trigger, it puts the choice to the user in plain language: fold this in,
or skip it. [`/continue`](../.claude/skills/continue/SKILL.md) reads this file
before choosing what to do, so a fired trigger is visible while it can still
change the decision rather than after the work is done.

**Skipping is a normal answer, and it is recorded.** Shipping features is the
point, and an entry declined today has cost nothing. Append the date to the
entry's *Offered and skipped* line. An entry declined four times is evidence:
either it does not matter and should be deleted, or it is being avoided because
it is bigger than its description admits. Say which.

**Debt is never a sub-phase of its own.** A pure refactor has no screen, so the
full-stack rule in [roadmap/README.md](roadmap/README.md) would refuse it. It
ships inside work that was opening that code anyway, which is why triggers are
written as "the next work that touches X" rather than as tasks.

**The `readiness` agent has nothing to do with this**, deliberately. It answers
one question — is this sub-phase described well enough to build? — and debt is
about code that already exists. Mixing them would make a `NOT READY` verdict
mean two unrelated things and be worth less. Do not add a debt check to it.

**This list is not a plan**, and two things follow honestly from that. Debt in
code nobody opens is never fixed, because its trigger never fires — that is the
intended trade, not an oversight. And a trigger can be dodged by scoping a
sub-phase to just miss the area; only a person noticing will catch that.

**An entry leaves only when the code changes.** Deleting one because it no longer
feels important is how a known problem becomes an unknown one. If it genuinely
stopped being true, say so in the entry and why. A fixed entry moves to
*Resolved* with the date and what fixed it.

**The [`reviewer`](../.claude/agents/reviewer.md) agent may add entries** for
divergences it finds that are real but out of scope for the change under review.
That is the main way things get here — noticed by something that was looking at
the code for another reason.

## Entry format

```
## D-001 — <what is wrong, in one line>

**Where**: the files or area.
**What it costs**: what goes wrong, or what gets harder, while it stays.
**How it happened**: the shortcut, and why it was taken.
**Trigger**: the work that will fix it — or none, if urgent.
**Offered and skipped**: dates.
**Added**: date.
```

Numbers are never reused.

---

# Urgent

None.

---

# Ordinary

None.

---

# Resolved

None.
