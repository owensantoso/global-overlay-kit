---
type: implementation-brief
id: IMPL-0002-01
title: Build And Physically Verify The Desktop Physics Demo
domain: product
status: completed
created_at: "2026-08-09 23:40:33 JST +0900"
updated_at: "2026-08-10 00:18:00 JST +0900"
parent_plan: PLAN-0002
task_refs:
  - PLAN-0002-task-2
  - PLAN-0002-task-3
owner:
areas: [AREA-OVERLAY-HOST]
depends_on: [PLAN-0001]
parallel_with: []
related_specs:
  - SPEC-0001
related_adrs: [ADR-0001]
related_sessions:
  - 2026-08-09-desktop-physics-falsification-demo
related_issues: []
related_prs: []
linked_paths:
  - Examples/DesktopPhysicsDemo
  - run
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# IMPL-0002-01 - Build And Physically Verify The Desktop Physics Demo

## Parent Plan

- [PLAN-0002](PLAN-0002-desktop-physics-falsification-demo.md)

## Task Goal

Build and launch the smallest useful physics-overlay consumer while preserving
the package boundary and separating automated evidence from physical behavior.

## Scope

In scope:

- one nested SwiftPM executable consumer
- one main-display, visible-frame, pass-through overlay
- transparent `SKView`, `SKScene`, gravity, edge collision, and circular bodies
- normal-window Spawn Ball, Clear, Show/Hide, and Quit controls
- root and consumer builds plus a bounded human observation

Out of scope:

- click-drag, global keys, Accessibility permission, controller input
- custom physics, characters, jumping, throwing, or a pixel renderer
- multi-display coordination and display-topology observation
- changes to the root library API unless the experiment exposes a generic bug

## Execution Steps

1. Create `Examples/DesktopPhysicsDemo` as a separate package depending on the
   repository root.
2. Implement a main-actor scene controller that embeds a transparent `SKView`
   and owns ball spawn/clear behavior.
3. Use the existing `GlobalOverlay` public initializer with `.passThrough`
   interaction and the main screen's visible frame.
4. Add a small SwiftUI app/window that owns the overlay lifecycle and exposes
   safe controls.
5. Add `./run demo` and include the example build in `./run check`.
6. Build, test, launch, and ask for an explicit visible/physical receipt.

## Verification

```bash
swift build
swift test
swift build --package-path Examples/DesktopPhysicsDemo
./run docs
git diff --check
```

Then launch `./run demo` and check, separately:

- a spawned ball is visible above another app
- it falls and bounces against the visible-frame bottom
- clicks outside the control window reach the app underneath
- Clear, Show/Hide, and Quit remain available

## Done Checklist

- [x] Implementation complete
- [x] Automated verification complete
- [x] Physical observation recorded
- [x] Root public API remains renderer-neutral

The clean second run visibly rendered multiple spawned balls over another app.
The project owner explicitly rejected the initial fast/jittery tuning, then
reported that the corrected result looked good after gravity and restitution
were fixed. Pointer pass-through was consistent with interacting with other
applications while balls remained visible. Broader Hide/Show and macOS matrix
coverage remains documented outside this bounded brief.
