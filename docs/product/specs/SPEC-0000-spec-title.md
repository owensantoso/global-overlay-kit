---
type: spec
id: SPEC-0000
title: <Spec title>
spec_type: feature
domain: product
status: draft
created_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
updated_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
owner:
source:
  type: conversation
  link:
  notes:
areas: []
related_plans: []
related_issues: []
related_prs: []
related_adrs: []
related_sessions: []
linked_paths: []
supersedes: []
superseded_by: []
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# SPEC-0000 - <Spec Title>

Use this for durable product, system, bug, architecture, or repo-health requirements before implementation planning. A spec explains what should be true and why. It is not an implementation plan.

File path:

```text
docs/<domain>/specs/SPEC-0000-<slug>.md
```

Register this spec in `docs/SPECS.md`.

Prefer `agent-continuity docs new spec "<title>"` when the repo has Agent Continuity document tooling; it will assign the next `SPEC-####`, fill timestamps and repo state, and place the file in the topic-first specs folder.

## Summary

<one paragraph on the outcome and why it matters>

## Problem / Opportunity

- <problem, bug, friction, or opportunity>
- <evidence or origin>

## Goals

- <goal>
- <goal>
- <goal>

## Non-Goals

- <explicit non-goal>
- <explicit non-goal>

## Users / Actors

- <actor, system, maintainer, or agent>
- <actor, system, maintainer, or agent>

## Current Behavior / Context

- <what exists today>
- <relevant current constraint>

## Desired Behavior / Target State

- <what should be true when this spec is satisfied>
- <what should be preserved>

## Requirements

- <functional, technical, workflow, or quality requirement>
- <functional, technical, workflow, or quality requirement>

## Type-Specific Notes

Use only the subsections that fit the `spec_type`.

### Feature

- User stories:
- Entry points:
- Primary flow:
- Edge behavior:

### Bug

- Observed behavior:
- Expected behavior:
- Reproduction / evidence:
- Regression risk:

### Improvement

- Current pain:
- Target shape:
- Safe migration path:
- Cleanup boundaries:

### Architecture

- Ownership boundary:
- Interfaces / seams:
- Alternatives considered:
- ADR needed:

### Repo Health

- Workflow/tooling impact:
- Maintenance rule:
- Rollout:

## Domain Language

- `<term>` means <canonical meaning>.
- Avoid `<ambiguous term>` because <reason>.

## Architecture / Data Implications

- <new seam>
- <changed seam>
- <related `AREA-*` doc, if the repo uses architecture areas>
- <new or changed caller-facing interface, if known>

## Open Questions

- <question that still needs product, technical, or workflow resolution>

## Test / Validation Expectations

- <externally visible behavior or workflow that should be tested>
- <module, seam, migration, or flow that should have coverage>
- <manual or automated validation expected before closeout>

## Paper Trail

| Type | Link / Value | Role |
|---|---|---|
| Source |  | origin of the spec |
| Plan |  | build strategy, when created |
| Issue |  | tracking container, when created |
| ADR |  | durable decision |
| Session |  | work receipt |

The spec owns truth and requirements. Plans own execution strategy. Area docs own durable architecture boundaries and interfaces. Issues own tracking.
