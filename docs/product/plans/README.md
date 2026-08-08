# Planning Docs Guide

This repo uses specs, plans, and implementation briefs on purpose.

Starter examples live here:

- `docs/IDEAS.md` and the repo's idea template
- `docs/SPECS.md` and the repo's spec template
- `docs/product/plans/PLAN-0000-plan-title/PLAN-0000-plan-title.md`
- `docs/product/plans/PLAN-0000-plan-title/IMPL-0000-00-implementation-brief-title.md`

Reusable implementation-session handoff prompt:

- `docs/repo-health/prompts/reusable-implementer-handoff-prompt.md`

If this repo has `agent-continuity docs`, use it for mechanical metadata:

```bash
agent-continuity docs next spec
agent-continuity docs next idea
agent-continuity docs next plan
agent-continuity docs next impl --plan PLAN-0000
agent-continuity docs new spec "<title>" --domain product --spec-type feature
agent-continuity docs new idea "<title>" --domain product
agent-continuity docs new plan "<title>" --domain product --spec SPEC-0000
agent-continuity docs new impl "<title>" --plan PLAN-0000
agent-continuity docs set-status PLAN-0000 in_progress
agent-continuity docs todos
agent-continuity docs update
agent-continuity docs check
agent-continuity docs roadmap --write
```

Do not ask agents to guess the next ID when the repo can derive it.

## Topic-first planning

Plans should live under the topic/domain that owns the work:

- `product/plans/` - user-facing product capability
- `repo-health/plans/` - docs, workflow, CI, test hygiene, maintainability
- `research/` - feasibility studies and spikes
- `operations/` - release, production, App Store, or manual operational work
- `marketing/` - launch and growth planning

Each meaningful plan should get its own folder:

```text
<domain>/plans/<plan-slug>/
  PLAN-0001-<slug>.md
  IMPL-0001-01-<slug>.md
```

The parent plan folder and parent plan file must both use the same uppercase
`PLAN-####-<slug>` identity:

```text
<domain>/plans/PLAN-0001-<slug>/PLAN-0001-<slug>.md
```

Do not name the parent plan `plan.md`. A generic filename breaks the stable
paper trail because commits, session logs, issues, generated views, and
implementation briefs refer to the `PLAN-####` ID.

Use the old flat file convention only when the repo intentionally chooses simpler docs.

## Source-of-truth stack

Use this hierarchy:

```text
IDEA -> SPEC -> PLAN -> IMPL -> Issues / PRs
```

- `IDEA` owns lightweight early capture: possible future work, rough product thoughts, and sparks that are not ready for requirements.
- `SPEC` owns durable requirements and language: what should be true and why.
- `PLAN` owns intent, architecture, scope, sequencing, dependencies, and validation strategy.
- `IMPL` owns bounded execution detail for one task or grouped slice.
- GitHub issues track approved work. They should link to specs, plans, and implementation briefs rather than replace them.
- PRs deliver one reviewable change and link back to the relevant issue/docs.

Specs and plans are versioned truth, not timeless truth. When a newer artifact
changes the meaning of an older one, record that relationship instead of letting
the docs silently disagree.

Full supersession:

- set the older doc's `status` to `superseded`
- add `superseded_by: [SPEC-0000]` or the relevant replacement doc
- add `supersedes: [SPEC-0000]` to the newer doc when applicable
- write one short note near the top of the older doc explaining why it was
  superseded

Partial supersession:

- keep the older doc active if most of it still applies
- add a short "Partial Supersession" or "Revision Notes" section naming the
  specific requirements, sections, or assumptions replaced by the newer doc
- link both directions in frontmatter where the schema supports it, or in the
  revision note when only prose is available
- when partial supersession becomes hard to reason about, split the still-valid
  requirement into a fresh spec or mark the old spec fully superseded

Prefer small, explicit revision notes over editing history until the old artifact
looks like it always knew the future.

## ID and filename conventions

Use independent IDs for specs and plans. Do not force plan numbers to match spec numbers.

```text
IDEA-0001
SPEC-0001
PLAN-0001
IMPL-0001-01
```

Recommended paths:

```text
docs/<domain>/ideas/IDEA-0001-<slug>.md
docs/<domain>/specs/SPEC-0001-<slug>.md
docs/<domain>/plans/PLAN-0001-<slug>/PLAN-0001-<slug>.md
docs/<domain>/plans/PLAN-0001-<slug>/IMPL-0001-01-<slug>.md
```

