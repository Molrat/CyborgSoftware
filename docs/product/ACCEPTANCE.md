# Acceptance scenarios

The end-to-end behaviour the product must demonstrably do. These are the
scenarios the product is accepted on. Each one is also the source of gate checks
— see [../roadmap/](../roadmap/).

**How these relate to the test suite.** [../TESTING.md](../TESTING.md) caps the
e2e layer at roughly 5–10 tests proving golden paths and cross-service concerns.
Only a scenario that genuinely needs the whole stack earns one of those; the rest
are domain and persistence behaviour and belong at the component layer, where
they run against a real Postgres without the browser, or are a person's journey
and belong to the browser layer. **The `Verified at` row is binding** — the same
behaviour is not asserted twice, and the `tester` agent checks it before adding
anything.

## Scenario format

```
## `ACC-A` — <short name>

**Proves** what this scenario demonstrates, in one sentence.
**Verified at** <one layer> (`tests/<layer>/`) · gate: <sub-phase id>.

**Preconditions**: the accounts, roles and data that must exist.

**Steps**

1. <actor> does <action>.
2. …

**Must prove**

- <an observable outcome>, citing the product document that requires it.
```

---

*(No scenarios yet — they are written as the product is described, and a
sub-phase cites the ones its gate binds to.)*
