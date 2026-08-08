# Performance Audit Guide

## Use When

- Users notice slowness, freezes, battery drain, high memory, slow builds, or slow tests.
- A feature adds heavy queries, AI calls, media processing, or background work.
- Preparing for release or scale.

## Inputs

- Performance reports, diagnostics, logs, traces, benchmarks, and evals.
- Slow user flows and affected code paths.
- Database queries, network calls, background jobs, and caching.
- Build/test timings when developer workflow is the concern.

## Core Questions

- Which flow is slow, and how slow is it?
- Is the bottleneck measured or guessed?
- Is the cost CPU, memory, I/O, network, database, rendering, AI calls, or build tooling?
- Is the fix local, architectural, or product-scope?
- What benchmark would prove improvement?

## Checks

```bash
rg -n "performance|slow|timeout|cache|query|memory|background|benchmark" docs src .
```

Use platform profilers and logs where available.

## Finding Categories

- unmeasured performance claim
- slow query or network path
- excessive memory/CPU
- UI/rendering hitch
- repeated expensive work
- missing benchmark

## Routing Guidance

| Finding Looks Like | Route To |
|---|---|
| Need measurement/reproduction | `DIAG` or `EVAL` |
| Need compare alternatives | `EVAL` |
| Need implementation | `PLAN` / `IMPL` |
| Need architecture change | `ADR` |
| Need product requirement | `SPEC` |

## Done When

- Findings name evidence or explicitly say evidence is missing.
- Recommended fixes include a verification method.
