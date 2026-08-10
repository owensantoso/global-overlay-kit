---
type: plan
id: PLAN-0003
title: Reusable Desktop World And Character Controls
domain: product
status: in_progress
created_at: "2026-08-10 00:17:57 JST +0900"
updated_at: "2026-08-11 04:57:05 JST +0900"
owner:
sequence:
  roadmap: "3.0"
  sort_key: "003.000"
  lane: product
  after: [PLAN-0002]
  before: []
areas: [AREA-DESKTOP-PHYSICS, AREA-OVERLAY-HOST]
related_specs:
  - SPEC-0002
related_adrs: [ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
related_issues: []
related_prs: []
linked_paths:
  - Examples/DesktopPhysicsDemo
  - run
repo_state:
  based_on_commit: efaf82d290a31a5cab0142cf1a1afa50112d89b9
  last_reviewed_commit: efaf82d290a31a5cab0142cf1a1afa50112d89b9
---

# PLAN-0003 - Reusable Desktop World And Character Controls

## Goal

Turn the accepted one-off physics demo into a small reusable desktop-world
adapter, then use that adapter to prove varied shapes, cursor interaction, and
an animated platform character without changing GlobalOverlayKit's public
product boundary.

## Architecture

- SpriteKit remains the actual engine.
- A proposed pure `DesktopGameCore` target owns portable state, semantic
  inputs/events, stable session identities, and deterministic gameplay
  policies. It imports no Apple UI/graphics framework and no game engine.
- A `DesktopPhysicsKit` library target owns the overlay/scene integration,
  SpriteKit authority, desktop objects, cursor collider, player runtime, and
  control-mode lifecycle.
- `DesktopPhysicsDemo` becomes a thin SwiftUI caller of that library.
- The target remains inside the nested example package for this milestone so
  extraction stays reversible while the API is still being learned.
- `GlobalOverlayKit` remains unchanged except for generic defects proven by the
  consumer.
- App Intents and Shortcuts integration stays in the demo executable and calls
  the existing `DesktopPhysicsWorld` command surface.
- Prior-art and native-input research are gates, not post-hoc justification.
- DesktopSurfaceKit's local `desktop-window-feed` and the multiplayer
  `desktop-game-state` protocol remain independently versioned seams.

## Task Dependencies / Parallelization

1. `PLAN-0002`, `SPEC-0002`, and `ADR-0001` establish the prerequisite host and
   content boundary.
2. `RSCH-0002` prior-art research and native macOS input research run in
   parallel before the final reusable contract is accepted.
3. Library extraction and shape/cursor work proceed only if the prior-art scan
   confirms no exact adoptable package.
4. Character controls depend on the safe native input mechanism and permission
   boundary.
5. Automated tests precede physical keyboard and cursor acceptance.

## Implementation Tasks

### Task 1: Research And Boundary Gate

- Compare exact and adjacent open-source macOS options.
- Compare local key monitoring, global monitors, event taps, and hotkeys.
- Accept, revise, or reject `ADR-0002` before freezing the target/API shape.

### Task 2: Extract The Reusable Target

- Add a `DesktopPhysicsKit` library product/target to the nested package.
- Introduce a small `DesktopPhysicsWorld` command API.
- Move SpriteKit controller, scene, lifecycle, and diagnostics behind it.
- Keep the demo model/view in the executable target.

### Task 3: Shapes, Sizes, And Cursor

- Add circle, square, triangle, and random shape selection.
- Add small, medium, large, and random sizing.
- Add an opt-in cursor-following physics collider without pointer interception.
- Replace fixed-only sizing in the demo with continuous object/cursor controls
  and a two-handle random-size range.
- Add an explicit click-drag mode for spawned objects. Make the pointer-routing
  tradeoff visible and keep the control window above the interactive overlay.
- Derive bounded release velocity from recent drag motion so flicks throw and
  stationary releases drop.

### Task 4: Character Controls

- Spawn one player and let the caller choose Stick Figure, Circle, Square,
  Triangle, or Random appearance.
- Add an interruptible authored-frame renderer for idle, walk, run, jump,
  wall-slide, and sit, with left/right mirroring, source/license provenance,
  and a Reduce Motion path.
- Add left/right movement and grounded jump.
- Add Shift-to-run and C sit/stand without weakening shortcut pass-through.
- Add side wall probes, sticky capped wall descent, recent-wall grace, and a
  primarily vertical wall jump with a modest away push and short steering lock.
- Use a measurable reusable controller profile with buffered jump, coyote time,
  post-physics ground probes, variable-height release, and explicit horizontal
  acceleration.
- Add explicit control-mode activation/deactivation and preserve every
  Command-modified shortcut, especially Command-Tab.
- Provide a normal-window recovery control and clean monitor/tap teardown.
- Let the user select WASD-only, arrows-only, or both without changing the
  global safety and Command-shortcut policy.

### Task 5: Verification And Extraction Decision

- Add focused library tests and include them in `./run check`.
- Run visual/physical cursor, drag/release, walk/run/jump/wall-slide/wall-jump/
  sit animation, and Command-Tab checks.
- Record whether the nested target is ready for a second consumer; do not create
  a separate public repository merely because the first demo works.

### Task 6: Measure External Action Invocation

- Add a parameter-free **Spawn Random Object** App Intent and App Shortcut to
  the signed demo app.
- Add unified-log events and signpost intervals around intent entry and the
  synchronous world-spawn command without placing automation concerns in
  `DesktopPhysicsKit`.
- Verify whether the preconfigured App Shortcut is listable and runnable by the
  macOS `shortcuts` command. If it is not, record the boundary before adding a
  one-action user Shortcut.
- Measure warm and cold command-line invocation and preserve foreground-focus
  behavior as a separate acceptance criterion.
- Extend Hold Keys with one constrained Run Shortcut action only after the
  native invocation is proven. Measure snap resolution to action dispatch and
  physically verify one snap adds one visible object.
- Compare a constrained direct App Action after the Shortcuts menu-bar status
  UI proves distracting. Bind the action to the target bundle identifier,
  propagate one `run_id`, use a local notification while running, and retain a
  non-activating verified custom-URL fallback for cold launch.

### Task 7: Adapt Real macOS Windows Into Platforms

- Audit the historical `DesktopSurfaceKit` POC for source-of-truth, permission,
  filtering, coordinate, identity, update, occlusion, and live-evidence gaps.
- Do not depend on its dated non-git path. Adapt only the narrow window geometry
  seam into a version-controlled macOS-specific target.
- Let objects collide with full application-window rectangles while the player
  uses descending-from-above one-way top surfaces.
- Preserve small moves only for an already supported player; ignore new/large
  intrusions so moving or resizing windows cannot squish the character.
- Publish polling count and fail-off state to an ordinary visible control.
- Add a default-on testing visualization with cyan full-rectangle outlines for
  object collision, thicker capped yellow top edges for player landing, and a
  normal-window toggle. Keep the nodes click-through and physics-free, keyed by
  the same IDs and refresh lifecycle as the colliders.
- Keep full-frame occlusion and possible loose-object ejection explicit as
  experimental physical-verification gaps.

### Task 8: Gate Built-In Tilt Gravity On A Supported Sensor API

- Inspect this exact Mac's accelerometer and gyroscope without opening a live
  stream or changing hardware state.
- Separate public macOS motion APIs from private SPU/HID access, root helpers,
  and persistent services; include Bosch BMI286 and `spank` prior art.
- Add tilt only if a non-privileged, stable, proportional API is genuinely
  available. Otherwise preserve the defer verdict and implement no toggle,
  adapter, helper, daemon, service, or fake sample path.
- Current result: deferred by
  [RSCH-0009](../../../research/RSCH-0009-macos-built-in-inertial-sensor-readiness.md).
  Hardware presence is confirmed, but public supported MacBook chassis motion
  is not.

### Task 9: Extract Portable State And Engine-Neutral Rules

- Add a nested pure `DesktopGameCore` target before implementing further
  SpriteKit-only mechanics.
- Move portable identities, coordinates, game-state values, semantic inputs,
  events, controller policy, draggable selection, and wall traversal into the
  target without importing AppKit, Core Graphics, SpriteKit, or Godot.
- Model position, orientation, linear velocity, angular velocity, surfaces, and
  viewport depth in X/Y/Z from version 1. Keep the current desktop on `Z = 0`,
  preserve observation order separately as `desktopLayerRank`, and make the
  SpriteKit adapter reject unsupported nonplanar authority state.
- Keep physics bodies, contacts, velocity mutation, alpha-mask decoding/cache,
  pointer capture, animation textures, and interpolation in engine adapters.
- Define version-1 snapshot/delta fixtures and privacy assertions. Keep local
  application/window metadata out of remote state by default.
- Make SpriteKit the first authority and prove a Godot fixture consumer before
  extracting the target into another repository.
- Implement painted-pixel player selection through a current-frame mask and
  implement feature-scoped wall traversal only after the pure seams exist.
- Remove the Accessibility trust gate from permission-free window geometry.
  Add focused-window observation only through a separately approved optional
  DesktopSurfaceKit product and release candidate.

## Validation

```bash
./run check
./run demo
./run demo-trace
```

Physical protocol must include toggling controls off again and using
Command-Tab while controls are on. A permission prompt, enabled tap, or moving
character alone does not prove safe recovery.

The window-platform protocol additionally covers one ordinary object bouncing
on a window, player landing from above and passing through from below, a moved
and resized support window, a newly overlapping loose object, current-Space
filtering, and one secondary-display arrangement.
With outlines enabled, the visible count must match the cyan rectangles, every
rectangle must have one thicker capped yellow top edge, and move/resize/
minimize/close changes must track within the 500 ms refresh. Disabling only the
outline toggle must remove the visuals immediately while collisions continue;
disabling window platforms must remove both visuals and collisions. Desktop
clicks must continue to pass through while object-drag mode is off.

Portable-state validation additionally requires golden Swift/Godot fixtures,
snapshot/delta loss and recovery cases, privacy-safe default packets,
coordinate conversion fixtures, and matching opaque/transparent asset points.
Cross-engine acceptance compares semantic surfaces, entity poses, animation,
and events rather than identical physics trajectories. A depth-moving fixture
must be accepted by Godot and explicitly rejected by the planar SpriteKit
adapter.

## Completion Criteria

- Prior art is recorded and the adopt/adapt/build decision is explicit.
- The executable uses `DesktopPhysicsKit` as a library product.
- Shapes and sizes spawn through the reusable API.
- Cursor movement visibly affects objects without blocking clicks.
- Direct manipulation makes a selected object follow the pointer and returns
  to click-through when disabled.
- The player moves and jumps only while controls are enabled.
- Command-Tab remains normal and controls can always be disabled from the
  visible window.
- Focused tests and `./run check` pass.
- Physical results, permissions, limitations, and extraction status are
  recorded without claiming a general-purpose engine.
- The App Intent path has measured warm/cold software timings and a separate
  physical snap-to-visible result before any custom action SDK is proposed.
- The direct comparison records the software endpoint at
  `world.spawn.completed`, proves the installed target window can reopen from
  the Dock, and keeps the saved Shortcut only as a fallback/comparison.
- Window rectangles are optional and visible in the control state; focused
  policy/lifecycle tests, outline lifecycle/nonphysics tests, and signed-app
  physical behavior are recorded separately before the feature is called
  accepted.
- A peer can reconstruct one fixture world from `desktop-game-state` without
  receiving screen pixels, local app/window identity metadata, or engine
  objects.

## Physical Acceptance Receipt

The first signed-app run produced mixed evidence:

- Accepted: overlay presentation and varied shapes looked very good.
- Accepted with refinement: cursor collision felt very good and clicks passed
  through; add continuous hitbox sizing from effectively tiny to very large.
- Accepted: Accessibility permission and control-mode activation completed.
- Failed: A/D only partly moved, arrow keys did nothing, and W/jump was absent
  or imperceptibly small. Character controls remain incomplete regardless of
  passing pure-state tests.
- Follow-up result after the derived controller, arrow handling, buffering, and
  ground-probe repair: “way better.” Exact control-scheme and player-shape
  options were then requested for the next build.
- Follow-up result for Circle/Square/Triangle/Random players and WASD/Arrows/
  Both modes, including Command-Tab and turning controls off: “all good.”
- The first procedural stick-figure renderer failed physical visual acceptance;
  its poses looked bad. It was replaced with selected authored CC0 frames. The
  wall jump was retuned to favor vertical motion and player restitution was set
  to zero. This corrected signed-app visual/feel verdict remains pending.
