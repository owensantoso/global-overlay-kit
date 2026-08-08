# Schema Audit Guide

## Use When

- Persistence, migrations, generated types, sync, or data ownership may be drifting.
- A domain model change might require schema evolution.
- App code and database shape may disagree.

## Inputs

- Migrations and schema source of truth.
- Generated types.
- Domain models and repositories.
- Sync logic.
- Specs, ADRs, and plans that mention data shape.

## Core Questions

- What is the schema source of truth?
- Do code models match migrations and generated types?
- Are derived fields clearly marked as derived?
- Are migrations ordered and reversible enough for the project stage?
- Are privacy/security constraints represented in schema and policy?

## Checks

```bash
rg -n "migration|schema|model|repository|sync" docs
```

Run repo-specific migration/type generation checks when available.

## Finding Categories

- schema/code drift
- missing migration
- generated type drift
- unclear source of truth
- unsafe migration assumption
- sync contract mismatch

## Routing Guidance

| Finding Looks Like | Route To |
|---|---|
| Need decide data model | `ADR` or `CONC` |
| Need define data behavior | `SPEC` |
| Need migration/code work | `PLAN` / `IMPL` |
| Need runtime reproduction | `DIAG` |
| Need external comparison | `RSCH` / `EVAL` |

## Done When

- Every schema risk points to its owning source of truth.
- Follow-ups distinguish design decisions from migration tasks.
