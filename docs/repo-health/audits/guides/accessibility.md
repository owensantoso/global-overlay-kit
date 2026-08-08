# Accessibility Audit Guide

## Use When

- A UI, app, website, or interactive workflow needs inclusive access review.
- New screens or controls are ready for implementation or release.
- Users may rely on keyboard, screen readers, Dynamic Type, captions, contrast, or reduced motion.

## Inputs

- Product specs and UI flows.
- Screenshots, prototypes, or running UI.
- Accessibility guidelines relevant to the platform.
- UI component code and test plans.

## Core Questions

- Can the core workflow be completed with assistive technologies?
- Are controls labeled with their purpose and state?
- Does text scale and remain readable?
- Are contrast, focus, motion, touch target, and keyboard expectations met?
- Are media or audio experiences accessible?

## Checks

Use platform-specific accessibility tooling where available. For docs-only review, inspect specs and UI code for labels, focus, motion, and text-scaling assumptions.

## Finding Categories

- missing label
- hidden state
- focus/navigation trap
- text scaling failure
- contrast or motion risk
- inaccessible media

## Routing Guidance

| Finding Looks Like | Route To |
|---|---|
| Need UI requirement | `SPEC` |
| Need implementation | `PLAN` / `IMPL` |
| Need runtime verification | `DIAG` |
| Need design decision | `ADR` |
| Small label/doc fix | direct edit or `TODO` |

## Done When

- Findings focus on user impact, not only checklist terms.
- Follow-ups include verification on the relevant platform or viewport.
