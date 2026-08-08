# Ontology Audit Guide

## Use When

- Names are overloaded or confusing.
- Multiple docs use different terms for the same concept.
- Source-of-truth and derived-record boundaries are unclear.
- Users or agents are repeatedly confused by a model.

## Inputs

- Concepts, ADRs, specs, and architecture docs.
- Current state and onboarding docs.
- Code models, schema names, API names, and UI labels.
- Prior questions or learnings about terminology.

## Core Questions

- Which terms are canonical?
- Which terms are synonyms, legacy terms, or UI labels?
- Which records are source-of-truth, derived, cached, or rendered?
- Which terms deserve a concept doc, ADR, or rename?
- Where would a new agent learn this vocabulary?

## Checks

```bash
rg -n "<term-a>|<term-b>|<legacy-term>" docs src packages
```

Adjust paths for the target repo.

## Finding Categories

- overloaded term
- hidden synonym
- source-of-truth ambiguity
- stale concept
- missing canonical definition
- UI/domain mismatch

## Routing Guidance

| Finding Looks Like | Route To |
|---|---|
| Needs model exploration | `CONC` |
| Needs durable naming decision | `ADR` |
| Needs user-visible behavior language | `SPEC` |
| Needs code/schema rename | `PLAN` / `IMPL` |
| One small doc correction | direct edit or `TODO` |

## Done When

- Each major ambiguous term has an owner doc or an explicit deferral.
- Findings distinguish naming preference from actual source-of-truth risk.
