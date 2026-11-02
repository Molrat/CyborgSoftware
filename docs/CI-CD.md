# CI / CD

> **Status: `[SPEC]` — nothing built.** No workflow exists, and there is no
> deployment target yet. This page is the design to build towards; each stage is
> marked the same way [architecture/](architecture/) marks its sections, so the
> page never claims a stage that does not run.

> `[OPEN]` Where it deploys (a VPS, a container host, a cloud service), whether
> there is a staging environment, and which registry holds images. Decided with
> the user before the first deployment sub-phase — each is an architectural
> decision (root `CLAUDE.md` rule 3).

---

## Principles

1. **The pipeline runs what a developer runs.** CI calls
   [`run-tests.ps1`](../run-tests.ps1), the same entry point used locally. No
   parallel CI-only test invocation that can drift.
2. **Fast feedback first.** Cheap layers gate expensive ones. A compile error
   should not wait on a Postgres container.
3. **Skipping is a lie in CI.** `run-tests.ps1` deliberately *skips* layers whose
   prerequisites are missing. That's right for a laptop and wrong for CI, where
   a skipped layer must be treated as a failure — so CI asserts its
   prerequisites are present before invoking it.
4. **Build once, promote the same artifact.** Images are built one time and moved
   between environments by tag. Never rebuilt per environment.
5. **`main` is always releasable** — enforced by the pipeline, not hoped for
   from the people merging.

**Build the test stages before the deploy stage.** A pipeline that deploys
before it tests ships whatever is merged, and every count in
[TESTING.md](TESTING.md) becomes a claim nothing checks.

---

## Pipeline stages

```
  push / PR
      │
      ▼
┌─────────────────┐
│ 1. Lint & build │  dotnet build (warnings = errors) · vue-tsc · npm run build
└────────┬────────┘  ~2 min · no services needed            [SPEC]
         │
         ▼
┌─────────────────┐
│ 2. Unit + FE    │  run-tests.ps1 -Unit -Frontend
└────────┬────────┘  no Docker                              [SPEC]
         │
         ▼
┌─────────────────┐
│ 3. Component    │  run-tests.ps1 -Component   (Testcontainers → needs Docker)
└────────┬────────┘                                         [SPEC]
         │
         ▼
┌─────────────────┐
│ 4. Image build  │  docker compose build · tag with git SHA
└────────┬────────┘                                         [SPEC]
         │
         ▼
┌─────────────────┐
│ 5. E2E + browser│  compose up -d → run-tests.ps1 -E2E -Browser → compose down -v
└────────┬────────┘  the built images, not a rebuild        [SPEC]
         │
         ▼
┌─────────────────┐
│ 6. Publish      │  push images to the registry   (main only)
└────────┬────────┘                                         [SPEC]
         │
         ▼
┌─────────────────┐
│ 7. Deploy       │  promote the published tag
└─────────────────┘                                         [SPEC]
```

### What runs when

| Trigger | Stages |
|---|---|
| Pull request | 1 → 5 |
| Push to `main` | 1 → 7 |
| Tag `v*` | 6 → 7, re-deploying a known-good tag (the rollback path) |

Stages 1–3 are the PR gate that must stay under about five minutes; anything
slower gets worked around by developers, and a gate that gets worked around is
not a gate.

---

## Secrets and configuration

- Secrets never enter the repository. `.env` is git-ignored; `.env.example`
  lists every variable with a `change_me_*` placeholder.
- Production secrets are generated **on the target**, so they never transit
  anywhere else.
- CI holds only what it needs to reach the target, scoped as narrowly as the
  platform allows.

---

## Database migrations in the pipeline

Migrations are **not** run by CI against a live environment. They run the way
they run locally: the `*-db-migrations` container executes on stack start, and
`depends_on: service_completed_successfully` holds the API back until schema is
in place. Deploying a new image set therefore migrates as a side effect of
starting it, in the correct order, with no separate migration step to forget.

Two consequences worth stating plainly:

- **Migrations must be backward compatible with the currently-running image**
  for the duration of a deploy. Add a column, backfill, then drop the old one in
  a later release — never rename in one step.
- **`*-db-procedures` redeploys every function on every start.** Functions are
  therefore always in sync with the deployed code, but a function signature
  change is a breaking change for any older API instance still running.

---

## Rollback

Re-deploy the previous image tag. Because migrations are forward-only and
backward compatible with the previous image, the old image runs against the new
schema; a migration is never rolled back by hand.
