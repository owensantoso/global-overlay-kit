# Paper Trail Audit Guide

## Use When

- Work history is hard to reconstruct.
- Commits, session logs, plans, specs, and generated views disagree.
- A repo needs handoff clarity before another agent continues.

## Inputs

- Recent commits.
- Session logs.
- Plans, implementation briefs, specs, ADRs, and generated registries.
- PRs/issues if the repo uses them.
- Current state docs.

## Core Questions

- Can a future reader tell what changed and why?
- Do commits reference the relevant plan/spec/session?
- Are completed tasks marked complete in the owning docs?
- Are generated views current after doc changes?
- Are there orphaned plans, TODOs, or session logs that matter?

## Checks

```bash
git log --oneline --decorate -20
agent-continuity docs recent
agent-continuity docs todos --all
```

Use equivalent commands when unavailable.

## Finding Categories

- missing session receipt
- stale plan checkbox
- missing commit trailer
- generated view drift
- duplicate or orphan work record
- unclear handoff state

## Routing Guidance

| Finding Looks Like | Route To |
|---|---|
| Small metadata/doc fix | direct edit or `TODO` |
| Missing durable decision | `ADR` |
| Missing implementation scope | `PLAN` / `IMPL` |
| Confusing workflow lesson | `LRN` |
| Unknown actual state | `DIAG` or current-state review |

## Done When

- The audit says where the next agent should start.
- Important completed work has a receipt and generated views are current.
