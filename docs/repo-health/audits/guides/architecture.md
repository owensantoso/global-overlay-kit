# Architecture Audit Guide

## Use When

- Code boundaries feel blurry.
- Features are crossing layers unexpectedly.
- Ownership, interfaces, or dependencies may have drifted.
- New plans may require architectural guardrails.

## Inputs

- Architecture overview and area docs.
- ADRs touching boundaries or dependencies.
- Code ownership maps, generated symbol maps, or module diagrams.
- Active plans that touch multiple areas.

## Core Questions

- What are the intended boundaries?
- Which dependencies violate or strain those boundaries?
- Are public interfaces clear enough for future work?
- Are there duplicate patterns that should become shared infrastructure?
- Is the architecture doc describing reality or aspiration?

## Checks

```bash
rg -n "TODO|FIXME|temporary|legacy" .
```

Also use language-specific dependency or symbol tools when available.

## Finding Categories

- boundary violation
- hidden coupling
- unclear ownership
- duplicated implementation pattern
- missing interface
- architecture doc drift

## Routing Guidance

| Finding Looks Like | Route To |
|---|---|
| Needs durable boundary decision | `ADR` |
| Needs architecture language/model | `CONC` or architecture doc |
| Needs behavior change | `SPEC` |
| Needs implementation/refactor | `PLAN` / `IMPL` |
| Needs evidence of runtime failure | `DIAG` |

## Done When

- Findings distinguish actual defects from future refactor ideas.
- Any recommended refactor explains why the current model cannot support the next work safely.