Relationships belong in frontmatter:

```yaml
sequence:
  roadmap: "3.5"
  sort_key: "003.005"
  lane: product
  after: [PLAN-0034]
promoted_to:
  - SPEC-0001
related_specs:
  - SPEC-0001
parent_plan: PLAN-0001
```

This keeps filenames readable while still supporting one-to-one, one-to-many, many-to-one, and no-spec plans.

## Roadmap order

`PLAN-*` IDs are stable identity after implementation history points at them. Before implementation starts, keep numeric IDs and execution order aligned; if order changes, move/renumber the docs rather than relying on hidden dependency interpretation.

Use `sequence` frontmatter for order:

```yaml
sequence:
  roadmap: "3.5.1"
  sort_key: "003.005.001"
  lane: product
  after: [PLAN-0035]
  before: [PLAN-0036]
```

Use `agent-continuity docs roadmap --write` to generate `docs/ROADMAP-VIEW.md` from plan frontmatter.

## Status and todos

Canonical status lives in frontmatter:

```yaml
status: draft
```

Allowed plan and implementation-brief statuses:

```text
draft
ready
in_progress
blocked
completed
superseded
archived
```

Use Markdown checkboxes for local task lists. Use structured `TODO-*` checkboxes only when work needs durable coordination across sessions, subagents, skills, commits, or reviews:

```markdown
- [ ] TODO-0001 [ready] [skill:docs-writer] [plan:PLAN-0002] Define stable todo lifecycle states.
```

Keep parent plans and implementation briefs authoritative for scope. Use `TODO-*` IDs for progress references, handoff, filtering, and closeout. `agent-continuity docs todos` derives a repo-level task view without making a second source of truth.
`skill:<name>` is a routing hint only. It does not imply that a matching Codex skill is installed in every environment.

Agent Continuity does not scan source-code TODO comments. Keep those comments for local implementation notes. Promote an in-file TODO to a structured Markdown `TODO-*` when it needs ownership, delegation, review, or cross-session tracking.

Place structured todos in the lowest durable doc that owns the work:

| Work shape | Put the `TODO-*` in |
|---|---|
| Milestone, dependency, or cross-brief progress | Parent plan |
| One bounded execution slice | Implementation brief |
| Operational checklist, repo-health pass, or temporary maintenance queue | Checklist, state, audit, or repo-health doc |
| Inline code TODO that now needs ownership or review | Promote it to the related plan or brief |

When claiming a `TODO-*`, add `owner:`, `agent:`, and `updated:` on the source checkbox line. Use `owner:` for accountability and `agent:` for the exact runner/session ID when available.

## The planning layers

### 1. Ideas

Ideas preserve sparks before they are ready to become specs, research notes, ADRs, or plans.

They define:

- the raw thought
- why it might matter
- possible shape
- unresolved questions
- promotion criteria

They should answer:

> What should we not lose, even if it is not ready to act on?

They should stay lightweight and cheap to capture.

### 2. Specs

Specs define durable requirements before implementation planning. They may describe features, bugs, improvements, architecture, repo-health work, or research-backed decisions.

They define:

- the user/system/workflow problem
- goals and non-goals
- user stories, primary flows, bug evidence, or improvement target shape
- requirements and edge behavior
- open questions
- architecture or data implications
- test expectations

They should answer:

> What should be true, for whom, and why?

They should not define task sequencing or become a pseudo-plan.

### 3. Architecture or milestone plans

These are the main plan docs.

They define:

- the goal of a milestone or phase
- architectural boundaries
- sequencing
- task dependencies and safe parallelization opportunities
- invariants
- non-goals or out-of-scope work
- the review standard for the work

They should answer:

> What are we trying to achieve, what shape should the solution have, and what must not be violated while we do it?

They should not try to fully pre-author every code edit or turn into a pseudo-patch.

### 4. Implementation briefs

Files named like:

```text
IMPL-<plan-id>-<sequence>-<slug>.md
```

These are execution docs for one bounded task or grouped task.

They define:

- exact task scope
- explicit dependencies and parallelization notes
- files likely to change
- concrete execution steps
- verification commands
- edge cases and traps
- handoff notes useful to a smaller model or subagent

