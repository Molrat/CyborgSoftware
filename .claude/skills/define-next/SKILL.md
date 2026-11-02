---
name: define-next
description: Define the next sub-phase — one whole full-stack feature — through a conversation with the user, ending in a written definition, its gate, and a cold readiness verdict. Use when the roadmap needs its next sub-phase defined, or when /continue finds nothing READY to build.
user-invocable: true
---

# /define-next — define one sub-phase, just before building it

This is a **conversation**, not a generation step. It ends with a written
definition, a gate, and a `readiness` verdict — and then it **stops**. It never
implements.

Everything said to the user here is governed by root [CLAUDE.md](../../../CLAUDE.md)
rule 5 — **load [/talk-to-human](../talk-to-human/SKILL.md) before the first
question.** The user is not up to speed with the code. A question they cannot
answer stalls the roadmap and spends their attention anyway.

## What a sub-phase is

**One whole feature, full-stack, that a person can be handed and asked to use.**
A planner. A review queue. An admin screen. Not a dropdown, not a card, and
never "the backend for X".

**The screen is part of the feature.** Backend-only sub-phases are refused —
there is no such thing as a throwaway UI to prove an API works, because
automated tests and Swagger already do that job. A sub-phase whose frontend is a
harness rather than the real screen is mis-scoped, not nearly finished.

**The bar for that screen is functional, usable, and built from the design
system's kit** ([design-system.md](../../../docs/architecture/design-system.md))
— `@/kit` and its templates only, held by the checks and by `checkScreen` in
its journey. Say so in the definition, and name any kit component the screen
needs that does not exist yet: it is part of the sub-phase. If the screen
extends one on `kit-exemptions.json`, offer moving that file onto the kit
(step 3). Full rule: [README.md](../../../docs/roadmap/README.md#rules).

## 0. Refuse to run ahead

Check `docs/roadmap/phases/` first. If any sub-phase is `READY` or `BUILDING`,
**stop** — that one gets built before the next is defined. Definition is
just-in-time by rule, and a definition written two sub-phases early is a guess
about a codebase that does not exist yet.

## 1. Propose the candidate

Read [docs/product/](../../../docs/product/) — the product description,
workflows, [ACCEPTANCE.md](../../../docs/product/ACCEPTANCE.md) — and the
remaining shape sketched in [phases.md](../../../docs/roadmap/phases.md).
Propose **two or three** candidate features with a recommendation and the
reason, in the user's language: what a person could do that they cannot do
today.

Say what each one unblocks and what it leaves for later. The user is choosing an
order, not approving a plan.

If `docs/product/` does not yet say enough to propose anything, that is the
conversation to have first — ask, and write the answers there.

## 2. Size it

Apply the one-sentence test aloud: *"A &lt;role&gt; can &lt;do a thing&gt;."*
If it needs an "and" joining two unrelated outcomes, it is two sub-phases — say
so and ask which comes first. If it is a control rather than a capability, it
belongs inside a bigger one.

## 3. Offer the debt this sub-phase would touch

Read [DEBT.md](../../../docs/DEBT.md) and find every entry whose **trigger** this
sub-phase fires — an entry whose trigger names the area, screen or layer this
work is about to open anyway.

For each one, **put the choice to the user** and let them decide. This is the
moment debt is actionable: the code is about to be opened regardless, so fixing
it costs a fraction of what a dedicated effort would, and skipping it costs
nothing today. Both are legitimate.

Present it the way [/talk-to-human](../talk-to-human/SKILL.md) requires — the
purpose first (*"this sub-phase opens code that has a known problem in it"*),
what the entry actually is in plain language, then two options:

- **Fold it into this sub-phase** — roughly what it adds in time, and what stops
  being true afterwards.
- **Skip for now** — the feature ships sooner; the entry stays and is offered
  again the next time something fires its trigger.

**The user decides, every time.** Never fold debt in silently, and never refuse
to define a sub-phase because debt was declined — shipping features is the
point, and an entry declined today is not a failure.

Record the outcome on the entry itself:

- **Taken** → it goes in the definition's *In scope* section, and is removed
  from `DEBT.md` by the commit that actually fixes it, not before.
- **Skipped** → append the date to the entry's *Offered and skipped* line.
  An entry declined four times is telling you something: either it does not
  matter and should be deleted, or it is being avoided and is bigger than its
  description says. Say so when it reaches that point.

## 4. Find what is undecided, and ask

`grep -rn "\[OPEN\]" docs/product` for this area, plus
[OPEN-QUESTIONS.md](../../../docs/product/OPEN-QUESTIONS.md). Every product
question this feature touches gets **asked**, never resolved by picking
something sensible — root [CLAUDE.md](../../../CLAUDE.md) rule 1.

Ask them one at a time, purpose first, with a recommendation and what it costs.
Write each answer into `OPEN-QUESTIONS.md` as it is given — an answer that lives
only in this conversation is lost the moment the session ends.

## 5. Check the substrate

Run [/spec-check](../spec-check/SKILL.md) on everything the feature sits on.
**Confirm against the tree, not the docs** — they drift. Anything `[SPEC]` or
`[PARTIAL]` is a blocker to raise with the user now, not a caveat to note and
build past.

## 6. Write the definition

Copy [subphase-template.md](../../../docs/roadmap/subphase-template.md) to
`docs/roadmap/phases/<id>-<slug>.md`, `state: DRAFT`. Fill every section. The
*deliberately out of scope* list is required: an empty one means the boundary was
never drawn, and `readiness` will refuse it.

## 7. Write the gate — now, not later

Run [/gate](../gate/SKILL.md) and fill the gate into the same file, from the
definition. A gate written after the work describes what was built; a gate
written now specifies it.

Keep it **short and high-value**. Chunky sub-phases make long gates, and a long
gate does not get walked. Every check earns its place by being something the
automated test layers genuinely cannot see.

## 8. Hand it to a cold reader

Dispatch the **`readiness`** agent. It has not heard this conversation, which is
the entire point — it cannot be talked round by reasoning it never heard.

- `READY` → set `state: READY`, `readiness: READY`, and run
  `bash docs/roadmap/build-index.sh`. **Stop here.** Report what was defined and
  what it deliberately excludes. Building is a separate decision the user makes
  next.
- `NOT READY` → fix what it names and dispatch again. **Do not argue with it**,
  and do not explain away a finding. If a finding is genuinely wrong, the
  definition is ambiguous enough to mislead a careful reader — which is the same
  defect.

## Never

- Define more than one sub-phase in a run.
- Answer an `[OPEN]` question yourself.
- Scope a sub-phase without a screen.
- Continue into implementation. `/define-next` ends at `READY`.
