# Docs Health Audit Guide

## Use When

- Documentation, generated views, links, templates, or metadata may be stale.
- A repo has had many agent sessions and needs cleanup.
- Before starting a large planning or implementation session.

## Inputs

- Root agent index.
- Docs README and generated views.
- Specs, plans, ADRs, session logs, questions, concepts, and templates.
- Metadata scripts and smoke tests.

## Core Questions

- Can a new agent find the right starting point?
- Are generated views current?
- Are links valid and useful?
- Are stale or duplicate docs creating confusion?
- Are templates and scripts aligned with the documented workflow?

## Checks

```bash
agent-continuity docs check
agent-continuity docs check-links
agent-continuity docs check-todos
agent-continuity docs health
```

Use equivalent checks if the target repo lacks Agent Continuity document tooling.

## Finding Categories

- stale generated view
- broken link
- orphan doc
- missing template
- conflicting instructions
- stale current-state doc
- unclosed session or TODO

## Routing Guidance

| Finding Looks Like | Route To |
|---|---|
| Small doc/tool fix | direct edit or `TODO` |
| Workflow confusion | `CONC`, `LRN`, or guide update |
| Missing requirement | `SPEC` |
| Larger docs migration | `PLAN` / `IMPL` |
| Unclear root cause | `DIAG` |

## Done When

- Generated docs are current or stale outputs are explicitly deferred.
- Every meaningful finding is fixed, routed, deferred, or accepted.
