---
name: continue
description: Resume the roadmap — work out where things stand, then walk a gate, resume a build, start a READY sub-phase, or define the next one. The single entry point; the user types "continue" and nothing else.
user-invocable: true
---

# /continue — pick up where the roadmap left off

The user types one word. This skill works out what that means and does exactly
one thing.

Everything said to the user is governed by root [CLAUDE.md](../../../CLAUDE.md)
rule 5 — **load [/talk-to-human](../talk-to-human/SKILL.md) first.** Open by
saying which of the situations below you are in and why, before doing anything
about it.

## 1. Read the state

Every sub-phase file in `docs/roadmap/phases/` carries its state in frontmatter:
`DRAFT`, `READY`, `BUILDING`, `BUILT`, `COMPLETE`. Definitions in
[README.md](../../../docs/roadmap/README.md).

[phases.md](../../../docs/roadmap/phases.md) indexes them, but it is
**generated** — read the files, not the table, and never write a state into the
table by hand.

**Whenever you move a sub-phase between states, run
`bash docs/roadmap/build-index.sh`** in the same step and commit the result with
it. The table exists so a person can see the roadmap at a glance; a stale one is
worse than none, and regenerating it takes a second.

Never guess a state from the code. If a file's state and the tree disagree, say
so and ask — a wrong state sends the whole loop the wrong way.

**Read [DEBT.md](../../../docs/DEBT.md) in the same pass**, before choosing what
to do. Note how many entries it holds and which of their triggers the work you
are about to pick would fire. Say both in your opening report — the count is
context, and a fired trigger is a choice the user is about to be offered.

**Name every entry under `# Urgent`, by name, every single run.** Those have no
trigger because they are causing harm while they sit there — bad data being
written, a dead test signal, a blocked release — so waiting for someone to
happen past the area is the wrong behaviour. Say what each one is costing right
now, and offer to fix it. The user may still say not yet; that is their call and
it is recorded like any skip. What is not optional is that they hear about it
every time, until it is gone.

Reading it early is the whole point: read last, a trigger is mentioned only once
the work it applied to is already finished.

## 2. Prepare everything that needs no person

**Do this first, and do all of it, before asking the user for anything.** These
cost the AI a few minutes and cost the user nothing, and each one removes a
reason to interrupt them later. Batch them: several in a run is correct here,
because none of them is a decision.

**Write every missing gate.** A sub-phase that is `BUILDING` with no gate cannot
be verified at all — it did not merely skip a step, it left nothing for a person
to walk. Write it from the definition and the acceptance scenarios, per
[/gate](../gate/SKILL.md), lowest id first. Keep it short: a long gate does not
get walked.

**Check each existing gate still fits what the code became.** A gate written
before its screens existed asks a person to verify through the API something
they could now simply look at. Read the sub-phase file: if its gate section says
it has been superseded, believe it, and fold the checks a person genuinely needs
to see into the gate of whatever replaced it. Never send the user to walk a gate
the file itself says is the wrong shape.

**Pre-walk every gate that is ready to walk** — each `BUILT` sub-phase whose
gate has no agent pre-walk yet, or none since its last change — in the browser,
per [/gate](../gate/SKILL.md) and [/look](../look/SKILL.md). Fix what the phase
built wrong; note the rest beside the row. A person should never be the first
to see a screen.

**Regenerate the index** (`bash docs/roadmap/build-index.sh`) if any state moved.

Then stop preparing and report what you did, in two or three lines.

## 3. Then ask the user for exactly one thing

Everything below needs a person. **Do one, then stop** — and prefer the one that
unblocks the most.

### Anything under `# Urgent` in DEBT.md → raise it first

Named in step 1, every run. Offer to fix it. Harm is accruing while it sits, so
it outranks work that is merely unverified.

### Any sub-phase is `BUILT` → offer the walk

Built-but-unwalked is work that looks finished and is not verified. It
accumulates silently — that is why it has its own state.

**Present everything walkable together**, now that step 2 has made it all
walkable: how many, which, and how long each has been sitting. Recommend the
oldest and ask. The user may choose to move on; that is their call, not a rule
to enforce. What is not optional is that they are told, every time, in plain
numbers.

Follow the gate protocol in [/talk-to-human](../talk-to-human/SKILL.md) — brief
first (what was built, what the tests cannot see, what the pre-walk found and
fixed, which rows it could not judge, why a person has to look),
then the shape of the walk, then one check at a time. Record the result in the
sub-phase file. A pass moves it to `COMPLETE`; **any** unchecked item fails it
and it stays `BUILT`.

### A sub-phase is `BUILDING` with a gate → resume the build

**Lowest id first** when several qualify — that is dependency order, and the
earlier one is usually what the later one leans on. Say what is done and what is
left before continuing. Finish with every test layer green
([/verify](../verify/SKILL.md) — name which layers actually ran) and every
screen looked at ([/look](../look/SKILL.md)), then set `BUILT`.

### A sub-phase is `READY` → build it

[/feature-slice](../feature-slice/SKILL.md), set `state: BUILDING` first. The
definition is the specification; if something in it turns out to be wrong or
missing, **stop and raise it** rather than deciding it mid-build — that is the
failure `readiness` exists to prevent, arriving late.

Dispatch `reviewer` and `tester` when the slice is done, per root
[CLAUDE.md](../../../CLAUDE.md).

### A sub-phase is `DRAFT`, or nothing is queued → define one

[/define-next](../define-next/SKILL.md). It is a conversation, and it **ends at
`READY`**.

**If [docs/product/README.md](../../../docs/product/README.md) still says the
product is not yet described**, that conversation comes first: there is nothing
to define a sub-phase *from*. Say so, and ask the user to describe what the
product is for, who uses it, and what the first thing a person must be able to do
is — one question at a time, per /talk-to-human — writing each answer into
`docs/product/` as it is given.

### Never do two of these in one run

**Never define a sub-phase and then build it in the same run.** Defining ends
with a cold `readiness` verdict and a stop, so the user decides whether to
proceed with a real definition in front of them. Rolling straight into
implementation turns just-in-time definition back into working ahead, with an
extra document to make it look deliberate.

Walking a gate, resuming a build, and starting a build are likewise one per run.
The batching in step 2 is the exception and only because none of it is a
decision: preparation is not delivery.

## 4. When a trigger fires, offer it — never decide it

If the run you are about to do fires a debt entry's trigger, put the choice to
the user **before** starting: fold it into this work, or skip it for now. The
full wording is in [/define-next](../define-next/SKILL.md) step 3, which is
where this normally happens — a sub-phase being scoped is the usual moment code
gets opened.

Three things hold regardless of the answer:

- **Never fold debt in without asking**, and never let it quietly expand a
  sub-phase the user already agreed to.
- **Never start debt as work of its own.** It has no screen, so the full-stack
  rule in [README.md](../../../docs/roadmap/README.md) would refuse it as a
  sub-phase, and the same logic applies here.
- **Skipping is a normal answer.** Shipping features is the point. Record the
  date on the entry and move on without arguing.

## 5. Close by saying where the roadmap is

Two or three lines, in the user's language: what just happened, what state it
left things in, and what `continue` would do next time. That line is how the
user keeps a model of the roadmap without reading any of it.
