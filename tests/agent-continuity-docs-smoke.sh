#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
agent_continuity="$repo_root/scripts/agent-continuity"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

docs_root="$tmpdir/docs"
repo_commit="$(git -C "$repo_root" rev-parse HEAD)"
mkdir -p "$docs_root/architecture/areas"

run_meta() {
  "$agent_continuity" docs --root "$docs_root" "$@"
}

require_file() {
  if [[ ! -f "$1" ]]; then
    echo "Expected file does not exist: $1" >&2
    exit 1
  fi
}

require_absent() {
  if [[ -e "$1" ]]; then
    echo "Expected path to be absent: $1" >&2
    exit 1
  fi
}

require_contains() {
  local file="$1"
  local pattern="$2"
  if ! grep -Fq "$pattern" "$file"; then
    echo "Expected $file to contain: $pattern" >&2
    exit 1
  fi
}

idea_path="$(run_meta new idea "Repo Memory Timeline" --domain product)"
rsch_path="$(run_meta new research "Embedding Options Survey" --domain research)"
eval_path="$(run_meta new eval "Embedding Model Bakeoff" --domain repo-health)"
diag_path="$(run_meta new diag "Simulator Freeze Investigation" --domain repo-health)"
spec_path="$(run_meta new spec "Shared Capture Workflow" --domain product --spec-type improvement)"
plan_path="$(run_meta new plan "Shared Capture Implementation" --domain product --spec SPEC-0001)"
impl_path="$(run_meta new impl "Persist Capture Drafts" --domain product --plan PLAN-0001 --spec SPEC-0001)"
adr_path="$(run_meta new adr "Use Append Only Journal" --domain architecture --spec SPEC-0001)"
lrn_path="$(run_meta new learning "Specs And Plans Stay Separate" --domain repo-health)"
expl_path="$(run_meta new explainer "Specs Plans And Briefs" --domain orientation)"
qst_path="$(run_meta new question "Should Specs And Plans Be One To One" --domain repo-health)"
conc_path="$(run_meta new concept "Selections Snapshots And Dynamic Sections" --domain product)"
audit_path="$(run_meta new audit "Docs System Migration Baseline Audit" --kind docs-health --domain repo-health)"
completed_audit_path="$(run_meta new audit "Completed Roadmap Alignment Audit" --kind roadmap-alignment --status completed --domain repo-health)"

if run_meta new audit "Audit Without CLI Kind" --domain repo-health >$tmpdir/docs-meta-new-audit-without-kind.out 2>&1; then
  echo "Expected agent-continuity docs new audit without --kind to fail" >&2
  exit 1
fi
require_contains $tmpdir/docs-meta-new-audit-without-kind.out "required for audit docs"

require_file "$idea_path"
require_file "$rsch_path"
require_file "$eval_path"
require_file "$diag_path"
require_file "$spec_path"
require_file "$plan_path"
require_file "$impl_path"
require_file "$adr_path"
require_file "$lrn_path"
require_file "$expl_path"
require_file "$qst_path"
require_file "$conc_path"
require_file "$audit_path"
require_file "$completed_audit_path"

if [[ "$audit_path" != *"/AUDT-0001-"* ]]; then
  echo "Expected new audit path to include AUDT-0001, got $audit_path" >&2
  exit 1
fi

require_contains "$idea_path" "id: IDEA-0001"
require_contains "$idea_path" "status: captured"
require_contains "$rsch_path" "id: RSCH-0001"
require_contains "$rsch_path" "type: research-survey"
require_contains "$rsch_path" "based_on_commit: $repo_commit"
require_contains "$eval_path" "id: EVAL-0001"
require_contains "$eval_path" "artifact_root: artifacts/evaluations/EVAL-0001/"
require_contains "$eval_path" "based_on_commit: $repo_commit"
require_contains "$diag_path" "id: DIAG-0001"
require_contains "$diag_path" "status: investigating"
require_contains "$diag_path" "artifact_root: artifacts/diagnostics/DIAG-0001/"
require_contains "$diag_path" "safe_to_commit: false"
require_contains "$diag_path" "raw_artifacts_local_only: []"
require_contains "$diag_path" "based_on_commit: $repo_commit"
require_contains "$spec_path" "id: SPEC-0001"
require_contains "$spec_path" "superseded_by: []"
require_contains "$plan_path" "related_prs: []"
require_contains "$impl_path" "parent_plan: PLAN-0001"
require_contains "$impl_path" "related_prs: []"
require_contains "$adr_path" "status: proposed"
require_contains "$adr_path" "related_prs: []"
require_contains "$lrn_path" "id: LRN-0001"
require_contains "$lrn_path" "status: active"
require_contains "$lrn_path" "learning_type: lesson"
require_contains "$expl_path" "id: EXPL-0001"
require_contains "$expl_path" "type: explainer"
require_contains "$expl_path" "explainer_type: concept"
require_contains "$qst_path" "id: QST-0001"
require_contains "$qst_path" "status: open"
require_contains "$qst_path" "question_type: product"
require_contains "$conc_path" "id: CONC-0001"
require_contains "$conc_path" "type: concept"
require_contains "$conc_path" "concept_type: domain-model"
require_contains "$audit_path" "id: AUDT-0001"
require_contains "$audit_path" "type: repo-health-audit"
require_contains "$audit_path" "audit_kind: docs-health"
require_contains "$audit_path" "status: planned"
require_contains "$completed_audit_path" "id: AUDT-0002"
require_contains "$completed_audit_path" "status: completed"
require_contains "$completed_audit_path" "audit_started_at: \""
require_contains "$completed_audit_path" "audit_ended_at: \""

