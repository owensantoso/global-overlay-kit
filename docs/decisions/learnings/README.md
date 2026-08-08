# Learning Records

Learning records preserve durable lessons learned.

Use `LRN-*` records when the project, human, or agent learned something that should survive the chat and change future behavior. Good examples include corrected assumptions, surprising runtime/tooling discoveries, plan corrections, and lessons from mistakes or repeated confusion.

Do not use learning records to teach a concept from scratch. Use `EXPL-*` explainers for human-facing explanations. Do not use learning records for unresolved uncertainty; use `QST-*` questions when the uncertainty needs lifecycle tracking.

Create a new learning with:

```bash
agent-continuity docs new learning "Title" --domain repo-health
```

## When To Create One

Create or update an `LRN-*` when:

- the human corrects an agent assumption and the correction matters later
- a plan, prompt, tool, or docs convention caused a repeated mistake
- a surprising implementation or runtime lesson should prevent future rework
- a conversation changes how future agents should approach the repo
- an explanation revealed a lesson about the workflow itself

Do not create one when:

- the answer is teaching material; create or update an `EXPL-*` instead
- the content is actually a decision that should be an ADR
- the content is an unresolved question that should be a `QST-*` or local open question
- the content is routine implementation narration that belongs in a session log

## Open Questions

Keep open questions in the lowest owning artifact first: spec, plan, implementation brief, research note, session log, explainer, or learning record.

Create a `QST-*` only when the question needs durable status, ownership, links, or resolution history across sessions. Promote a question to `TODO-*` only when it needs action, verification, or closeout.

## Template

Start from `LRN-0000-learning-title.md` or `agent-continuity docs new learning`.
