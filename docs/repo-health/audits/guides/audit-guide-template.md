# <Audit Kind> Audit Guide

Use this template when adding a new reusable audit kind guide.

## Use When

-

## Inputs

Read only the inputs needed for this audit kind.

- Repo-local audit profile, if present:
- Canonical docs:
- Generated views:
- Code or config surfaces:
- Tests or verification logs:

## Core Questions

-

## Checks

Commands, searches, or manual review passes that usually apply:

```bash

```

## Finding Categories

-

## Routing Guidance

| Finding Looks Like | Likely Route |
|---|---|
| Clear small fix | `TODO` or direct edit |
| Needs reproduction or runtime evidence | `DIAG` |
| Needs options research | `RSCH` or `EVAL` |
| Needs durable decision | `ADR` |
| Needs behavior contract | `SPEC` |
| Needs implementation work | `PLAN` / `IMPL` |

## Done When

- Every finding is resolved, routed, deferred, accepted as risk, or archived.
- The audit records what was in scope and out of scope.
- Follow-up artifacts are linked from the finding register.
