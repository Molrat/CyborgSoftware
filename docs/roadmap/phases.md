# Phases

Every sub-phase has its own file in [phases/](phases/). This file is the index:
what exists, what state each one is in, and why the groupings are shaped the way
they are.

**State lives in the sub-phase's own file, in frontmatter** — see
[README.md](README.md#sub-phase-states). The table below is *generated* from
those files by [build-index.sh](build-index.sh); do not edit it by hand. If the
table and a file disagree, the file is right and the table is stale — rerun the
script.

Rules for how sub-phases are built and gated: [README.md](README.md).
Defining the next one: [subphase-template.md](subphase-template.md).

## Where things stand

<!-- INDEX:START -->
| # | Sub-phase | State |
|---|---|---|
| `0` | [Foundation](phases/0-foundation.md) | DRAFT |

DRAFT: 1 · COMPLETE: 0
<!-- INDEX:END -->

## The shape ahead

Sketched only as far forward as it stays useful — a sketch is not a definition.
Each sub-phase is defined by `/define-next` just before it is built.

1. **Foundation** — the stack runs end to end, the test layers and the design
   system exist, and a person signs off the look. Sketch:
   [phases/0-foundation.md](phases/0-foundation.md).
2. The first product feature — `[OPEN]` until the product is described
   ([../product/README.md](../product/README.md)).
