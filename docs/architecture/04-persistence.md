# Persistence

Plain SQL, stored functions, and Dapper. No ORM, no EF Core, no code-first
migrations.

| Section | Status |
|---|---|
| The two-container pattern, migration and function conventions, privilege model, Dapper access | `[SPEC]` — decided; nothing built |
| [Data isolation](#data-isolation-is-a-schema-property) | `[SPEC]` — the mechanism is decided; **whether the system is multi-tenant is `[OPEN]`** |

Markers are defined in [README.md](README.md#status-markers).

## Two containers per database

Each database gets exactly two one-shot containers, and they do different jobs:

| Container | Runs | Idempotency |
|---|---|---|
| `*-db-migrations` | Versioned schema files `V###__description.sql`, in `sort -V` order | Tracked in `schema_migrations`; each version applies once, ever |
| `*-db-procedures` | Every `procedures/**/*.sql` | Recreates **all** functions on **every** start |

Both exit 0 and are chained ahead of the API with
`depends_on: condition: service_completed_successfully`.

### Why functions redeploy every time

Because it removes drift as a category of bug. The repository is the only source
of truth for a function body — there is no "someone patched production by hand"
state to reconcile. These files are the desired state, and `CREATE OR REPLACE`
makes re-running them safe, so **editing a function file in place is the normal
way to change it** — the opposite of a migration. It also means the app user can
hold `EXECUTE` rights without ever holding DDL rights.

### Why migrations are append-only

An applied migration is history. Editing one means the database that already ran
it and a database created fresh no longer agree, and nothing detects that. Fix
forward: add `V00N+1`.

**The runner decides what to run by the version number parsed from the
filename**, not a checksum of the contents. Edit an applied file and every
database that already ran it skips the change forever, a fresh database gets the
new body, and both report the version as applied. Flyway would catch that with a
checksum mismatch; a plain runner does not — so the rule is enforced
mechanically: [`block-applied-migration.sh`](../../.claude/hooks/block-applied-migration.sh)
refuses the edit.

### Writing a migration

- `V###__lower_snake_description.sql`, next free number, never a reused one.
- `${APP_USER}` is substituted by the runner from the environment, so the same
  file works under compose and Testcontainers.
- A header comment says *why* the change is shaped this way — the reasoning a
  reader cannot recover from the DDL.
- **Backward compatible with the image still running** during a deploy: add a
  column, backfill, then drop the old one in a later release — never rename in
  one step ([../CI-CD.md](../CI-CD.md#database-migrations-in-the-pipeline)).

## Stored function conventions

All reads and writes go through PostgreSQL functions named `sp_<table>_<verb>`,
one per file, under `db-procedures/procedures/<table>/`.

```sql
CREATE OR REPLACE FUNCTION sp_order_get_by_id(
    p_tenant_id UUID,          -- the isolation parameter, if the system has one — always first
    p_id        UUID
) RETURNS TABLE (id UUID, reference TEXT, status TEXT, row_version INTEGER)
LANGUAGE plpgsql
AS $$ ... $$;

GRANT EXECUTE ON FUNCTION sp_order_get_by_id(UUID, UUID) TO ${APP_USER};
```

- Parameters are prefixed `p_`, locals `v_`.
- Every file ends with its own `GRANT EXECUTE ... TO ${APP_USER}` — forget it and
  the endpoint fails at runtime, not at deploy.
- Explicit column lists — never `SELECT *` in a function returning a table.
- **A function whose writes can arrive late or twice is guarded on the current
  status**, so a duplicate is a no-op rather than a regression.

**Signature changes are breaking changes.** `CREATE OR REPLACE` cannot change a
function's parameter list, so a changed signature leaves the old overload behind,
still resolvable. Drop it explicitly in the same file (`DROP FUNCTION IF EXISTS`
with the old signature, first). A stale overload is a second, unmaintained path
to the same table.

## Data isolation is a schema property

> `[OPEN]` **Is the system multi-tenant** — several organisations' data in one
> database — or are there other boundaries (per user, per team) that a caller
> must never cross? Decided with the user before the first table that holds
> such data. The mechanism below applies to whatever boundary is chosen.

If data is separated, every such table carries the boundary column (e.g.
`tenant_id UUID NOT NULL`), and **every stored function that reads or writes one
takes the boundary parameter and filters on it**. Not the repository. Not the
service. The function.

```sql
    WHERE o.id = p_id
      AND o.tenant_id = p_tenant_id;   -- never optional
```

The reason it is pushed this far down rather than applied in C#: a forgotten
service-layer filter is one missing `WHERE` clause away from returning another
customer's data, and **nothing detects it** — the response is well-formed, the
status is 200, the tests pass. As a mandatory parameter it cannot be forgotten
silently; the call does not compile or the row does not come back.

Consequences that follow from it:

- **The boundary parameter is the first parameter**, by convention, so its
  absence is visible at a glance in a diff.
- **A function returning boundary-bearing rows without filtering on it is a
  defect**, even when every current caller happens to pass a correct id. The
  guarantee is the function's, not the caller's.
- Index scoped lookups leading with the boundary column.
- **Rows never change boundary.** No function updates `tenant_id`.
- Another party's row reads as **404, never 403** — a 403 confirms it exists.
- **Exceptions are deliberate and recorded** — shared reference data, a
  background worker processing every tenant's queue — each explained in its
  migration's header. A new exception is a decision, not an omission.

The component test layer is what makes this real: same request, two parties, one
gets its data and the other gets a 404 ([../TESTING.md](../TESTING.md)).

## The privilege model

The database superuser owns schema and runs migrations. The application connects
as a separate, lower-privileged user (`APP_USER`) that has:

- `EXECUTE` on the stored functions
- the table rights those functions need
- **no** DDL rights

So a compromised API cannot alter schema.

## Data access from C#

```csharp
public sealed class OrderRepository(ISqlDataAccess db) : IOrderRepository
{
    public async Task<Order?> GetById(Guid tenantId, Guid id, CancellationToken ct)
        => (await db.LoadData<OrderRow>("sp_order_get_by_id",
               new { TenantId = tenantId, Id = id }, ct)).FirstOrDefault()?.ToDomain();
}
```

`Dapper.DefaultTypeMap.MatchNamesWithUnderscores = true` is set once at startup,
so `created_by_user_id` maps to `CreatedByUserId` without attributes. JSONB
columns go through registered type handlers in `Shared.Infrastructure`, and are
converted into Domain values in `Data`
([backend-patterns.md](backend-patterns.md#who-adapts-to-whom)).

**Renames must move together.** A column rename touches the migration, every
stored function that names it, and every C# property bound to it. The component
test layer is what proves all three agree.
