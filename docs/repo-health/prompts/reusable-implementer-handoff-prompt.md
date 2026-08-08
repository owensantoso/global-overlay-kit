# Reusable Implementer Handoff Prompt

Use this when starting a new implementation session or handing a milestone to a new main implementing agent.

## Prompt

```text
Start by reading, in order:

1. docs/orientation/CURRENT_STATE.md
2. docs/orientation/ONBOARDING.md or equivalent orientation doc
3. docs/orientation/ROADMAP.md
4. docs/orientation/ARCHITECTURE.md
5. the relevant `SPEC-*` doc
6. the parent plan doc
7. the relevant implementation brief(s)
8. AGENTS.md and any surface-level AGENTS.md you touch

Use subagent-driven development where it helps. Preserve your own precious context: do not try to hold the whole milestone in one head if bounded delegation can move the work forward safely. Delegate concrete, well-scoped tasks when possible, especially sidecar work that does not block your immediate next step.

Do not implement from plans blindly. Plans are plans, not gospel. If something in the plan seems stale, contradictory, or mismatched with the codebase or current docs, do not silently force the code to match it. Bring the mismatch back to the main agent, explain it, and escalate before committing to the wrong shape.

Parent plan intent and boundaries win over implementation-brief detail. Implementation briefs win on task-level execution order and verification. If either seems wrong, fix the docs or raise it. Do not just plow ahead.

Also: leave unrelated local files alone unless your task is explicitly about them.

At closeout, update the compact state doc if current truth changed, update plan/brief status or checklists, add a timestamped session log for meaningful work, and include commit trailers if you commit.
```

## Why this exists

This prompt gives fresh sessions a stable boot path so they rely on repo docs instead of old chat memory.
