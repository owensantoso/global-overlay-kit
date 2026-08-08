---
type: plan
id: PLAN-0000
title: <Plan title>
domain: product
status: draft
created_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
updated_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
planned_execution_start:
planned_execution_end:
actual_execution_start:
actual_execution_end:
owner:
sequence:
  roadmap: "0.0"
  sort_key: "000.000"
  lane: product
  after: []
  before: []
areas: []
related_specs: []
related_adrs: []
related_sessions: []
related_issues: []
related_prs: []
linked_paths: []
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# PLAN-0000 - <Plan Title>

Use this for new parent `PLAN-*` docs. Keep it architectural and milestone-oriented. Point detailed execution into `IMPL-*` briefs when useful. If there is a source spec, treat that spec as requirements truth and link it in frontmatter.

File path:

```text
docs/<domain>/plans/PLAN-0000-<slug>/PLAN-0000-<slug>.md
```

Do not use `plan.md` for parent plans. The folder and file must both carry the
same uppercase `PLAN-####` ID and slug.

Prefer `agent-continuity docs new plan "<title>" --spec SPEC-0000` when the repo has Agent Continuity document tooling; it will assign the next `PLAN-####`, fill timestamps and repo state, and create the topic-first plan folder.

**Goal:** <One paragraph on the user-facing or system outcome.>

**Architecture:** <Why this plan exists, what shape the solution should have, and what layer it belongs to.>

**Tech Stack:** <Relevant stack for this plan only.>

**Architecture Areas:** <List `AREA-*` IDs from `docs/architecture/areas/`, if the repo uses area docs.>

**Source Spec:** <SPEC ID or link, if this plan implements an approved spec.>

---

## Prerequisites

- <completed milestone or required seam>
- <required doc or spec dependency>

## Why Now

- <why this should happen now in the roadmap>
- <why delaying it would create pain or drift>

## Product Decisions

- <decision>
- <decision>
- <decision>

## Domain Model / Interfaces

- Domain terms to preserve: `<term>`, `<term>`
- New or changed interfaces: `<interface or seam>`
- Related area docs: `AREA-<NAME>`

## Design Rules

- <invariant to preserve>
- <another invariant>
- <behavior or UX rule that must not regress>

## Task Dependencies / Parallelization

- <which tasks are foundational and must go first>
- <which tasks can run in parallel after that foundation>
- <which tasks are doc or closeout follow-through and should finish last>
- Net: <one-sentence execution shape>

## Out Of Scope

- <explicit non-goal>
- <explicit non-goal>
- <explicit non-goal>

## File Structure

Likely create:

```text
<new files or seams>
```

Likely modify:

```text
<existing files or seams>
```

## Implementation Tasks

Use structured `TODO-*` checkboxes only for durable cross-session coordination. Keep small local checklist items as ordinary Markdown checkboxes.

### Task 1: <Task title>

**Goal:** <one-sentence task goal>

- <what it should do>
- <what it should preserve>
- <what it should avoid>

Dependencies / parallelization:

- Depends on: <task numbers or "prerequisites only">
- Can run in parallel with: <task numbers or "none">
- Notes: <ownership split or why it is coupled>

Durable todo, if needed:

```markdown
- [ ] TODO-0001 [ready] [skill:<skill-name>] [plan:PLAN-0000] <coordination task>
```

### Task 2: <Task title>

**Goal:** <one-sentence task goal>

- <what it should do>
- <what it should preserve>
- <what it should avoid>

Dependencies / parallelization:

- Depends on: <task numbers>
- Can run in parallel with: <task numbers or "none">
- Notes: <ownership split or why it is coupled>

### Task N: <Task title>

**Goal:** <one-sentence task goal>

- <what it should do>
- <what it should preserve>
- <what it should avoid>

Dependencies / parallelization:

- Depends on: <task numbers>
- Can run in parallel with: <task numbers or "none">
- Notes: <ownership split or why it is coupled>

## Validation

- <build or generation command>
- <focused tests>
- <full suite or migration checks>
- <manual smoke if needed>

## Completion Criteria

- <observable finished condition>
- <observable finished condition>
- <architecture or invariant condition>

## Issue Tracking

- Parent issue: <link, if created>
- Sub-issues: <links, if created>

Issues track this plan. They do not replace the plan or implementation briefs.
