# Explainers

Explainers are durable human-facing teaching docs. Use `EXPL-*` when a concept, workflow, diagram, or mental model needs a stable reference outside chat.

Explainers teach how something works. They are not records of what the team learned; use `LRN-*` learning records for that. They are not unresolved issues; use `QST-*` questions for durable uncertainty. They are not source-of-truth decisions; use ADRs for that.

Create a new explainer with:

```bash
agent-continuity docs new explainer "Title" --domain orientation
```

## When To Create One

Create or update an `EXPL-*` when:

- the human asks "I do not understand this" and the explanation is likely to recur
- a future human or agent would benefit from a stable teaching doc
- a visual map would reduce cognitive load
- onboarding, architecture, a seams guide, or a testing guide would become too long if it carried the explanation inline

Do not create one when:

- the answer is one-off chat help
- the content is actually current truth, architecture truth, a decision, a requirement, or execution scope
- the content records a corrected assumption; use an `LRN-*` learning record instead
- the content is unresolved; create or link a `QST-*` question instead

## Visualization Pass

Use a visualization pass when a diagram clarifies architecture, data flow, boundaries, state, or behavior better than prose alone.

Prefer one strong diagram over several average ones. Default to Mermaid, keep scope tight, name ownership boundaries, and label inference when the diagram is not proven directly from source docs or code.

## Template

Start from `EXPL-0000-explainer-title.md` or `agent-continuity docs new explainer`.
