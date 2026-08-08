---
type: docs-index
title: Evaluations
status: ready
created_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
updated_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
---

# Evaluations

Use `EVAL-*` evaluation reports when the question is:

> Which approach works better, and how do we know?

An evaluation report defines a repeatable protocol and records results from representative fixtures, metrics, timings, costs, and failure modes. The runnable harness belongs in scripts, fixtures, or artifacts; the Markdown doc records the protocol, summary, and recommendation.

Do not use `EVAL-*` for ordinary unit tests, one-off debugging, or unsourced research. Use `RSCH-*` for research surveys and `DIAG-*` for diagnostic records of real runs.

Do not create a new `EVAL-*` unless there is a repeatable fixture/protocol and predeclared good-enough criteria. Update an existing evaluation when the candidates, dataset, and metrics are the same.

This folder is the cross-domain evidence home for evaluations, including product/model bakeoffs. Use the `domain` frontmatter to distinguish product, architecture, repo-health, research, operations, and marketing evaluations.

## Layout

- [templates/evaluation-template.md](templates/evaluation-template.md) - template for `EVAL-*` reports.

Local or sanitized artifacts should use this shape:

```text
artifacts/evaluations/EVAL-####/
  inputs/
  runs/<timestamp>/
    results.jsonl
  reports/
```

Raw private data should stay local unless explicitly sanitized. The default `artifacts/evaluations/` root is git-ignored; force-add only reviewed sanitized artifacts.

## Filename

```text
EVAL-####-<slug>.md
```

Create new evaluations with:

```bash
agent-continuity docs new eval "<Title>" --domain <domain>
```
