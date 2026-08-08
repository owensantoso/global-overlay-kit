---
type: implementation-brief
id: IMPL-0000-00
title: <Implementation brief title>
domain: product
status: draft
created_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
updated_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
planned_execution_start:
planned_execution_end:
actual_execution_start:
actual_execution_end:
parent_plan: PLAN-0000
task_refs: []
owner:
areas: []
depends_on: []
parallel_with: []
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

# IMPL-0000-00 - <Implementation Brief Title>

Use this for new `IMPL-*` docs. Keep it concrete enough for delegation, but do not turn it into a pseudo-patch.

File path:

```text
docs/<domain>/plans/PLAN-0000-<slug>/IMPL-0000-00-<slug>.md
```

Prefer `agent-continuity docs new impl "<title>" --plan PLAN-0000` when the repo has Agent Continuity document tooling; it will assign the next implementation ID scoped to the parent plan, fill timestamps and repo state, and create the brief beside its parent plan.

## Parent plan

- [PLAN-0000-plan-title.md](PLAN-0000-plan-title.md)

<Optional note if this brief intentionally groups multiple parent-plan tasks.>

## Tracking issue

- <GitHub sub-issue link, if created>

The issue tracks this execution slice. This brief owns the execution detail.

## Task goal

<What this bounded task or grouped task should accomplish, in plain language.>

After this task:

- <outcome>
- <outcome>
- <outcome>

## Scope

In scope:

- <owned work>
- <owned work>
- <owned work>

Out of scope:

- <explicit non-goal>
- <explicit non-goal>
- <explicit non-goal>

## Ownership

- Owns: <files, seams, or behavior this brief is responsible for>
- Adjacent briefs own: <nearby seams this brief must not absorb>
- Integration expectation: <whether this brief is standalone or expected to integrate parallel slices>

## Preserve

- <invariant or UX behavior that must not regress>
- <invariant or UX behavior that must not regress>
- <constraint from the parent plan>

## Dependencies / parallelization

- Depends on: <brief path(s), task numbers, or "parent-plan prerequisites only">
- Can run in parallel with: <brief path(s) or "none">
- Write-conflict notes: <which files or surfaces must stay disjoint if parallelized>

## Entry point

- Start from: `<primary file>`
- Main seam to extend: <repository, view model, settings seam, migration seam, service seam, etc.>

## Files to read first

- `<important file 1>`
- `<important file 2>`
- `<important file 3>`

## Files likely to change

Create:

```text
<new files>
```

Modify:

```text
<existing files>
```

## Execution steps

### 1. <Step title>

<Concrete instruction.>

### 2. <Step title>

<Concrete instruction.>

### 3. <Step title>

<Concrete instruction.>

### 4. <Step title>

<Concrete instruction.>

## Verification

Run:

```bash
<focused verification commands>
```

Also run if this task touches schema, settings storage, shared persistence, or integration plumbing:

```bash
<migration, reset, smoke, or broader verification commands>
```

Manual smoke if relevant:

- <manual check>
- <manual check>

## Risks / traps

- <common failure mode>
- <boundary or scope trap>
- <regression risk>

## Review focus

- Spec reviewer: <what to check for plan compliance>
- Code reviewer: <what quality or architecture risk to scrutinize>

## Done checklist

- Use structured `TODO-*` IDs here only when this brief needs durable cross-session or delegated progress tracking.
- [ ] <done condition>
- [ ] <done condition>

```markdown
- [ ] TODO-0001 [ready] [skill:<skill-name>] [plan:PLAN-0000] [brief:IMPL-0000-00] <durable coordination item, if needed>
```

- [ ] <verification complete>