mkdir -p "$tmpdir/app/src"
touch "$tmpdir/app/src/todo.ts"

perl -0pi -e 's/linked_paths: \[\]/linked_paths:\n  - app\/src\/todo.ts/' "$plan_path"

cat > "$docs_root/architecture/areas/AREA-capture.md" <<'AREA'
---
type: architecture-area
id: AREA-capture
title: Capture
status: active
created_at: "2026-04-25 10:00:00 JST +0900"
updated_at: "2026-04-25 10:00:00 JST +0900"
owners: []
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# AREA-capture - Capture

- [ ] Define owner boundaries
AREA

cat >> "$plan_path" <<'TODOS'

## Structured Todo Smoke

- [ ] TODO-0001 [ready] [owner:main-agent] [skill:docs-writer] [plan:PLAN-0001] Define stable todo model
- [ ] TODO-0002 [blocked] [owner:main-agent] [skill:docs-writer] [plan:PLAN-0001] [brief:IMPL-0001-01] [blocker:TODO-0001] Wire todo checks
- [x] TODO-0003 [done] [owner:main-agent] [skill:docs-writer] [plan:PLAN-0001] [verification:tests/agent-continuity-docs-smoke.sh] Document todo workflow
- [ ] TODO-0004 [in_progress] [owner:main-agent] [agent:smoke-agent] [updated:2026-04-25 10:20:00 JST +0900] [skill:docs-writer] [plan:PLAN-0001] Claim todo work
- [ ] Follow up on TODO-0001 in review notes
- [ ] Local task with a | pipe

```text
- [ ] TODO-9999 [bogus] This example should not be parsed.
```
TODOS

mkdir -p "$docs_root/repo-health/audits"
cat > "$docs_root/repo-health/audits/AUDT-0003-repo-health-audit.md" <<'AUDIT'
---
type: repo-health-audit
id: AUDT-0003
title: Repo Health Audit
status: completed
audit_kind: docs-health
created_at: "2026-04-25 10:00:00 JST +0900"
updated_at: "2026-04-25 10:30:00 JST +0900"
audit_started_at: "2026-04-25 10:00:00 JST +0900"
audit_ended_at: "2026-04-25 10:30:00 JST +0900"
timezone: "JST +0900"
auditor: smoke-test
scope:
  - docs
  - metadata
checks:
  - agent-continuity docs check
  - agent-continuity docs health --write
related_issues: []
related_prs: []
repo_state:
  based_on_commit:
  last_reviewed_commit:
next_audit_due:
---

# 2026-04-25 - Repo Health Audit

## Findings

