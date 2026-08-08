# Questions

Questions preserve durable uncertainty with a stable `QST-*` ID.

Use `QST-*` only when unresolved uncertainty needs status, ownership, links, or resolution history across sessions. Ask ordinary clarification questions in chat. Keep local questions inside specs, plans, briefs, research notes, session logs, explainers, or learning records until they need that lifecycle.

Create a new question with:

```bash
agent-continuity docs new question "Title" --domain product
```

## Statuses

```text
open
investigating
answered
deferred
superseded
archived
```

`answered` questions should include `resolution` or `resolved_by`. `superseded` questions should include `superseded_by` or `reason`.

## Template

Start from `QST-0000-question-title.md` or `agent-continuity docs new question`.
