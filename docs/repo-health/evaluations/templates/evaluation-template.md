# Evaluation Template

Use this for `EVAL-*` docs: repeatable evaluation reports that compare approaches against representative fixtures and metrics.

Create new evaluations with:

```bash
agent-continuity docs new eval "<Title>" --domain <domain>
```

---
type: evaluation
id: EVAL-####
title: <Evaluation Title>
domain: <product | architecture | repo-health | research | operations | marketing>
status: draft
created_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
updated_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
owner:
hypothesis:
artifact_root: artifacts/evaluations/EVAL-####/
dataset_version:
fixture_digest:
run_command:
metrics_version:
baseline_eval:
related_research: []
related_diagnostics: []
related_adrs: []
related_specs: []
related_plans: []
related_sessions: []
linked_paths: []
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# EVAL-#### - <Evaluation Title>

## Hypothesis

What can this evaluation prove, disprove, or rank?

## Candidates

List each model, provider, algorithm, threshold, implementation, or configuration being compared.

## Dataset / Fixtures

Describe fixture source, version, size, privacy handling, and digest. For quality bakeoffs, define gold labels before the run, separate tuning data from test data, and record ambiguous cases instead of silently fitting thresholds to the answers.

## Metrics

Include quality and operational metrics, such as precision, recall, false-positive rate, p50/p95/max latency, cost, storage, energy, or failure classes.

## Run Command

```bash
<repeatable command or manual procedure>
```

## Output Format

JSONL is preferred for per-case results. Include enough metadata to reproduce the run:

```json
{"case_id":"<id>","candidate":"<name>","duration_ms":0,"status":"ok","metrics":{}}
```

## Good-Enough Criteria

Define the threshold before reading the results.

## Results

Summarize results. Keep raw outputs in `artifact_root`.

## Recommendation / ADR Input

State what the evidence suggests. Link an ADR if the choice becomes durable.

## Reproduction Notes

## Artifact Policy

Commit summaries and sanitized excerpts. Keep raw private JSONL, transcripts, media, payload dumps, and user content local unless explicitly sanitized.

The default `artifacts/evaluations/` root is git-ignored. Force-add only reviewed sanitized artifacts.
