# Research Survey Template

Use this for `RSCH-*` docs: sourced surveys that answer "what options exist?" before the team is ready to choose, specify, evaluate, or build.

Create new surveys with:

```bash
agent-continuity docs new research "<Title>" --domain <domain>
```

---
type: research-survey
id: RSCH-####
title: <Research Survey Title>
domain: <product | architecture | repo-health | research | operations | marketing>
status: draft
created_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
updated_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
owner:
question:
source:
  type:
  link:
  notes:
external_sources: []
repo_findings: []
agent_notes: []
related_ideas: []
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

# RSCH-#### - <Research Survey Title>

## Question

State the research question in one sentence.

## Context

Why does this need a survey instead of a quick answer or raw idea?

## External Sources

Separate external sources from repo facts and agent summaries.

## Repo / Internal Findings

Facts from this repo, local experiments, existing docs, or code.

## Agent Notes

Subagent findings or chat-derived summaries. Mark these as synthesis, not primary evidence.

## Options Compared

## Findings

## Risks / Unknowns

## Recommendation

Give a shortlist, recommended next step, or next-question set. Do not lock durable architecture decisions here; use an ADR when needed.

## Follow-Ups

- <Next survey, evaluation, spec, ADR, or plan to create>
