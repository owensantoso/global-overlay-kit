# Test Coverage Audit Guide

## Use When

- A plan/spec says behavior is guaranteed, but test coverage is uncertain.
- A bug escaped and similar behavior may be untested.
- Before refactoring shared or risky code.
- Before release or handoff.

## Inputs

- Specs, plans, implementation briefs, and acceptance criteria.
- Test files and test commands.
- CI configuration and recent failures.
- Diagnostics for recent bugs.

## Core Questions

- What behavior is promised?
- Which promises are covered by automated tests?
- Which promises are covered only manually?
- Which high-risk paths have no verification?
- Are tests too brittle, slow, or disconnected from user behavior?

## Checks

```bash
rg -n "Verification|Acceptance|Test|TODO|Not run" docs
```

Run repo-specific test discovery and coverage tools when available.

## Finding Categories

- missing test
- weak assertion
- manual-only critical path
- flaky or slow test
- untracked not-run item
- outdated verification command

## Routing Guidance

| Finding Looks Like | Route To |
|---|---|
| Need add tests | `PLAN` / `IMPL` or `TODO` |
| Need reproduce bug | `DIAG` |
| Need define acceptance criteria | `SPEC` |
| Need compare test strategies | `EVAL` |
| Need update docs command | direct edit |

## Done When

- High-risk gaps are routed or explicitly accepted.
- Verification commands in docs match reality.