They should answer:

> For this bounded task, what should the implementer do next, in what order, and how do we know it is done?

## Relationship between the two

The important rule is:

> The spec defines requirements truth. The parent `PLAN-*` doc defines intent and boundaries. The `IMPL-*` brief defines execution details for one bounded slice.

If both exist:

- spec wins on requirements, user promises, bug expectations, and target behavior
- plan wins on product intent, scope, architecture, and non-goals
- implementation brief wins on execution order and verification details

If they disagree, update the lower-level artifact or explicitly revise the higher-level source of truth.

Never implement from an `impl-*` brief alone if the parent plan exists and has not been read.

## When to create an implementation brief

Create one when:

- a task is large enough that execution order matters
- a subagent or smaller model could implement it independently
- the main plan would become noisy if it included all the detail
- the work has tricky verification or migration steps
- resumability across sessions or worktrees would help

Do not create implementation briefs for every tiny task by default.

Implementation briefs are optional. A parent plan can be directly executable
when the scope is small, the file ownership is obvious, the verification path is
simple, and there is no need to delegate or resume multiple independent slices.
In that case, keep the plan's implementation tasks and validation sections clear
enough for execution and skip separate `IMPL-*` files.

Add implementation briefs later if the work grows, needs subagents, develops
tricky ordering or verification, or starts accumulating enough local checklist
detail that the parent plan becomes noisy.

## Recommended structure

### Frontmatter

New parent plans and implementation briefs should start with YAML frontmatter.

Use frontmatter for metadata that future tools or Obsidian-style workflows may query:

- `type`: `plan` or `implementation-brief`
- `domain`: `product`, `repo-health`, `research`, `operations`, or `marketing`
- `status`: `draft`, `ready`, `in_progress`, `blocked`, `completed`, `superseded`, or `archived`
- `created_at`: exact local creation timestamp
- `updated_at`: exact local last meaningful update timestamp
- `planned_execution_start` / `planned_execution_end`: intended execution window, if known
- `actual_execution_start` / `actual_execution_end`: filled when execution actually begins/finishes
- `related_specs`, `related_adrs`, `related_sessions`: links to source docs and receipts
- `linked_paths`: repo-relative files or folders that matter to the work but are not structured docs

For implementation briefs, also include:

- `parent_plan`
- `task_refs`
- `depends_on`
- `parallel_with`

Leave unknown fields blank rather than inventing dates or links.

### GitHub issues

When GitHub issues are used:

- parent issues usually track a parent plan or approved work package
- sub-issues usually track implementation briefs or independently grabbable slices
- decision sub-issues track unresolved choices
- investigation sub-issues track ambiguity reduction
- issues should link to the source docs in a paper trail
- issue bodies and PR descriptions may cite `TODO-*` IDs for progress references, but should still link the parent plan or implementation brief as the scope authority

Do not make issues the only memory system when specs, plans, or implementation briefs exist.

### Main plan

Recommended sections:

- Goal
- Architecture
- Prerequisites
- Why now
- Product decisions
- Design rules or invariants
- Task dependencies and parallelization
- Out of scope
- File structure
- Implementation tasks
- Validation
- Completion criteria

### Implementation brief

Recommended sections:

- Parent plan
- Task goal
- Scope and non-goals
- Ownership
- Preserve
- Dependencies and parallelization
- Entry point
- Files to read first
- Files likely to change
- Execution steps
- Verification
- Risks and traps
- Review focus
- Done checklist

## Naming conventions

Folder-based plan:

```text
<domain>/plans/PLAN-0001-<slug>/PLAN-0001-<slug>.md
```

Implementation briefs:

```text
<domain>/plans/PLAN-0001-<slug>/IMPL-0001-01-<slug>.md
```

Use `<sequence>` to keep briefs ordered within a parent plan:

- first brief: `01`
- second brief: `02`
- grouped brief for related tasks: choose the next sequence and explain the grouped scope in the brief

## Grouping guidance

Group tasks into one brief when:

- they share one seam or hot file set
- they should land together to avoid churn
- they have one verification bundle
- splitting them would create a temporary invalid state

Split tasks when:

- ownership is disjoint
- they can run in parallel
- they have different verification paths
- combining them would make the brief vague or conflict-prone
