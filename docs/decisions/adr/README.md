# Architecture Decision Records

Architecture decision records capture durable product/data-model/system decisions that later plans should honor or explicitly supersede.

Use ADRs for decisions that are expected to outlive one implementation task or affect multiple future plans. Do not use ADRs for routine execution notes, small UI choices, or one-off implementation details; use plans, implementation briefs, session logs, or learnings for those.

Start new ADRs from the nearby `ADR-0000-decision-title.md` example or with `agent-continuity docs new adr "<title>"`.

New ADRs should start with YAML frontmatter:

- `type: adr`
- `id: ADR-####`
- `title`
- `domain`
- `status`: `proposed`, `accepted`, `superseded`, or `archived`
- `created_at` and `updated_at`
- `areas`
- `deciders`
- `related_specs`, `related_plans`, `related_briefs`, `related_sessions`, `related_issues`, and `related_prs`
- `supersedes` and `superseded_by`

## When To Create Or Update An ADR

Create or update an ADR when a decision:

- changes the canonical product/data model
- sets a cross-surface architecture boundary
- affects sync, auth, security, persistence, or migration strategy
- resolves a meaningful alternative that future contributors may otherwise reopen
- supersedes a previous durable decision

Keep each ADR focused on one decision. Link to the relevant spec, plan, implementation brief, and session log instead of copying their full content.

## Decision Index

| Decision | Status | Supersedes / superseded by | Related docs |
|---|---|---|---|
| <decision> | Proposed | None | <links> |

## ADR Candidates

- <decision documented elsewhere that may deserve an ADR later>
