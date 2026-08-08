# Roadmap Alignment Audit Guide

## Use When

- Existing plans or specs predate a newer roadmap.
- Multiple plans compete for next priority.
- Implementation order may make the desired future model harder.
- A milestone has drifted from current state or north-star direction.

## Inputs

- Current state docs.
- Roadmap docs.
- Active and ready plans.
- Relevant specs, ADRs, and concepts.
- Generated roadmap or registry views, if available.

## Core Questions

- Does each active plan still move the repo toward the roadmap?
- Does any plan assume an older domain model or naming system?
- Are dependencies and sequencing still correct?
- Are there plans that should be superseded, merged, split, or deferred?
- Is the next implementation slice still the best next slice?

## Checks

```bash
agent-continuity docs recent
agent-continuity docs roadmap
agent-continuity docs health
```

Use equivalent checks when Agent Continuity document tooling is unavailable.

## Finding Categories

- stale plan
- roadmap conflict
- missing dependency
- wrong sequence
- duplicate plan
- plan too broad
- current-state mismatch

## Routing Guidance

| Finding Looks Like | Route To |
|---|---|
| Plan needs minor status or note update | direct edit or `TODO` |
| Old plan conflicts with current roadmap | update/supersede `PLAN` |
| Roadmap itself is ambiguous | `QST` or `CONC` |
| Durable sequencing decision is needed | `ADR` |
| Behavior contract changed | `SPEC` |

## Done When

- Every active or ready plan reviewed has one of: aligned, needs update, superseded, deferred.
- Findings are routed to concrete follow-up artifacts or explicitly accepted.
