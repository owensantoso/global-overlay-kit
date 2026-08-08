# Diagnostic Record Template

Use this for `DIAG-*` docs: real-run investigations that need structured evidence, timing, correlation IDs, and a durable diagnosis trail.

Create new diagnostic records with:

```bash
agent-continuity docs new diag "<Title>" --domain <domain>
```

---
type: diagnostic-record
id: DIAG-####
title: <Diagnostic Title>
domain: <product | architecture | repo-health | research | operations | marketing>
status: investigating
created_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
updated_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
owner:
symptom:
artifact_root: artifacts/diagnostics/DIAG-####/
privacy_classification:
artifact_sensitivity:
safe_to_commit: false
retention_policy:
delete_after:
capture_method:
raw_artifacts_local_only: []
sanitized_artifacts: []
environment:
git_sha:
app_build:
related_evaluations: []
related_adrs: []
related_specs: []
related_plans: []
related_sessions: []
linked_paths: []
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# DIAG-#### - <Diagnostic Title>

## Symptom

What was observed? Include exact user-visible behavior, crash reason, freeze, slowdown, or flaky state.

## Run Context

Include device/simulator, OS, app build, git SHA, account/data state, feature flags, network state, and reproduction steps.

## Instrumentation Added

List trace points, OSLog categories, correlation IDs, or export paths added for this investigation.

## Evidence

Link sanitized trace files, crash logs, screenshots, profiler output, or relevant excerpts.

## Key Events

Reconstruct the important event order. Include wall-clock time and monotonic elapsed time when available.

## Current Theory / Root Cause

State what the evidence supports. Mark unproven theories clearly.

## Fix Or Next Instrumentation

## Privacy Notes

Say what raw data exists, where it is stored, whether the path is ignored by git, who deletes it, when it should be deleted, what was redacted, and what exact sanitized excerpt is safe to commit.

## Cleanup Plan

Remove noisy instrumentation after the issue is understood, or keep it if it is useful product telemetry/debug UI.
