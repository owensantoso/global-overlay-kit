---
type: docs-index
title: Research
status: ready
created_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
updated_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
---

# Research

Research notes, surveys, prompts, and exploratory inputs live here when they are useful to keep with the docs paper trail.

Use `RSCH-*` research surveys when the question is:

> What options exist, what do credible sources say, and what should we investigate next?

`RSCH-*` is for sourced landscape work before the team is ready to choose, specify, or build. It should compare at least two options or source clusters and end with a recommendation, shortlist, or next-question set.

Do not use a research survey for repeatable experiments or model bakeoffs; use an `EVAL-*` evaluation instead. Do not use it for one real failed run; use a `DIAG-*` diagnostic record.

Do not create a new `RSCH-*` for one source, one quick chat answer, a decision that is already made, or material that belongs in an existing survey. Update the existing survey when the research question is the same.

## Layout

- [notes/](notes/) - raw research notes and exploratory inputs.
- [templates/research-survey-template.md](templates/research-survey-template.md) - template for `RSCH-*` surveys.

## Filename

```text
RSCH-####-<slug>.md
```

Create new surveys with:

```bash
agent-continuity docs new research "<Title>" --domain <domain>
```
