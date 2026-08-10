---
type: plan
id: PLAN-0002
title: Desktop Physics Falsification Demo
domain: product
status: completed
created_at: "2026-08-09 23:40:33 JST +0900"
updated_at: "2026-08-10 00:18:00 JST +0900"
owner:
sequence:
  roadmap: "2.0"
  sort_key: "002.000"
  lane: product
  after: []
  before: []
areas: [AREA-OVERLAY-HOST]
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

# PLAN-0002 - Desktop Physics Falsification Demo

## Goal

Prove that the existing renderer-neutral overlay host can present a continuously
rendered SpriteKit physics scene above ordinary macOS applications without
adding game or renderer concepts to the `GlobalOverlayKit` library target.

## Architecture

- A nested example package is a real consumer of the root package through a
  local Swift Package Manager dependency.
- A caller-owned `NSViewController` hosts a transparent `SKView` and `SKScene`.
- SpriteKit's `SKPhysicsWorld` owns gravity, collision boundaries, and ball
  simulation; no custom physics engine is created.
- One pass-through overlay fills the main display's visible frame so the Dock
  and menu bar remain usable.
- A separate normal SwiftUI control window provides Spawn Ball, Clear, and
  Show/Hide actions plus an obvious Quit/recovery route.
- The library target and public API remain unchanged unless observed behavior
  proves a renderer-neutral correction is necessary.

## Task Dependencies / Parallelization

1. The completed `PLAN-0001` host and `SPEC-0001` contract are prerequisites.
2. Update the promoted idea, roadmap, and current state before implementation
   so the changed consumer order survives the conversation.
3. Implement the scene/controller and control window as one bounded slice;
   their lifecycle is tightly coupled for this proof.
4. Automated build/check evidence can be gathered before launch. Visual and
   physical observations require a separate human receipt after launch.

## Implementation Tasks

### Task 1: Promote And Bound The Experiment

- Promote `IDEA-0001` to this plan.
- Choose one display, the visible frame, and pass-through interaction.
- Keep click-drag and global input out of the first slice because a full-screen
  interactive surface would intercept underlying application clicks.

### Task 2: Build The Nested Consumer

- Add an example executable package that depends on the root package.
- Present a transparent SpriteKit scene through the public
  `NSViewController` initializer.
- Spawn circular bodies near the top, apply gravity, and bounce them from an
  edge-loop boundary.
- Provide normal-window controls for spawn, clear, overlay visibility, and
  quitting.

### Task 3: Verify Without Overclaiming

- Build the root package and nested consumer.
- Run the root tests and documentation checks.
- Launch the consumer and separately record whether the overlay is visible,
  animated, click-through, and recoverable.
- Preserve untested Spaces, full-screen, multi-display, accessibility, and
  performance claims as open evidence.

## Validation

Automated baseline:

```bash
./run check
```

Interactive launch:

```bash
./run demo
```

The physical receipt must state what a human actually observed. A successful
build or a running process alone does not prove pixels, gravity, bounce,
click-through behavior, or focus preservation.

Current receipt: automated checks pass and a clean run visibly rendered
multiple balls over another app. The first run failed because controller
installation collapsed the host frame; that generic defect now has a regression
test. The project owner then reported that initial gravity was too fast and
floor motion jittered. Bounded trajectory logging exposed a `-980` versus
SpriteKit's documented `-9.8` unit error and persistent collision velocity; the
corrected trace reaches a stable floor position and zero vertical velocity.
On 2026-08-10 the project owner reported that the tuned demo looked good and
immediately promoted shapes, cursor interaction, reuse, and a controllable
character into a new milestone. Remaining broader macOS behavior gaps stay
recorded in current state rather than blocking this bounded falsification plan.

## Completion Criteria

- The nested consumer compiles against the public GlobalOverlayKit API.
- Spawn Ball creates a visible body that falls and bounces on one display.
- Clear removes bodies and Show/Hide controls the surface.
- The overlay remains pass-through and a normal control window remains usable.
- No SpriteKit or physics type is added to the root library API.
- `./run check` passes.
- Physical results and remaining evidence gaps are recorded.
