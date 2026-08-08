---
type: architecture-area
id: AREA-EXAMPLE
title: Example
domain: architecture
status: draft
created_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
updated_at: "YYYY-MM-DD HH:MM:SS TZ +0000"
owners: []
related_specs: []
related_adrs: []
related_plans: []
related_sessions: []
related_issues: []
related_prs: []
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# AREA-EXAMPLE - Example

Use this doc for one stable architecture area. The `id` and filename must match:

```text
docs/architecture/areas/AREA-EXAMPLE.md
```

## Owns

- <boundary, subsystem, or responsibility>
- <boundary, subsystem, or responsibility>

## Does Not Own

- <nearby boundary owned elsewhere>
- <nearby boundary owned elsewhere>

## Stable Invariants

- <rule that should survive refactors>
- <rule that should survive refactors>

## Domain Language

Use this section when the area owns important terms, lifecycle states, actors, or product concepts.

| Term | Meaning | Notes |
|---|---|---|
| `<term>` | <canonical meaning> | <aliases, rejected names, or source docs> |

## Interfaces / Seams

Use this section for caller-facing contracts owned by the area.

| Interface | Caller | Owns | Does Not Own |
|---|---|---|---|
| `<interface or seam>` | <caller> | <responsibility> | <nearby responsibility owned elsewhere> |

## Intended Flow

1. <step>
2. <step>
3. <step>

## Current Mismatch Notes

- <where current implementation differs from intended architecture>
- <what not to mistake for a stable rule>

## Related Areas

- `AREA-<OTHER>` - <relationship>

## Related Docs

- <spec, ADR, plan, session log, or source-of-truth doc>

The area doc is a boundary contract. Keep vocabulary and interfaces stable here; put execution sequencing in plans, receipts in session logs, and durable rationale in ADRs.
