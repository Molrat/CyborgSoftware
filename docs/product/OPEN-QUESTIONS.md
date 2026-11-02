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

*(No questions yet.)*
