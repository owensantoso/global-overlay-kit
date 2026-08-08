---
type: repo-health-audit
id: AUDT-0000
title: Repo Health Audit
status: planned
audit_kind: docs-health
audit_guide: docs/repo-health/audits/guides/docs-health.md
created_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
updated_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
audit_started_at:
audit_ended_at:
timezone: "TZ +0000"
auditor:
scope: []
checks: []
related_issues: []
related_prs: []
repo_state:
  based_on_commit:
  last_reviewed_commit:
next_audit_due:
---

# YYYY-MM-DD - Repo Health Audit

## Scope

- What areas were checked.
- What was intentionally out of scope.

## Guide Used

- Audit kind:
- Reusable guide:
- Repo-local profile: docs/repo-health/audits/audit-profile.md

Audits are read-only by default. Do not run write-mode cleanup commands unless the audit scope explicitly includes cleanup or the user asked for it.

Audits do not block unrelated implementation by default. Pause related implementation only for confirmed high-severity safety, security, data-loss, privacy, or release-readiness findings.

## Checks Run

Read-only commands:

- `agent-continuity docs check`

Optional cleanup commands, only if in scope:

- `agent-continuity docs health --write`
- `agent-continuity docs roadmap --write`

Manual or agent checks:

-

## Evidence Handling

- Raw sensitive artifacts reviewed:
- Local-only paths:
- Sanitized excerpts committed:
- Safe to commit: no
- Redactions performed:
- Retention/delete plan:

Never paste secret values, bearer tokens, private keys, auth headers, raw user content, transcripts, full logs, or provider payload dumps into committed audit docs.

## Findings

Use this exact table shape so follow-up work can be reviewed deterministically. Finding IDs are local to this audit; canonical references are `<audit path>#FINDING-###`.

| ID | Severity | Status | Finding | Route | Follow-up | Resolution |
|---|---|---|---|---|---|---|

Allowed severities:

- `critical`
- `high`
- `medium`
- `low`
- `info`

Allowed finding statuses:

- `open`
- `routed`
- `resolved`
- `deferred`
- `accepted-risk`
- `archived`

Allowed routes:

- `TODO`
- `DIAG`
- `RSCH`
- `EVAL`
- `QST`
- `CONC`
- `LRN`
- `ADR`
- `SPEC`
- `PLAN`
- `IMPL`
- `none`

Guide routing tables may mention alternatives for human judgment. Each actual finding-register row must choose exactly one allowed route code.

For direct fixes, use `Status` = `resolved`, `Route` = `none`, and put the evidence in `Resolution`. For accepted risks, use `Status` = `accepted-risk`, `Route` = `none`, and put the rationale and owner in `Resolution`.

Status-specific closeout rules:

- `routed` requires a stable ID or link in `Follow-up`.
- `resolved` requires evidence in `Resolution`.
- `deferred` requires a reason and revisit trigger in `Resolution`.
- `accepted-risk` requires rationale and owner in `Resolution`.
- `archived` requires reason in `Resolution`.

## Looks Good

- 

## Recommendations

- 

## Cleanup Done

- 

## Routed Or Deferred Follow-Ups

- 

## Next Audit Recommendation

- Suggested next audit:
- Suggested focus:
