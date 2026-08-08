# Repo Health Audits

Use this folder for periodic project checkups.

Repo health audits are broader than docs audits. They can include:

- docs metadata and generated views
- stale docs and roadmap order
- architecture boundaries and `AREA-*` drift
- duplicated code or repeated patterns
- refactor opportunities
- test, lint, build, and CI health
- dependency, release, security, or operations hygiene
- open issue/PR paper-trail quality

Audits are receipts, not generated truth. Generated signals such as `HEALTH.md`, `ROADMAP-VIEW.md`, `TODOS.md`, and `DOCS-REGISTRY.md` can feed an audit, but the audit records what a human or agent actually checked and concluded.

Use the installed audit guides as reusable procedures. Read only the guide for the audit kind you are running, then combine it with this repo's local paths and commands from [audit-profile.md](audit-profile.md).

Installed guide path:

```text
docs/repo-health/audits/guides/<audit-kind>.md
```

The available audit kinds and guide files are listed at `docs/repo-health/audits/guides/README.md` in installed full-profile repos.

Recommended cadence:

- small active repo: every 1-2 weeks
- fast-moving repo: after major milestones
- quiet repo: before restarting meaningful work

## Workflow

Use `agent-continuity docs new audit "<Title>" --kind <audit-kind>` when possible. It creates `repo-health/audits/AUDT-####-<slug>.md` with the required stable audit ID. When drafting by hand, start from `AUDT-0000-repo-health-audit.md` and replace `AUDT-0000` before committing.

Before reviewing, choose `audit_kind` and identify the matching reusable guide. Do not read every audit guide for every audit.

Start read-only:

```bash
agent-continuity docs check
```

Then add project-specific checks such as tests, lint, build, architecture review, duplication search, dependency checks, or manual review.

Write-mode cleanup commands such as `agent-continuity docs health --write` or `agent-continuity docs roadmap --write` belong in docs-health or paper-trail cleanup only when the audit scope explicitly includes cleanup.

An audit is complete only when every finding is resolved, routed to a follow-up artifact, deferred with reason, accepted as risk, or archived.

Audits do not block unrelated implementation by default. Pause related implementation only for confirmed high-severity safety, security, data-loss, privacy, or release-readiness findings.

## Last Audit

- Last completed audit:
- Next suggested audit:

Update these pointers after completing a meaningful audit. `agent-continuity docs health` can also flag when completed audits are missing or old.
