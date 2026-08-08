# Audit Guides

Reusable procedures for Agent Continuity audit kinds.

These guides are repo-agnostic. A target repo can add a small local audit profile that says where its specs, plans, code, tests, generated views, security-sensitive files, and release commands live.

Recommended target-repo profile path:

```text
docs/repo-health/audits/audit-profile.md
```

The profile should contain repo-specific paths and commands only. Keep reusable audit method here in Agent Continuity.

## Routing Rule

Do not read every audit guide for every audit.

1. Read the audit request or audit doc.
2. Identify `audit_kind`.
3. Open only the matching guide below.
4. Open the repo-local audit profile if present.
5. Review only the sources needed for that audit kind.

| `audit_kind` | Guide | Use When |
|---|---|---|
| `roadmap-alignment` | [roadmap-alignment.md](roadmap-alignment.md) | Plans/specs/current work may drift from roadmap or north-star direction |
| `ontology` | [ontology.md](ontology.md) | Naming, taxonomy, source-of-truth, or domain boundaries are confusing |
| `architecture` | [architecture.md](architecture.md) | Module boundaries, dependencies, interfaces, or ownership need review |
| `schema` | [schema.md](schema.md) | Data model, migrations, generated types, sync, or persistence contracts may drift |
| `security` | [security.md](security.md) | Auth, authorization, secrets, dependencies, or attack surface need review |
| `privacy` | [privacy.md](privacy.md) | Sensitive data, retention, AI payloads, export/delete, or consent need review |
| `performance` | [performance.md](performance.md) | Runtime cost, latency, launch, memory, queries, or build/test speed need review |
| `accessibility` | [accessibility.md](accessibility.md) | UI semantics, assistive tech, contrast, motion, or keyboard/touch access need review |
| `docs-health` | [docs-health.md](docs-health.md) | Docs metadata, generated views, stale docs, links, or docs tooling need review |
| `test-coverage` | [test-coverage.md](test-coverage.md) | Planned guarantees may not be covered by tests or verification |
| `paper-trail` | [paper-trail.md](paper-trail.md) | Commits, sessions, plans, specs, PRs, and generated views may not tell a coherent story |

## Standard Output

Every audit should produce:

- stable `AUDT-*` document ID
- scope
- sources reviewed
- checks run
- evidence handling
- findings register
- recommendations
- routed follow-ups
- explicit non-goals

An audit is complete only when every finding is resolved, routed, deferred, accepted as risk, or archived.

Audits are read-only by default. Do not run write-mode cleanup commands unless cleanup is explicitly in scope.

Audits do not block unrelated implementation by default. Pause related implementation only for confirmed high-severity safety, security, data-loss, privacy, or release-readiness findings.

## Evidence Handling

Add an evidence-handling section to every meaningful audit:

```md
## Evidence Handling

- Raw sensitive artifacts reviewed:
- Local-only paths:
- Sanitized excerpts committed:
- Safe to commit: yes/no
- Redactions performed:
- Retention/delete plan:
```

Never paste secret values, bearer tokens, private keys, auth headers, raw user content, transcripts, full logs, media, provider payload dumps, or private JSONL into committed audit docs.

## Fallback Discovery

If the target repo has no Agent Continuity document tooling or no audit profile yet:

```bash
rg --files
find . -name AGENTS.md -o -name README.md
```

Then inspect:

- root and surface `AGENTS.md` files
- docs root and current-state docs
- package manifests, build files, and test configs
- schema, migration, or persistence directories
- CI, release, and deployment configs
- generated-docs or reports directories

Record unavailable checks explicitly instead of pretending they passed.

## New Guide Bar

Create a new audit guide only when it has distinct:

- inputs
- evidence sources
- checks
- finding categories
- routing rules

If a new topic mostly reuses an existing guide, extend the existing guide or add a short note instead of creating another shallow file.

## Finding Register

Use this exact table shape unless a repo has a stricter versioned machine format. Keep each finding on one row, and escape literal pipes as `\|`.

```md
| ID | Severity | Status | Finding | Route | Follow-up | Resolution |
|---|---|---|---|---|---|---|
| FINDING-001 | high | open | Example mismatch | PLAN |  |  |
```

Finding IDs are local to an audit. Canonical references are `<audit path>#FINDING-###`.

Allowed severities:

- `critical`
- `high`
- `medium`
- `low`
- `info`

Allowed statuses:

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

Closeout rules:

- `routed` requires a stable ID or link in `Follow-up`.
- `resolved` requires evidence in `Resolution`.
- `deferred` requires a reason and revisit trigger in `Resolution`.
- `accepted-risk` requires rationale and owner in `Resolution`.
- `archived` requires reason in `Resolution`.
