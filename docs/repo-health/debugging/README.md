# Debugging Notes

This folder records significant local-development incidents and debugging sessions that are likely to matter again.

Use it for issues where the final fix is not obvious from code alone: broken local tooling, simulator problems, stale smoke scripts, dependency-cache failures, or anything where the sequence of failed attempts is useful context for future work.

Each note should include:

- date and affected area
- symptoms
- likely root cause
- what was tried
- what worked
- verification performed
- what to do next time
- any cleanup or follow-up risk

These notes are operational history, not product specs. Keep implementation plans in `docs/<domain>/plans/`, architecture contracts in `docs/orientation/ARCHITECTURE.md`, and broader conceptual explainers in `docs/orientation/explainers/`.

## Diagnostic Records

Use `DIAG-*` diagnostic records when the question is:

> What happened in this real run, in what order, how long did each step take, and why did it fail or slow down?

`DIAG-*` is for run-level evidence: structured JSONL traces, crash logs, simulator/device logs, correlation IDs, timings, hypotheses ruled out, and a root cause or next instrumentation step. A session log records the human/agent work session; a diagnostic record records the execution path being investigated.

Raw traces are privacy-sensitive. Commit summaries and sanitized excerpts by default; keep raw logs, transcripts, media, payloads, and device traces local unless explicitly sanitized.

Do not create a new `DIAG-*` for routine debugging that is obvious after one command or one log line. Create one when the run involves user-visible failure, device/simulator specificity, privacy-sensitive logs, multiple hypotheses, added instrumentation, recurrence risk, or a result another agent may need to resume.

Create new diagnostic records with:

```bash
agent-continuity docs new diag "<Title>" --domain <domain>
```

## Layout

- [diagnostics/](diagnostics/) - `DIAG-*` diagnostic records and templates.
