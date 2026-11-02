---
name: talk-to-human
description: Ask the user something in language they can act on — purpose first, no jargon, consequences stated, a recommendation given. Use whenever a question, a choice, a gate walk, or an explanation is going to the user rather than into a document.
user-invocable: true
---

# /talk-to-human — the other register

This repository writes for engineers. Its documents are dense, precise, and
assume the reader knows the codebase. **Keep writing them that way.**

This skill governs one channel only: **what you say to the user.** They are not
up to speed with the code, do not use engineering jargon, and hold limited domain
knowledge. Two registers, deliberately — do not let the documents' register leak
into this one, and do not let this one leak into the documents.

A question the user cannot answer is worse than no question. It stalls the work
*and* spends their attention.

## Start with the purpose. Always.

Before the question itself, say what kind of question it is. The user needs to
know what sort of attention to bring before they read the content — a decision
they will live with for a year and a "which of these two words is better" read
identically otherwise.

| Purpose | Opens roughly like |
|---|---|
| **Clarifying a sub-phase** | "Before I build X, I need to know what should happen when…" |
| **An architectural decision** | "This is a choice that is expensive to change later. Two options…" |
| **A product rule nobody has decided** | "The specification does not say, and I am not allowed to guess — see [OPEN-QUESTIONS.md](../../../docs/product/OPEN-QUESTIONS.md)." |
| **Walking a gate** | "The code is finished. This is the part only a person can check." |
| **Reporting a problem** | "I found something wrong with what we agreed. Here is the choice it leaves." |

If a message does two of these at once, split it.

## How to ask

**A genuine choice between options → the picker** (`AskUserQuestion`). Put the
recommendation first and mark it. Two or three real options, never five — if two
of them are the same answer wearing different clothes, drop one.

**Everything else → plain prose in the chat.** Open-ended questions,
explanations, gate walks, anything where inventing options would hide the answer
the user would actually have given.

## Rules for the words

- **No jargon without a definition.** If a term is genuinely unavoidable, define
  it in half a sentence, the first time, every time. Treat `repository`,
  `migration`, `endpoint`, `projection`, `idempotent`, `abstraction`,
  `dependency injection`, `store`, `reducer`, `schema`, `state management` and
  every abbreviation as needing this.
- **Never omit the consequence.** "Option A is faster to build" is plain English
  and useless. "Option A is faster now, but if we later want two people to edit
  the same record at once, we rebuild this screen and everything under it" is
  plain English and decidable. Plain language is not the goal; *decidability* is.
- **Price things in time and rework**, not in nouns. "About a day, and it would
  need redoing if X changes" beats "it introduces a coupling".
- **Say what you recommend, and why.** Presenting a balanced menu with no opinion
  pushes an engineering judgement onto someone who has said they cannot make it.
  Recommend, then say plainly what would change your mind.
- **Never ask what you can find out.** Read the repository first. A question
  answerable by `grep` spends the user's attention on nothing.
- **Do not flatter, hedge, or apologise into the question.** Lead with it.

## Explaining an architectural choice

For each option, in this order, one short paragraph each:

1. **What it means in practice** — what the user would actually see or do.
2. **What it gives you.**
3. **What it costs**, in time now.
4. **What it makes harder later** — the part they cannot evaluate alone, and the
   only reason the question is being asked at all.

Then the recommendation, and what would change it.

## Walking a gate

The user wants a full script, one step at a time — but **never cold**.
Specific instructions without context are the thing to avoid.

1. **Brief first, in two or three sentences.** What was built, what could be
   wrong that the automated tests genuinely cannot see, and why that means a
   person has to look. Then one or two more: what the AI's own walk in the
   browser (`/look`) already found and fixed, and which checks it could not
   judge — those are where the person should look hardest. No checklist yet.
2. **Then the shape of the walk** — roughly how many checks, which areas of the
   app, and how long it will take. The user is deciding whether to start now.
3. **Then one check at a time.** The exact action, and exactly what they should
   see if it is right. Wait for their answer before giving the next one.
4. **When something looks wrong, ask what they saw** before diagnosing. Their
   description is the evidence; do not replace it with a theory.
5. **Record honestly.** Any unchecked item fails the gate
   ([README.md](../../../docs/roadmap/README.md)). A partial pass is a fail, and
   saying so is the whole point of the exercise.

## Reporting what you saw in the app

After a [`/look`](../look/SKILL.md), the user hears what a person would have
seen — not the walk's record. The record (path, verdict, console, screenshot
files) goes into the slice report or beside the gate row, in the documents'
register.

1. **Purpose first**: "I opened the new *Planning* screen in the app as a
   planner, to check it before you see it."
2. **What looked right, in one line.** Not a list of every click.
3. **Each problem on its own**: what was on the screen, using the screen's own
   words (the labels as shown), what it should have been, and what you did
   about it — fixed, or the choice it leaves, with a recommendation.
4. **What could not be checked in a browser, and why** — a PDF's content, an
   email, whether a wording is right for the people who will use it.
5. **No tool names or browser internals.** Not `browser_snapshot`, not "the
   console": "the page reported an error behind the scenes" is enough, and the
   detail goes in the record.

## Anti-patterns

- **"Does it work correctly?"** — not a check. "Assign the task to a colleague;
  their name appears on the card without you refreshing" is.
- **The question buried under three paragraphs of context.** Purpose, question,
  then context.
- **A decision handed over with no recommendation.**
- **Five options where two are real.**
- **Reporting green without saying what actually ran.** See
  [/verify](../verify/SKILL.md) — a skipped layer is not a passing layer, and
  the user cannot infer that from "the tests pass".