| ID | Severity | Status | Finding | Route | Follow-up | Resolution |
|---|---|---|---|---|---|---|
| FINDING-001 | high | open | Review queue is not generated yet | PLAN | PLAN-0001 |  |
| FINDING-002 | medium | routed | Diagnostic follow-up is missing | DIAG | DIAG-9999 |  |
| FINDING-003 | low | accepted-risk | Legacy naming remains inconsistent | none |  | Accepted by owner:docs because migration churn is not worth it |
| FINDING-004 | info | resolved | Generated docs were refreshed | none |  | Verified with agent-continuity docs update |
| FINDING-005 | low | routed | Blocked todo should stay visible | TODO | TODO-0002 |  |
| FINDING-006 | medium | routed | Stale plan should stay visible | PLAN | PLAN-0001 |  |
| FINDING-007 | low | deferred | Deferred finding should be reviewed later | none |  | Deferred because this is low risk; revisit after next planning pass |
| FINDING-008 | medium | routed | Markdown follow-up fragment is missing | PLAN | [Plan](../../product/plans/PLAN-0001-shared-capture-implementation/PLAN-0001-shared-capture-implementation.md#missing-anchor) |  |
| FINDING-009 | medium | open | Medium finding should not be grouped as high priority | PLAN | PLAN-0001 |  |
| FINDING-010 | medium | routed | Freeform routed follow-up should stay visible | PLAN | Someone should look into this |  |
| FINDING-011 | medium | routed | Markdown follow-up title should still resolve | PLAN | [Plan](../../product/plans/PLAN-0001-shared-capture-implementation/PLAN-0001-shared-capture-implementation.md#plan-0001-shared-capture-implementation "Open plan") |  |
| FINDING-012 | low | routed | External Markdown issue link should be accepted | PLAN | [Issue](https://github.com/owensantoso/agent-continuity/issues/1 "Issue") |  |
| FINDING-013 | medium | routed | Route mismatch should stay visible | DIAG | PLAN-0001 |  |

```md
| ID | Severity | Status | Finding | Route | Follow-up | Resolution |
|---|---|---|---|---|---|---|
| FINDING-999 | high | open | Fenced examples must not parse | PLAN | PLAN-9999 |  |
```
AUDIT

cat > "$docs_root/repo-health/audits/AUDT-0004-invalid-audit.md" <<'BADAUDIT'
---
type: repo-health-audit
id: AUDT-0004
title: Invalid Audit
status: completed
audit_kind: docs-health
created_at: "2026-04-26 10:00:00 JST +0900"
updated_at: "2026-04-26 10:30:00 JST +0900"
audit_started_at: "2026-04-26 10:00:00 JST +0900"
audit_ended_at: "2026-04-26 10:30:00 JST +0900"
timezone: "JST +0900"
auditor: smoke-test
scope:
  - docs
checks:
  - agent-continuity docs review
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# 2026-04-26 - Invalid Audit

| ID | Severity | Status | Finding | Route | Follow-up | Resolution |
|---|---|---|---|---|---|---|
| FINDING-001 | urgent | open | Invalid severity should be reported | PLAN | PLAN-0001 |  |
| FINDING-001 | low | archived | Duplicate and archived without reason | none |  |  |
| FINDING-002 | medium | nonsense | Invalid status should be grouped before open findings | none |  |  |
| FINDING-003 | low | accepted-risk | Accepted risk with route is invalid | PLAN | PLAN-0001 | Accepted by owner:docs for now |
| FINDING-004 | low | deferred | Deferred risk lacks a revisit trigger | none |  | Deferred for later |
| FINDING-005 | low | accepted-risk | Accepted risk lacks rationale | none |  | owner:docs |
| FINDING-006 | low | open | Malformed row has SECRET-AUDIT-PAYLOAD and an unescaped | pipe | PLAN | PLAN-0001 |  |
| FINDING-007 | high | open | Row after malformed row should still parse | PLAN | PLAN-0001 |  |
BADAUDIT

next_idea="$(run_meta next idea)"
if [[ "$next_idea" != "IDEA-0002" ]]; then
  echo "Expected next IDEA-0002, got $next_idea" >&2
  exit 1
fi

next_adr="$(run_meta next adr)"
if [[ "$next_adr" != "ADR-0002" ]]; then
  echo "Expected next ADR-0002, got $next_adr" >&2
  exit 1
fi

next_rsch="$(run_meta next rsch)"
if [[ "$next_rsch" != "RSCH-0002" ]]; then
  echo "Expected next RSCH-0002, got $next_rsch" >&2
  exit 1
fi

next_eval="$(run_meta next eval)"
if [[ "$next_eval" != "EVAL-0002" ]]; then
  echo "Expected next EVAL-0002, got $next_eval" >&2
  exit 1
fi

next_diag="$(run_meta next diag)"
if [[ "$next_diag" != "DIAG-0002" ]]; then
  echo "Expected next DIAG-0002, got $next_diag" >&2
  exit 1
fi

next_lrn="$(run_meta next lrn)"
if [[ "$next_lrn" != "LRN-0002" ]]; then
  echo "Expected next LRN-0002, got $next_lrn" >&2
  exit 1
fi

next_expl="$(run_meta next expl)"
if [[ "$next_expl" != "EXPL-0002" ]]; then
  echo "Expected next EXPL-0002, got $next_expl" >&2
  exit 1
fi

next_qst="$(run_meta next qst)"
if [[ "$next_qst" != "QST-0002" ]]; then
  echo "Expected next QST-0002, got $next_qst" >&2
  exit 1
fi

next_conc="$(run_meta next conc)"
if [[ "$next_conc" != "CONC-0002" ]]; then
  echo "Expected next CONC-0002, got $next_conc" >&2
  exit 1
fi

next_audt="$(run_meta next audt)"
if [[ "$next_audt" != "AUDT-0005" ]]; then
  echo "Expected next AUDT-0005, got $next_audt" >&2
  exit 1
fi

next_todo="$(run_meta next todo)"
if [[ "$next_todo" != "TODO-0005" ]]; then
  echo "Expected next TODO-0005, got $next_todo" >&2
  exit 1
fi

run_meta set-status ADR-0001 accepted >/dev/null
require_contains "$adr_path" "status: accepted"
run_meta set-status IDEA-0001 exploring >/dev/null
require_contains "$idea_path" "status: exploring"
run_meta set-status LRN-0001 draft >/dev/null
require_contains "$lrn_path" "status: draft"
run_meta set-status DIAG-0001 resolved >/dev/null
require_contains "$diag_path" "status: resolved"
run_meta set-status PLAN-0001 ready >/dev/null
perl -0pi -e 's/updated_at: "[^"]+"/updated_at: "2026-01-01 00:00:00 JST +0900"/' "$plan_path" "$qst_path"

run_meta review >$tmpdir/docs-meta-review.out
expected_finding_line="$(grep -n '^| FINDING-001 | high | open' "$docs_root/repo-health/audits/AUDT-0003-repo-health-audit.md" | cut -d: -f1)"
require_contains $tmpdir/docs-meta-review.out "FINDING-001"
require_contains $tmpdir/docs-meta-review.out "FINDING-007"
require_contains $tmpdir/docs-meta-review.out "Review queue is not generated yet"
require_contains $tmpdir/docs-meta-review.out "missing-follow-up"
require_contains $tmpdir/docs-meta-review.out "DIAG-9999"
require_contains $tmpdir/docs-meta-review.out "TODO-0002"
require_contains $tmpdir/docs-meta-review.out "PLAN-0001"
require_contains $tmpdir/docs-meta-review.out "QST-0001"
require_contains $tmpdir/docs-meta-review.out "blocked-follow-up"
require_contains $tmpdir/docs-meta-review.out "stale-follow-up"
require_contains $tmpdir/docs-meta-review.out "invalid-follow-up"
require_contains $tmpdir/docs-meta-review.out "missing-anchor"
require_contains $tmpdir/docs-meta-review.out "Someone should look into this"
require_contains $tmpdir/docs-meta-review.out "Route DIAG does not match follow-up PLAN-0001"
require_contains $tmpdir/docs-meta-review.out "Other open audit findings"
if grep -Fq "Other review items" $tmpdir/docs-meta-review.out; then
  echo "Expected every smoke review item to be grouped into a known urgency bucket" >&2
  exit 1
fi
if grep -Fq "FINDING-999" $tmpdir/docs-meta-review.out; then
  echo "Expected review parser to ignore fenced audit table examples" >&2
  exit 1
fi
run_meta review --stale-days 1 >$tmpdir/docs-meta-review-due.out
require_contains $tmpdir/docs-meta-review-due.out "due-review"
require_contains $tmpdir/docs-meta-review-due.out "FINDING-003"
require_contains $tmpdir/docs-meta-review-due.out "FINDING-007"
first_review_line="$(awk 'NF { print; exit }' "$tmpdir/docs-meta-review.out")"
if [[ "$first_review_line" != "Invalid audit finding rows" ]]; then
  echo "Expected review output to group invalid findings first, got: $first_review_line" >&2
  exit 1
fi
run_meta review --type audit-findings --severity high >$tmpdir/docs-meta-review-high.out
require_contains $tmpdir/docs-meta-review-high.out "FINDING-001"
if grep -Fq "FINDING-002" $tmpdir/docs-meta-review-high.out; then
  echo "Expected high severity review filter to exclude medium findings" >&2
  exit 1
fi
run_meta review --json >$tmpdir/docs-meta-review.json
require_contains $tmpdir/docs-meta-review.json "\"reference\": \"repo-health/audits/AUDT-0003-repo-health-audit.md#FINDING-001\""
require_contains $tmpdir/docs-meta-review.json "\"source\": \"repo-health/audits/AUDT-0003-repo-health-audit.md:$expected_finding_line\""
require_contains $tmpdir/docs-meta-review.json "\"code\": \"invalid-audit-finding\""
require_contains $tmpdir/docs-meta-review.json "\"message\": \"Invalid severity 'urgent'\""
require_contains $tmpdir/docs-meta-review.json "\"message\": \"Malformed audit finding row\""
if grep -Fq "SECRET-AUDIT-PAYLOAD" $tmpdir/docs-meta-review.json; then
  echo "Expected malformed audit row detail to avoid raw sensitive payloads" >&2
  exit 1
fi
if grep -Fq "\"route\": \"pipe\"" $tmpdir/docs-meta-review.json || grep -Fq "\"follow_up\": \"PLAN\"" $tmpdir/docs-meta-review.json; then
  echo "Expected malformed audit row shifted cells not to leak via route or follow_up" >&2
  exit 1
fi
if grep -Fq "Invalid route 'pipe'" $tmpdir/docs-meta-review.json; then
  echo "Expected malformed audit rows not to emit shifted validation noise" >&2
  exit 1
fi
require_contains $tmpdir/docs-meta-review.json "\"code\": \"duplicate-audit-finding\""
require_contains $tmpdir/docs-meta-review.json "\"code\": \"stale-doc\""
require_contains $tmpdir/docs-meta-review.json "\"code\": \"blocked-follow-up\""
require_contains $tmpdir/docs-meta-review.json "\"message\": \"Accepted risk must use Route = none\""
require_contains $tmpdir/docs-meta-review.json "\"message\": \"Deferred finding needs reason and revisit trigger\""
require_contains $tmpdir/docs-meta-review.json "\"message\": \"Accepted risk needs rationale and owner\""
require_contains $tmpdir/docs-meta-review.json "\"message\": \"Invalid follow-up fragment #missing-anchor\""
require_contains $tmpdir/docs-meta-review.json "\"message\": \"Invalid follow-up target Someone should look into this\""
require_contains $tmpdir/docs-meta-review.json "\"message\": \"Route DIAG does not match follow-up PLAN-0001\""
if grep -Fq "Invalid follow-up fragment #plan-0001-shared-capture-implementation" $tmpdir/docs-meta-review.json; then
  echo "Expected Markdown follow-up links with optional titles to resolve" >&2
  exit 1
fi
if grep -Fq "Missing follow-up [Issue](https://github.com/owensantoso/agent-continuity/issues/1" $tmpdir/docs-meta-review.json; then
  echo "Expected external Markdown issue links to be accepted" >&2
  exit 1
fi
run_meta set-status PLAN-0001 draft >/dev/null

run_meta update
require_file "$docs_root/IDEAS.md"
require_file "$docs_root/SPECS.md"
require_file "$docs_root/LEARNINGS.md"
require_file "$docs_root/EXPLAINERS.md"
require_file "$docs_root/QUESTIONS.md"
require_file "$docs_root/CONCEPTS.md"
require_file "$docs_root/DOCS-REGISTRY.md"
require_file "$docs_root/TODOS.md"
require_file "$docs_root/AREAS.md"
require_file "$docs_root/AUDITS.md"
require_file "$docs_root/ROADMAP-VIEW.md"
require_contains "$docs_root/IDEAS.md" "IDEA-0001"
require_contains "$docs_root/AREAS.md" "AREA-capture"
require_contains "$docs_root/AUDITS.md" "AUDT-0001"
require_contains "$docs_root/AUDITS.md" "AUDT-0003"
require_contains "$docs_root/AUDITS.md" "Repo Health Audit"
require_contains "$docs_root/LEARNINGS.md" "LRN-0001"
require_contains "$docs_root/LEARNINGS.md" "Specs And Plans Stay Separate"
require_contains "$docs_root/EXPLAINERS.md" "EXPL-0001"
require_contains "$docs_root/EXPLAINERS.md" "Specs Plans And Briefs"
require_contains "$docs_root/QUESTIONS.md" "QST-0001"
require_contains "$docs_root/QUESTIONS.md" "Should Specs And Plans Be One To One"
require_contains "$docs_root/CONCEPTS.md" "CONC-0001"
require_contains "$docs_root/CONCEPTS.md" "Selections Snapshots And Dynamic Sections"
require_contains "$docs_root/DOCS-REGISTRY.md" "RSCH-0001"
require_contains "$docs_root/DOCS-REGISTRY.md" "EVAL-0001"
require_contains "$docs_root/DOCS-REGISTRY.md" "DIAG-0001"
require_contains "$docs_root/ROADMAP-VIEW.md" "PLAN-0001"
require_contains "$docs_root/ROADMAP-VIEW.md" "PLAN-0001-shared-capture-implementation"
require_contains "$docs_root/ROADMAP-VIEW.md" "type: generated-view"
require_contains "$docs_root/ROADMAP-VIEW.md" "updated_at:"
require_contains "$docs_root/TODOS.md" "Define owner boundaries"
require_contains "$docs_root/TODOS.md" "Structured Todos"
require_contains "$docs_root/TODOS.md" "TODO-0001"
require_contains "$docs_root/TODOS.md" "Local task with a \\| pipe"

mkdir -p "$docs_root/research"
cat > "$docs_root/research/bad-research-without-id.md" <<'BADRESEARCH'
---
type: research-survey
title: Bad Research Without ID
domain: research
status: draft
created_at: "2026-04-25 10:00:00 JST +0900"
updated_at: "2026-04-25 10:00:00 JST +0900"
owner:
question:
source:
  type: conversation
  link:
  notes:
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# Bad Research Without ID
BADRESEARCH
if run_meta check >$tmpdir/docs-meta-bad-research.out 2>&1; then
  echo "Expected typed RSCH-style doc without id to fail validation" >&2
  exit 1
fi
require_contains $tmpdir/docs-meta-bad-research.out "Missing frontmatter field 'id'"
rm "$docs_root/research/bad-research-without-id.md"

cat > "$docs_root/repo-health/audits/bad-audit-without-id.md" <<'BADAUDITID'
---
type: repo-health-audit
title: Bad Audit Without ID
status: completed
audit_kind: docs-health
created_at: "2026-04-25 10:00:00 JST +0900"
updated_at: "2026-04-25 10:30:00 JST +0900"
audit_started_at: "2026-04-25 10:00:00 JST +0900"
audit_ended_at: "2026-04-25 10:30:00 JST +0900"
scope:
  - docs
checks:
  - agent-continuity docs check
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# Bad Audit Without ID
BADAUDITID

if run_meta check >$tmpdir/docs-meta-bad-audit-id.out 2>&1; then
  echo "Expected typed repo-health-audit without id to fail validation" >&2
  exit 1
fi
require_contains $tmpdir/docs-meta-bad-audit-id.out "Missing frontmatter field 'id'"
rm "$docs_root/repo-health/audits/bad-audit-without-id.md"

run_meta check
run_meta check-todos >$tmpdir/docs-meta-check-todos.out 2>&1
require_contains $tmpdir/docs-meta-check-todos.out "No todo issues found."
run_meta check-todos --strict >$tmpdir/docs-meta-check-todos-strict.out 2>&1
require_contains $tmpdir/docs-meta-check-todos-strict.out "WARN:"
run_meta todos --status ready >$tmpdir/docs-meta-todos-ready.out
require_contains $tmpdir/docs-meta-todos-ready.out "TODO-0001"
run_meta todos --owner main-agent --structured-only >$tmpdir/docs-meta-todos-owner.out
require_contains $tmpdir/docs-meta-todos-owner.out "TODO-0002"
run_meta todos --agent smoke-agent --structured-only >$tmpdir/docs-meta-todos-agent.out
require_contains $tmpdir/docs-meta-todos-agent.out "TODO-0004"
run_meta todos --plan PLAN-0001 --json >$tmpdir/docs-meta-todos.json
require_contains $tmpdir/docs-meta-todos.json "\"id\": \"TODO-0001\""
require_contains $tmpdir/docs-meta-todos.json "\"agent\": \"smoke-agent\""
run_meta todos TODO-0003 --all >$tmpdir/docs-meta-todos-id.out
require_contains $tmpdir/docs-meta-todos-id.out "TODO-0003"
run_meta todos --structured-only --all >$tmpdir/docs-meta-todos-structured.out
if grep -Fq "Follow up on TODO-0001" $tmpdir/docs-meta-todos-structured.out; then
  echo "Expected non-leading TODO reference to remain a local checkbox" >&2
  exit 1
fi
rm "$docs_root/ROADMAP-VIEW.md"
run_meta roadmap --json >$tmpdir/docs-meta-roadmap.json
require_contains $tmpdir/docs-meta-roadmap.json "\"id\": \"PLAN-0001\""
require_contains $tmpdir/docs-meta-roadmap.json "\"plan_name\": \"PLAN-0001-shared-capture-implementation\""
require_absent "$docs_root/ROADMAP-VIEW.md"
run_meta roadmap --write >$tmpdir/docs-meta-roadmap-write.out
require_file "$docs_root/ROADMAP-VIEW.md"
run_meta show PLAN-0001 >$tmpdir/docs-meta-show-plan.out
require_contains $tmpdir/docs-meta-show-plan.out $'Linked Paths:'
require_contains $tmpdir/docs-meta-show-plan.out "app/src/todo.ts: ok -> app/src/todo.ts"
run_meta show PLAN-0001 --json >$tmpdir/docs-meta-show-plan.json
require_contains $tmpdir/docs-meta-show-plan.json "\"linked_paths\""
require_contains $tmpdir/docs-meta-show-plan.json "\"status\": \"ok\""
run_meta view todos >$tmpdir/docs-meta-view-todos.md
require_contains $tmpdir/docs-meta-view-todos.md "Docs Todos"
require_contains "$docs_root/TODOS.md" "updated_at:"

cat >> "$plan_path" <<'BADTODO'

- [ ] TODO-0001 [ready] Duplicate todo ID
- [x] TODO-0005 [in_progress] [owner:main-agent] Checked but active
- [ ] TODO-0006 [done] Open but done
- [ ] TODO-0007 [nonsense] Invalid status
- [ ] TODO-0008 [in_progress] Missing owner
- [ ] TODO-0009 [in_progress] [owner:main-agent] Missing agent and timestamp
- [ ] TODO-0010 [blocked] Missing blocker reason
- [x] TODO-0011 [done] Missing done evidence
- [ ] TODO-0012 [ready] [plan:PLAN-9999] Missing plan
BADTODO
if run_meta check-todos >$tmpdir/docs-meta-bad-todos.out 2>&1; then
  echo "Expected invalid structured todos to fail validation" >&2
  exit 1
fi
require_contains $tmpdir/docs-meta-bad-todos.out "Duplicate todo ID TODO-0001"
require_contains $tmpdir/docs-meta-bad-todos.out "invalid todo status"
require_contains $tmpdir/docs-meta-bad-todos.out "in_progress status without owner"
require_contains $tmpdir/docs-meta-bad-todos.out "in_progress status without agent"
require_contains $tmpdir/docs-meta-bad-todos.out "in_progress status without updated timestamp"
require_contains $tmpdir/docs-meta-bad-todos.out "blocked status without blocker"
require_contains $tmpdir/docs-meta-bad-todos.out "done status without verification"
require_contains $tmpdir/docs-meta-bad-todos.out "references missing plan PLAN-9999"
perl -0pi -e 's/\n- \[ \] TODO-0001 \[ready\] Duplicate todo ID\n- \[x\] TODO-0005 \[in_progress\] \[owner:main-agent\] Checked but active\n- \[ \] TODO-0006 \[done\] Open but done\n- \[ \] TODO-0007 \[nonsense\] Invalid status\n- \[ \] TODO-0008 \[in_progress\] Missing owner\n- \[ \] TODO-0009 \[in_progress\] \[owner:main-agent\] Missing agent and timestamp\n- \[ \] TODO-0010 \[blocked\] Missing blocker reason\n- \[x\] TODO-0011 \[done\] Missing done evidence\n- \[ \] TODO-0012 \[ready\] \[plan:PLAN-9999\] Missing plan\n//' "$plan_path"

perl -0pi -e 's/linked_paths:\n  - app\/src\/todo.ts\n/linked_paths:\n  - app\/src\/missing.ts\n/' "$plan_path"
if run_meta check >$tmpdir/docs-meta-bad-linked-paths.out 2>&1; then
  echo "Expected missing linked_paths target to fail validation" >&2
  exit 1
fi
require_contains $tmpdir/docs-meta-bad-linked-paths.out "linked_paths entry 'app/src/missing.ts' is missing"
perl -0pi -e 's/linked_paths:\n  - app\/src\/missing.ts\n/linked_paths:\n  - app\/src\/todo.ts\n/' "$plan_path"

mkdir -p "$docs_root/link-fixtures"
cat > "$docs_root/link-fixtures/target.md" <<'TARGET'
# Target
TARGET
cat > "$docs_root/link-fixtures/source.md" <<'SOURCE'
# Source

- [Target](target.md)
- [Spec](/product/specs/SPEC-0001-shared-capture-workflow.md)
- [Missing](missing.md)
- [[target.md]]
- `<not-a-link>`

```text
[also-not-a-link](missing-in-code.md)
```
SOURCE

run_meta links link-fixtures/source.md >$tmpdir/docs-meta-links.out
require_contains $tmpdir/docs-meta-links.out "target.md"
require_contains $tmpdir/docs-meta-links.out "wiki-link"
run_meta backlinks link-fixtures/target.md >$tmpdir/docs-meta-backlinks.out
require_contains $tmpdir/docs-meta-backlinks.out "link-fixtures/source.md"
if run_meta check-links >$tmpdir/docs-meta-check-links.out 2>&1; then
  echo "Expected missing link to fail check-links" >&2
  exit 1
fi
require_contains $tmpdir/docs-meta-check-links.out "missing.md"
if grep -Fq "not-a-link" $tmpdir/docs-meta-check-links.out || grep -Fq "missing-in-code" $tmpdir/docs-meta-check-links.out; then
  echo "Expected check-links to ignore links inside inline and fenced code" >&2
  exit 1
fi
perl -0pi -e 's/^- \[Missing\]\(missing\.md\)\n//m' "$docs_root/link-fixtures/source.md"
if ! run_meta check-links >$tmpdir/docs-meta-check-links-clean.out 2>&1; then
  cat $tmpdir/docs-meta-check-links-clean.out >&2
  echo "Expected check-links to pass after removing missing link" >&2
  exit 1
fi
run_meta normalize-links --style relative --dry-run >$tmpdir/docs-meta-normalize-dry-run.out
require_contains $tmpdir/docs-meta-normalize-dry-run.out "/product/specs/SPEC-0001-shared-capture-workflow.md -> ../product/specs/SPEC-0001-shared-capture-workflow.md"
run_meta normalize-links --style relative --write >$tmpdir/docs-meta-normalize-write.out
require_contains "$docs_root/link-fixtures/source.md" "../product/specs/SPEC-0001-shared-capture-workflow.md"
run_meta move link-fixtures/target.md link-fixtures/moved/target-new.md --dry-run >$tmpdir/docs-meta-move-dry-run.out
require_contains $tmpdir/docs-meta-move-dry-run.out "target.md -> moved/target-new.md"
run_meta move link-fixtures/target.md link-fixtures/moved/target-new.md --write >$tmpdir/docs-meta-move-write.out
require_file "$docs_root/link-fixtures/moved/target-new.md"
require_contains "$docs_root/link-fixtures/source.md" "moved/target-new.md"
run_meta backlinks link-fixtures/moved/target-new.md >$tmpdir/docs-meta-backlinks-moved.out
require_contains $tmpdir/docs-meta-backlinks-moved.out "link-fixtures/source.md"
run_meta orphans --exclude 'link-fixtures/*' >$tmpdir/docs-meta-orphans.out
if grep -Fq "link-fixtures/target.md" $tmpdir/docs-meta-orphans.out; then
  echo "Expected orphan exclude pattern to suppress link-fixtures docs" >&2
  exit 1
fi

perl -0pi -e 's/updated_at: "[^"]+"/updated_at: "2026-01-01 00:00:00 JST +0900"/' "$docs_root/architecture/areas/AREA-capture.md"
run_meta health --stale-days 1 >$tmpdir/docs-meta-health.out
require_contains $tmpdir/docs-meta-health.out "stale-by-time"
require_contains $tmpdir/docs-meta-health.out "AREA-capture"
require_absent "$docs_root/HEALTH.md"
run_meta health --stale-days 1 --write >$tmpdir/docs-meta-health-write.out
require_file "$docs_root/HEALTH.md"
require_contains "$docs_root/HEALTH.md" "Docs Health"
run_meta health --stale-days 1 --json >$tmpdir/docs-meta-health.json
require_contains $tmpdir/docs-meta-health.json "\"code\": \"stale-by-time\""

missing_field="$docs_root/product/specs/SPEC-0002-missing-field.md"
cp "$spec_path" "$missing_field"
perl -0pi -e 's/^title: .+\n//m; s/SPEC-0001/SPEC-0002/g' "$missing_field"
if run_meta check >$tmpdir/docs-meta-missing-field.out 2>&1; then
  echo "Expected missing title field to fail validation" >&2
  exit 1
fi
require_contains $tmpdir/docs-meta-missing-field.out "Missing frontmatter field 'title'"
rm "$missing_field"

bad_area="$docs_root/architecture/areas/AREA-bad.md"
cp "$docs_root/architecture/areas/AREA-capture.md" "$bad_area"
perl -0pi -e 's/AREA-capture/AREA-other/g' "$bad_area"
if run_meta check >$tmpdir/docs-meta-bad-area.out 2>&1; then
  echo "Expected area ID mismatch to fail validation" >&2
  exit 1
fi
require_contains $tmpdir/docs-meta-bad-area.out "must match filename stem"
rm "$bad_area"

perl -0pi -e 's/status: draft/status: accepted/' "$plan_path"
if run_meta check >$tmpdir/docs-meta-bad-status.out 2>&1; then
  echo "Expected invalid plan status to fail validation" >&2
  exit 1
fi
require_contains $tmpdir/docs-meta-bad-status.out "Unknown status 'accepted' for type 'plan'"

echo "agent-continuity docs smoke test passed"
