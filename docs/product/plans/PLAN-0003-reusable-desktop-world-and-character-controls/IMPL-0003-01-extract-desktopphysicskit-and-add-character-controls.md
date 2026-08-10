---
type: implementation-brief
id: IMPL-0003-01
title: Extract DesktopPhysicsKit And Add Character Controls
domain: product
status: in_progress
created_at: "2026-08-10 00:17:57 JST +0900"
updated_at: "2026-08-10 00:41:00 JST +0900"
parent_plan: PLAN-0003
task_refs:
  - PLAN-0003-task-2
  - PLAN-0003-task-3
  - PLAN-0003-task-4
owner:
areas: [AREA-DESKTOP-PHYSICS, AREA-OVERLAY-HOST]
depends_on: [PLAN-0002, RSCH-0002]
parallel_with: []
related_specs:
  - SPEC-0002
related_adrs: [ADR-0001, ADR-0002]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
related_issues: []
related_prs: []
linked_paths:
  - Examples/DesktopPhysicsDemo/Package.swift
  - Examples/DesktopPhysicsDemo/Sources/DesktopPhysicsKit
  - Examples/DesktopPhysicsDemo/App/Sources
  - Examples/DesktopPhysicsDemo/Tests/DesktopPhysicsKitTests
  - run
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# IMPL-0003-01 - Extract DesktopPhysicsKit And Add Character Controls

## Parent Plan

- [PLAN-0003](PLAN-0003-reusable-desktop-world-and-character-controls.md)

## Task Goal

Extract the reusable desktop-world seam and prove it with varied objects,
cursor collision, and one safely controlled jumping character.

## Scope

In scope:

- nested library target and public command API
- circle/square/triangle plus size variants
- optional cursor collider using global cursor position only
- one circular player with horizontal movement and grounded jump
- explicit selective control mode with Command-modifier pass-through
- focused tests, demo UI, diagnostics, docs, and physical acceptance

Out of scope:

- standalone repository/release, custom engine, ECS, general input mapping
- click-drag/throw, multiple players, levels, sprites/assets, multi-display
- swallowing arbitrary keys or Command-modified events

## Execution Steps

1. Complete prior-art and native-input research; accept or revise the proposed
   boundary.
2. Add `DesktopPhysicsKit` product/target and migrate scene/controller code.
3. Define small spawn shape/size/configuration types and `DesktopPhysicsWorld`.
4. Update the demo to call only the library API.
5. Add cursor collision and focused coordinate-mapping tests.
6. Implement the selected control mechanism with explicit teardown and
   Command-modifier bypass.
7. Add player movement/jump and grounded-state tests where deterministic.
8. Run automated and physical protocols; update the plan/current state.

## Verification

```bash
swift test --package-path Examples/DesktopPhysicsDemo
./run check
```

Physical:

- spawn each shape and multiple sizes
- move cursor through objects while clicking the app underneath
- enable controls, move left/right, jump, reject mid-air repeat jump
- press Command-Tab while controls are enabled
- disable controls from the visible window and confirm keys return to normal

## Done Checklist

- [x] Implementation complete
- [ ] Verification complete
- [x] Prior-art and input gates resolved
- [ ] Physical recovery and Command-Tab verified
