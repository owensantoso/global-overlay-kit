---
type: session-log
title: Project Foundation And Overlay Boundary
domain: repo-health
status: in_progress
created_at: "2026-08-09 03:45:00 JST +0900"
updated_at: "2026-08-09 03:58:00 JST +0900"
started_at: "2026-08-09 03:45:00 JST +0900"
ended_at:
timezone: "JST +0900"
participants:
  - Human
  - Codex
areas: [AREA-OVERLAY-HOST]
related_plans: [PLAN-0001]
related_briefs: [IMPL-0001-01]
related_specs: [SPEC-0001]
related_adrs: [ADR-0001]
related_todos: []
related_issues: []
related_prs: []
commits: []
---

# 2026-08-09 - Project Foundation And Overlay Boundary

## Goal

Create a separate GlobalOverlayKit repository, implement the smallest
renderer-neutral macOS host, and preserve the architecture/research boundary in
the full Agent Continuity scaffold.

## Timeline

- 2026-08-09 03:45 JST - Confirmed that the reusable unit is a native overlay
  surface host, not Live Text Chat's complete message presentation.
- 2026-08-09 03:50 JST - Agent Continuity tooling assigned the initial research,
  ADR, spec, plan, brief, idea, and explainer IDs.
- 2026-08-09 03:52 JST - Clean-room AppKit package source and focused tests
  landed in parallel with documentation work.
- 2026-08-09 03:58 JST - Synchronized orientation and boundary docs with the
  actual public API while preserving physical behavior as unverified.

## Context Read

- [Current state](../../orientation/CURRENT_STATE.md)
- [Architecture](../../orientation/ARCHITECTURE.md)
- [SPEC-0001](../../product/specs/SPEC-0001-global-overlay-surface-host.md)
- [ADR-0001](../../decisions/adr/ADR-0001-keep-content-and-product-behavior-outside-the-overlay-host.md)
- [RSCH-0001](../../research/RSCH-0001-global-overlay-prior-art-and-package-boundary.md)

## Changes

- `AREA-OVERLAY-HOST`: defined the package's ownership and content seam.
- Added initial AppKit package source, SwiftUI adapter, configuration, tests,
  local command baseline, CI workflow, license, and contributor guidance.
- Replaced generic orientation/repo-health templates with project-specific
  current state, architecture, roadmap, codebase, seams, and testing guidance.
- Captured the first spec, accepted ADR, parent plan, bounded implementation
  brief, SpriteKit falsification idea, prior-art survey, and open-source
  contribution explainer.

## Decisions

- Decision: use one separate GlobalOverlayKit package with one renderer-neutral
  AppKit host and SwiftUI convenience.
  - Why: Agent Commander's message overlay and a desktop game share surface
    mechanics but not their product or renderer lifecycle.
  - Source of truth: `ADR-0001` and `AREA-OVERLAY-HOST`.
- Decision: keep implementation clean-room from Apple APIs.
  - Why: prior-art and consumer code are evidence, not implementation donors.
  - Source of truth: `SPEC-0001` and `RSCH-0001`.

## Verification

- Commands run during drafting:
  - Agent Continuity ID allocation and document creation commands.
  - Read-only source and package inspection.
  - Primary-source GitHub/Apple research.
- Closeout commands: pending final docs generation, checks, links, smoke, and
  package baseline.
- Manual checks: none.
- Not run: physical overlay, visual, accessibility, multi-display, performance,
  or remote-CI verification.

## Follow-Ups

- Integrate Agent Commander as the first physical consumer.
- Record a bounded physical evidence matrix before release-quality claims.
- Build the SpriteKit falsification prototype only after the message consumer
  identifies actual API friction.
- Tag a first semantic version only after consumer and evidence hardening.
