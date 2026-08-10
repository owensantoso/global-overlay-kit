---
type: spec
id: SPEC-0002
title: Reusable Desktop Physics World
spec_type: feature
domain: product
status: approved
created_at: "2026-08-10 00:17:57 JST +0900"
updated_at: "2026-08-11 04:57:05 JST +0900"
owner:
source:
  type: conversation
  link:
  notes:
areas: [AREA-DESKTOP-PHYSICS]
related_plans: [PLAN-0003]
related_issues: []
related_prs: []
related_adrs: [ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
supersedes: []
superseded_by: []
linked_paths:
  - Examples/DesktopPhysicsDemo
repo_state:
  based_on_commit: efaf82d290a31a5cab0142cf1a1afa50112d89b9
  last_reviewed_commit: efaf82d290a31a5cab0142cf1a1afa50112d89b9
---

# SPEC-0002 - Reusable Desktop Physics World

## Summary

Create a small reusable desktop-world layer that combines GlobalOverlayKit's
transparent macOS surface with SpriteKit's existing 2D physics engine. The
layer should make ordinary experiments—spawn objects, collide with the cursor,
and control one jumping character—easy without turning GlobalOverlayKit into a
game engine or inventing a replacement for SpriteKit.

## Problem / Opportunity

The first ball demo proved the renderer-neutral host, but its scene, object
creation, physics configuration, and overlay lifecycle are tied to one
executable target. Future desktop toys would either copy that code or require
callers to understand AppKit, overlay geometry, SpriteKit view setup, and
physics details before they can create anything.

The project owner explicitly expects to reuse this capability across many
desktop experiments and has stated that game-engine architecture is unfamiliar.
The reusable contract therefore needs a small, legible caller API rather than
framework internals leaking into every project.

## Goals

- Reuse SpriteKit as the physics/game engine rather than recreate one.
- Provide one caller-facing desktop-world object with show/hide, spawn, clear,
  cursor-collision, and character-control operations.
- Support circles, squares, and triangles at small, medium, large, or random
  sizes.
- Let the visible macOS cursor push physics objects without making the overlay
  consume ordinary pointer clicks.
- Provide one appearance-selectable player, including a sprite-animated stick
  figure, that walks, runs, jumps, wall-slides, wall-jumps, and sits.
- Let the user explicitly enter a direct-manipulation mode where spawned
  objects follow click-drag input and resume physics on release.
- Make controls explicitly opt-in and recoverable from a normal window.
- Preserve Command-Tab and every Command-modified shortcut while controls are
  enabled.
- Keep the reusable layer separable from both GlobalOverlayKit and the demo UI.
- Let cooperating macOS automation surfaces invoke the same one-shot spawn
  command without moving gesture detection or action routing into this app.
- Let the user opt into real application windows as object obstacles and
  natural one-way player platforms without moving macOS observation into the
  generic overlay host.

## Non-Goals

- a new physics solver, game engine, entity-component system, level editor, or
  asset pipeline
- arbitrary key remapping or full-keyboard capture
- swallowing Command-modified shortcuts, automating other apps, or bypassing
  macOS input security
- multi-display worlds, saved scenes, networking, audio, scores, or gameplay
- a tagged public DesktopPhysicsKit release before prior-art review and a
  second consumer validate the interface
- a general cross-application action bus, arbitrary command execution, or a
  custom provider SDK before the native App Intents path is measured
- pixel-visible window silhouettes or collision with Accessibility element
  boundaries; rectangular front-to-back occlusion is an approximation rather
  than pixel visibility
- a root helper, private Apple SPU/HID contract, persistent sensor daemon, or
  implied live chassis-tilt control without a supported macOS motion API

## Current Behavior / Context

- GlobalOverlayKit hosts arbitrary `NSViewController` content and remains
  renderer-neutral.
- `Examples/DesktopPhysicsDemo` owns one transparent `SKView`, one `SKScene`,
  balls, gravity, boundaries, and a normal SwiftUI control window.
- The tuned demo is physically accepted for its current ball behavior.
- The code is reusable only by copying internal executable-target types.

## Desired Behavior / Target State

The nested consumer package exposes a `DesktopPhysicsKit` library product. Its
main-actor `DesktopPhysicsWorld` owns the overlay/scene integration and offers
domain-shaped commands. The executable target owns only control-panel state and
presentation.

The first public shape should be approximately:

```swift
let world = try DesktopPhysicsWorld(screen: screen)
world.show()
world.spawn(.init(shape: .triangle, size: .large))
world.setCursorCollisionEnabled(true)
world.setObjectDraggingEnabled(true)
world.spawnPlayer()
world.setControlsEnabled(true)
```

Callers should not need to construct `NSPanel`, `SKView`, `SKScene`, or
`SKPhysicsBody` for these common operations. Advanced scene customization is
deferred until a real consumer demonstrates the need.

## Requirements

### R1 - Preserve The Package Boundary

- `Sources/GlobalOverlayKit` must not import SpriteKit or define physics,
  entity, character, cursor, or input types.
- Desktop-world behavior must live in a separate `DesktopPhysicsKit` target.
- Portable state values and deterministic gameplay policies must move behind a
  pure `DesktopGameCore` target before the next engine-specific feature wave.
  That target must not import AppKit, Core Graphics, SpriteKit, or Godot.

### R2 - Reuse The Native Engine

- SpriteKit owns simulation, gravity, collision detection, bodies, and frame
  cadence.
- The adapter may configure and coordinate SpriteKit but must not duplicate its
  engine concepts without a caller-facing need.
- A future Godot adapter consumes the same canonical game-state values and
  rules. SpriteKit and Godot are not required to produce deterministic matching
  solver trajectories.

### R3 - Object Spawning

- Callers can request circle, square, triangle, or random shape.
- Callers can request small, medium, large, or random size.
- Physics bodies match the visible convex shape closely enough for the demo.
- Object mass scales with object area rather than using one fixed mass.
- Callers can specify a continuous object diameter instead of only named size
  presets.
- Random-size spawning accepts a minimum and maximum diameter. The demo exposes
  that range through a two-handle control spanning very small objects to
  approximately half the selected display's shorter dimension.

### R4 - Cursor Collision

- Cursor collision is optional and visible in the control window.
- The collider follows the global cursor only while it is inside the selected
  world frame.
- Enabling it must not make the overlay receive or block pointer clicks.
- The cursor collider diameter is adjustable continuously from an effectively
  point-sized collider to a deliberately large collider, with the visible halo
  matching the selected physics size.

### R5 - Character And Controls

- Player appearance can be Stick Figure, Circle, Square, Triangle, or Random.
  The stick figure uses a stable non-bouncing character physics body plus an
  independently animated sprite child; geometric appearances retain matching
  bodies.
- Character animation states are idle, walk, run, jump, wall slide, and sit.
  Facing is independent so walk/run/jump/wall-slide mirror left and right.
- Holding Shift while moving selects the authored run speed. Shift alone is a
  gameplay modifier; Command/Control/Option/Fn shortcuts still pass through.
- C toggles sitting. Movement or jump input exits sit, and sitting does not
  change the physics body each frame.
- Controls can be limited to WASD, limited to arrow keys, or enable both.
  Spacebar jump is an independent option: disabling it leaves W and/or Arrow Up
  active according to the selected movement scheme, including true WASD-only
  and arrow-only configurations.
- A grounded jump plus exactly one airborne double jump are admitted per
  landing. Held keys must not create unbounded repeated jumps, and a platform
  drop-through must not consume either jump.
- Holding the scheme's Down input (S and/or Arrow Down) while pressing Jump
  drops through only the one-way window edge currently supporting the player.
  It must not disable unrelated platforms or launch the player downward.
- Player feel is expressed through a reusable profile with authored run speed,
  jump height, time-to-apex, tap height, coyote time, and jump buffer. Derived
  velocity/gravity values must not be independently guessed.
- Grounding uses post-physics support probes rather than edge-loop contact-node
  identity.
- Side probes distinguish walls from floors. While airborne and moving into a
  wall, downward velocity is capped for a sticky gradual slide.
- A buffered jump may launch primarily upward with a modest away push from a
  current or very recent wall. A short steering lock preserves that initial
  push before air control resumes.
- While touching an enabled visible window-side wall, holding toward that wall
  and pressing Jump requests a directional wall phase: only coincident edges
  at that contacted x-coordinate are temporarily excluded until the player's
  previous-frame body is fully across the line. Holding away and pressing Jump
  keeps the ordinary outward wall jump. This is not global noclip.
- When visible window-side collision is enabled, double-tapping toward a wall
  and holding the second press requests a bounded wall run. The wall run
  requires live wall contact and ends on release, contact loss, timeout, or
  landing; ordinary wall slide remains the fallback.
- Running changes horizontal target speed and therefore jump distance while
  leaving the configured vertical jump impulse and height unchanged.
- The player can leave the selected scene above its top edge and fall back into
  view. Loose objects retain the existing closed display boundary.
- Controls have an explicit enabled/disabled state and visible recovery button.
- Command-Tab and every Command-modified event must pass through unchanged.
- Truly global exclusive controls use a Core Graphics event tap and therefore
  require macOS Accessibility permission. Permission must be requested only
  from an explicit user action, never at launch.

### R6 - Direct Object Manipulation

- Object dragging is an explicit mode and is off by default.
- Mouse-down on a spawned object suspends that body's simulation, mouse-drag
  moves it while preserving the original grab offset, and mouse-up restores
  dynamic physics.
- Release velocity comes from the most recent drag motion and is capped to a
  safe maximum. A quick flick throws; pausing before release drops the object
  without stale velocity.
- The controllable player can be dragged and flicked through the same explicit
  direct-manipulation mode as spawned objects. Active gameplay control must not
  fight the drag, and release restores the player body and controller state.
- Enabling direct manipulation does not make the entire screen-sized overlay
  interactive. Only an explicitly draggable object or player visual hit region
  captures pointer input while hovered; capture remains latched until mouse-up
  during an active drag. Empty desktop stays click-through.
- For textured players, “visual hit region” means a per-frame source-alpha
  sample of the currently rendered texture after node transforms. Transparent
  padding inside the sprite rectangle must remain click-through; the larger
  physics collider must not define mouse capture. Shape players and loose
  objects use their painted path rather than a rectangular node bound.
- The portable player visual names its asset revision, animation frame or
  phase, draw transform, and pick-mask reference. Each engine resolves and
  caches the mask locally; multiplayer state must not send per-frame pixels.
- Disabling or stopping ends any active drag and immediately returns every
  overlay point to click-through behavior.

### R7 - Diagnostics And Safety

- Bounded trajectory logging remains opt-in.
- The control window exposes object count, overlay state, cursor collision, and
  control mode.
- Quitting or disabling controls removes any global input tap and clears held
  keys.
- If macOS disables the tap or permission is missing, controls fail off rather
  than silently re-enabling or swallowing input.

### R8 - Packaging

- The demo executable depends on the library product rather than importing
  library implementation files into its own target.
- The nested package remains unreleased until the interface is reused by a
  second consumer or extracted into a dedicated repository.

### R9 - External One-Shot Spawn Action

- The demo app exposes **Spawn Random Object** as an App Intent and App
  Shortcut while `DesktopPhysicsKit` remains free of App Intents and Hold Keys
  types.
- External invocation reaches the same `DesktopPhysicsWorld.spawn` command as
  the visible Spawn button; the intent must not duplicate scene construction or
  physics behavior.
- Hold Keys owns snap detection, sequence resolution, and trigger-to-action
  binding. Desktop Physics owns only the action and its result.
- The first experiment is a discrete one-shot action. Press/release lifecycles,
  arbitrary shell commands, and a custom action-provider protocol remain out of
  scope.
- Native unified logging and signposts distinguish intent entry, domain-command
  dispatch, and command completion. Software timing ends when the SpriteKit
  scene accepts the node; only a physical visual check can establish when the
  object became perceptible on screen.
- The experiment separately measures warm and cold invocation, focus behavior,
  and the Shortcuts hop. The comparison path is a strict bundle-bound semantic
  action: a local notification while the target is running and a verified
  custom-URL cold-launch fallback. Both transports call the same world command.

### R10 - macOS Window Platforms

- Window platforms are optional, off by default, and controlled from the
  normal control window with visible status and recovery text.
- Canonical `DesktopSurfaceKit` owns on-screen application-window enumeration,
  live Core Graphics window IDs, filtering, and permission-free geometry. A
  narrow macOS-specific consumer adapter owns top-left-global to selected-scene
  coordinate conversion.
- Core Graphics supplies window IDs and frames without Accessibility
  permission. Missing Accessibility permission must not remove ordinary window
  platforms. Accessibility remains required only for global controls and the
  separately optional focused-window observer.
- The provider excludes the current process, desktop elements, nonzero window
  layers, transparent windows, small invalid frames, and nonregular apps. It
  clips qualifying frames to the one selected display.
- DesktopSurfaceKit subtracts front-to-back rectangular coverage before the
  consumer converts the remaining visible fragments to the selected scene.
  Fully covered windows contribute no geometry. This is deterministic rectangle
  geometry, not a promise about rounded corners or translucent pixels.
- Loose objects collide with the remaining visible static rectangles and use
  ordinary object restitution.
- The player ignores rectangle bodies. While player-window collision is
  enabled, both a visible window top edge and a visible window bottom edge act
  as ordinary one-way landing platforms: upward motion passes through from
  below, while a descending crossing from above lands and stands on the edge.
  Reconciliation must not squish the player when geometry moves or appears.
- Original visible left and right window edges are independently available as
  two-sided player collision walls. Their toggle is separate from horizontal
  one-way landing edges and debug outlines. Occlusion-cut edges never become
  player walls.
- Rectangle fragments created only by occlusion cuts remain object colliders
  but do not become player landing surfaces. A player surface must coincide
  with the original source window's still-visible top or bottom edge.
- A player already supported by the same stable window ID may follow a small
  move or resize. New intrusions, large geometry jumps, upward player velocity,
  invalid destinations, and lost overlap must detach or ignore support so a
  window cannot squish or trap the player.
- Geometry refreshes on a bounded polling cadence, preserves same-sized bodies
  by stable window ID, removes stale bodies, and publishes current count/fail-
  off state back to the visible controls.
- Visible-region observation, player-window collision, and debug outlines are
  independently switchable from the normal control window. Geometry polling
  remains active whenever any of those consumers needs it.
- The visualization outlines each visible rectangular fragment in cyan and
  marks the player's one-way top and bottom landing edges with thicker capped yellow
  lines so the two policies are inspectable at a glance.
- The normal control window exposes a jump-height slider in points. Its default
  preserves the authored 180-point jump and its upper range permits a jump near
  the selected display height; derived gravity, launch speed, release cap, and
  wall-jump vertical speed stay coherent with the selected height.
- Visualization nodes use the same stable IDs and refresh lifecycle as the
  collision bodies, have no physics bodies, and must disappear immediately
  when either window platforms or visualization is disabled. They remain
  click-through and cannot change collision geometry.
- Occlusion uses opaque rectangular subtraction. Rounded corners, translucent
  pixels, shadows, and irregular holes remain outside the visible-silhouette
  contract.

### R11 - Full Game Presentation

- A separate Game World Mode covers the selected overlay with an opaque white
  SpriteKit backdrop behind gameplay nodes, visually replacing the desktop
  without changing the observed geometry or activating another app.
- In Game World Mode, the actual enabled player-platform and wall edges render
  as black lines. The debug-outline toggle remains independent in normal
  desktop mode; Game World Mode supplies its own required platform rendering.
- Entering and leaving Game World Mode is one reversible, interruptible
  transition. The white backdrop opacity and platform styling move together,
  repeated requests for the current target are no-ops, and the latest request
  wins after rapid reversal.
- The default transition is a short ease-in/ease-out fade. With Reduce Motion
  enabled, the same complete end state is applied atomically without motion.
- Player, loose-object, input, collision, overlay-interaction, and control-panel
  state remain invariant across the visual transition.

### R12 - Reusable Visible Window Identity

- DesktopSurfaceKit preserves the live source window identifier, owning process
  metadata, and front-to-back source order for each observed window.
- Axis-neutral sides remain `minX`, `maxX`, `minY`, and `maxY`. In global Quartz
  coordinates, where Y increases downward, those map visually to left, right,
  top, and bottom respectively.
- Visible-region fragments expose which original source sides survive clipping,
  rather than forcing each consumer to reconstruct side identity. Edges created
  only by rectangular subtraction are distinguishable from original window
  edges.
- Window numbers are session-lifetime live-window identities; localized owner
  names and titles are display metadata, not durable application identity.
  Optional metadata is added only when the system source and availability
  contract are reliable enough to document and test.
- Optional focused-window status is resolved against one exact window snapshot
  by a separately imported, nonprompting Accessibility-backed product. Zero,
  multiple, unavailable, and permission-required results remain explicit; the
  package must never guess from frontmost z-order.

### R13 - Portable Multiplayer State And Engine Boundary

- Local macOS observation, canonical/network game state, engine-private solver
  state, and renderer-only state are separate ownership categories.
- A versioned `desktop-game-state` envelope carries a world-session ID,
  sequence, optional base sequence, tick, and one snapshot, delta, input, or
  event payload.
- Canonical snapshots use a right-handed three-dimensional world with X
  screen-right, Y screen-up, positive Z toward the viewer, negative Z into the
  world, and the collapsed desktop at `Z = 0`. Values use `Double`; adapters
  own Quartz/SpriteKit/Godot conversion.
- Entity pose uses a three-component position and normalized quaternion.
  Linear and angular velocity are three-component vectors. SpriteKit supports
  the planar subset and must reject nonplanar authoritative state rather than
  silently flattening it; Godot may consume full depth.
- Window-source front-to-back order is `desktopLayerRank` provenance, not game
  Z. The game separately assigns an extruded segment's collision depth range.
- A full snapshot contains privacy-filtered surfaces, rules, avatars, objects,
  gameplay-visible locomotion, and asset references. It never contains AppKit,
  Core Graphics, SpriteKit, or Godot types.
- Authority-minted entity IDs are never reused within a world session. Raw
  macOS window IDs remain local to an observation epoch; peers receive random
  session-local source aliases instead.
- App names, process IDs, titles, document metadata, and Window Server numbers
  are excluded from remote state by default. Focus sharing, if ever enabled,
  uses an explicit privacy-controlled source alias.
- New replicas and recovery paths receive full snapshots. Deltas name one
  exact base sequence; a missing or reordered base requires a full snapshot.
- One engine is authoritative. Version 1 replicates gameplay-visible state and
  events but does not promise exact authority-process migration of contact
  manifolds, solver warm-start state, or interpolation caches.
- Semantic inputs describe move, jump, run, drop-through, wall traversal, and
  drag lifecycle rather than raw macOS key codes or pointer events.
- JSON fixtures are the first compatibility format. A binary encoding is
  adopted only after measured payload or encode/decode cost fails an explicit
  budget, without changing domain meaning.

## Open Questions

- Should the eventual public identity be DesktopPhysicsKit, DesktopWorldKit, or
  a product name chosen after the second use?
- Should the shared multiplayer viewport use the selected display's full frame
  or visible frame, and should focus ever be shared behind a privacy toggle?
- Should desktop platforms span the full playable depth, occupy a narrow band
  around `Z = 0`, or recede as part of the flat-to-depth transition?
- What snapshot cadence, numeric quantization, and asset-distribution policy
  meet a measured two-player latency and bandwidth budget?
- Should cursor interaction remain a kinematic collider or become a field/force
  adapter after physical testing?
- Resolved: the saved-Shortcut path worked but showed macOS Shortcuts status UI
  and measured about 215 ms median when warm. The direct warm App Action
  measured 58.4 ms through Launch Services. The running-app notification then
  measured 1.5 ms median in a synthetic sender and 22.3 ms median from installed
  Hold Keys snap resolution to world mutation (16.5–31.0 ms), while removing
  target-window churn. The direct cold path measured 714.0 ms median across
  three runs and preserved the foreground app.

Resolved during implementation:

- Targeted prior-art research found adjacent products and libraries but no
  complete reusable match; adopt SpriteKit and build only the adapter seam.
- The exact requested global/exclusive behavior requires an active Core
  Graphics event tap and explicit Accessibility permission, so the proof uses
  a stable signed app rather than a local-only substitute.

## Test / Validation Expectations

- Unit tests cover shape/size resolution, matching physics-body creation,
  object count/clear, cursor coordinate mapping, drag lifecycle, window
  filtering and coordinate conversion, one-way admission, anti-crush support,
  and stable window-body lifecycle.
- Automated build proves the demo consumes the library product.
- A physical test covers object spawning, cursor pushing, click-drag/release,
  left/right movement, grounded jumping, control disable/recovery, and
  Command-Tab preservation.
- A measured external-action test records warm and cold Shortcuts invocation,
  direct App Action transport and target timing, foreground preservation, and a
  manual snap-to-visible/UI-stability verdict.
- Permission, build, visual, physical, and subjective evidence remain separate.
- A physical window-platform check covers object bounce, landing from above,
  pass-through from below, window move/resize while supported, abrupt loose-
  object overlap, current-Space filtering, and a secondary-display arrangement.

## Paper Trail

- [Accepted overlay/content boundary](../../decisions/adr/ADR-0001-keep-content-and-product-behavior-outside-the-overlay-host.md)
- [Proposed reusable-layer boundary](../../decisions/adr/ADR-0002-keep-desktop-physics-reuse-outside-globaloverlaykit.md)
- [Proposed DesktopSurfaceKit promotion and versioning gates](../../decisions/adr/ADR-0003-promote-desktopsurfacekit-through-versioned-compatibility-gates.md)
- [Proposed Godot desktop-window observation feed](../../decisions/adr/ADR-0004-bridge-desktopsurfacekit-to-godot-through-a-versioned-snapshot-feed.md)
- [Proposed portable game-state and engine boundary](../../decisions/adr/ADR-0005-separate-portable-game-state-from-observation-and-engine-runtime.md)
- [Prior-art research](../../research/RSCH-0002-desktop-physics-overlay-prior-art.md)
- [Native input research](../../research/RSCH-0003-global-gameplay-key-input-on-macos.md)
- [Stick-figure and wall-movement research](../../research/RSCH-0007-procedural-stick-figure-character-animation-and-wall-movement.md)
- [macOS window-geometry readiness](../../research/RSCH-0008-macos-window-geometry-reuse-readiness.md)
- [Cross-app spawn transport evaluation](../../repo-health/evaluations/EVAL-0001-cross-app-spawn-transport-latency-and-ui-intrusion.md)
- [Implementation plan](../plans/PLAN-0003-reusable-desktop-world-and-character-controls/PLAN-0003-reusable-desktop-world-and-character-controls.md)
