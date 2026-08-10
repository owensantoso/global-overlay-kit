---
type: session-log
title: Reusable Desktop World And Controls
domain: repo-health
status: in_progress
created_at: "2026-08-10 00:18:00 JST +0900"
updated_at: "2026-08-11 06:22:00 JST +0900"
started_at: "2026-08-10 00:10:00 JST +0900"
ended_at:
timezone: "JST +0900"
participants: [Owen, Codex, prior-art subagent, input-research subagent, platformer-policy subagent, surface-contract subagent, Godot-portability subagent]
areas: [AREA-DESKTOP-PHYSICS, AREA-OVERLAY-HOST]
related_plans: [PLAN-0003]
related_briefs: [IMPL-0003-01]
related_specs: [SPEC-0002]
related_adrs: [ADR-0001, ADR-0002, ADR-0003, ADR-0004]
related_todos: []
related_issues: []
related_prs: []
commits: []
---

# 2026-08-10 - Reusable Desktop World And Controls

## Session metadata

- Started: 2026-08-10 00:10:00 JST +0900
- Ended: in progress
- Timezone: JST +0900
- Participants: Owen, Codex, prior-art subagent, input-research subagent

## Goal

- Determine whether the desired macOS desktop-physics overlay already exists.
- If a custom gap remains, create the smallest reusable adapter and prove it
  with varied shapes, cursor collision, and one jumping character.

## Timeline

- 2026-08-10 00:10:00 JST +0900 - Project owner accepted the tuned ball demo
  and requested reusable architecture, shapes/sizes, and cursor collision.
- 2026-08-10 00:15:00 JST +0900 - Project owner added a simple controlled
  circle, opt-in arrow/WASD/Space controls, and strict Command-Tab preservation;
  requested parallel prior-art and input research before reinvention.
- 2026-08-10 00:18:00 JST +0900 - Closed `PLAN-0002`, opened `SPEC-0002`,
  `PLAN-0003`, proposed `ADR-0002`, and dispatched bounded research agents.
- 2026-08-10 00:22:00 JST +0900 - Research found no exact reusable match.
  Accepted the thin-adapter boundary. Native input research selected an active
  Core Graphics event tap and identified Accessibility permission plus stable
  signing as required for global exclusive controls.
- 2026-08-10 00:34:00 JST +0900 - Extracted the nested
  `DesktopPhysicsKit` target; five initial input/coordinate tests passed.
- 2026-08-10 00:36:00 JST +0900 - Built and verified the stable signed app
  bundle with bundle ID `com.owensantoso.DesktopPhysicsDemo` and team
  `GU93K4U9DN`.
- 2026-08-10 00:37:00 JST +0900 - Launched the exact signed app. Process and
  SpriteKit startup were observed; new physical behavior remains with Owen.
- 2026-08-10 00:55:00 JST +0900 - Owen accepted overlay/shapes and cursor
  collision, including click-through, and completed the permission flow. He
  requested continuous object and collider sizing plus a two-handle random-size
  range up to roughly half-screen scale.
- 2026-08-10 00:55:00 JST +0900 - Character acceptance failed: A/D only partly
  worked, arrows did nothing, and W/jump was absent or too small to perceive.
  Passing input-state tests did not supersede this physical result.
- 2026-08-10 01:05:00 JST +0900 - Opened `IDEA-0002` for an agent-native live
  desktop-world sandbox and dispatched reviewed xhigh research on established
  controller feel and runtime/authoring architecture.
- 2026-08-10 01:18:00 JST +0900 - Replaced arrow-modifier bypass, one-frame
  jump admission, contact-set grounding, guessed jump constants, and competing
  friction with a reusable derived controller profile. Owen's physical verdict
  on the signed rebuild was “way better.”
- 2026-08-10 01:20:00 JST +0900 - Owen requested selectable WASD-only,
  arrows-only, or combined controls plus selectable player shape.
- 2026-08-10 01:27:00 JST +0900 - Added the three control-family modes and
  Circle/Square/Triangle/Random player replacement. Twelve focused tests and a
  signed app rebuild passed; the newest physical check remains with Owen.
- 2026-08-10 01:29:00 JST +0900 - Owen returned “all good” for the player
  shape/control-family/Command-Tab/off protocol and requested optional direct
  click-drag manipulation of spawned objects.
- 2026-08-10 01:34:00 JST +0900 - Added explicit drag mode, visible click
  interception warning, a control-window level guard, and a focused
  grab/follow/release test. Physical drag acceptance remains with Owen.
- 2026-08-10 01:39:00 JST +0900 - Owen found that release resumed physics with
  zero velocity, making every object stop dead. He requested flick-to-throw.
- 2026-08-10 01:42:00 JST +0900 - Replaced zero-velocity release with a bounded
  velocity derived from the latest 120 milliseconds of actual object motion.
  The focused test covers both a moving throw and a held stationary drop.
- 2026-08-10 05:30:00 JST +0900 - Owen expanded the player into an animated
  stick figure with idle, directional walk/run/jump, wall slide, wall jump,
  sticky gradual wall descent, and C-to-sit.
- 2026-08-10 05:37:00 JST +0900 - Research selected an asset-free procedural
  pose renderer over an external sprite sheet or inverse-kinematics rig, while
  retaining SpriteKit physics and the existing DesktopPhysicsKit boundary.
- 2026-08-10 05:55:00 JST +0900 - Implemented the procedural stick figure,
  six-state animation resolver, directional mirroring, Shift-to-run, C-to-sit,
  wall probes, capped sticky descent, and away/up wall jump. A window-backed
  test crash was traced to the XCTest harness releasing its temporary NSWindow
  twice; after correcting ownership, the scene test passed repeatedly with the
  stick figure and exercised grounding, jump, wall slide, and wall jump.
- 2026-08-10 05:59:00 JST +0900 - Owen rejected the physical animation quality,
  reported that wall jumps traveled far too horizontally rather than upward,
  and rejected bounce on the player body.
- 2026-08-10 06:07:00 JST +0900 - Replaced the improvised pose renderer with
  selected authored CC0 idle/walk/run/jump/wall-slide frames by Raphael
  Gonçalves, retained their source and license, reduced wall-jump horizontal
  velocity from 680 to 260, restored vertical velocity to 1,000, and set player
  restitution to zero.
- 2026-08-10 17:43:00 JST +0900 - Owen confirmed the trigger/action ownership
  split and requested an App Intents plus Shortcuts latency experiment before a
  custom provider protocol. The experiment must measure the Shortcuts hop with
  unified logging/signposts and keep software timing separate from a manual
  visible-result check.
- 2026-08-10 18:52:00 JST +0900 - Owen asked to reuse a prior macOS
  Accessibility rectangle project and turn actual application windows into
  natural object obstacles and one-way player platforms.
- 2026-08-10 19:01:56 JST +0900 - The readiness audit found that the only
  `DesktopSurfaceKit` copy is a dated non-git POC. Its eight tests pass, but it
  is not a durable dependency and its multi-display, occlusion, and SpriteKit
  behavior remain unvalidated. The implementation adapted only its narrow Core
  Graphics window seam into the active version-controlled package.
- 2026-08-10 21:15:24 JST +0900 - Owen requested visible proof of every
  detected platform. Added default-on cyan full-window outlines, thicker capped
  yellow one-way player edges, a normal-window toggle/legend, and a nonphysical
  stable-ID lifecycle test. Installed-app visual behavior remains untested.
- 2026-08-10 21:17:28 JST +0900 - The exact-Mac sensor audit confirmed a Bosch
  BMI286 accelerometer and gyroscope but no public non-privileged macOS chassis-
  motion API. Private root `spank`/SPU access was rejected for this build, and
  no sensor code or service was added.
- 2026-08-10 21:29:33 JST +0900 - Replaced the nested raw-window enumerator
  with a compatibility adapter over canonical DesktopSurfaceKit observation.
  The adapter retains Accessibility fail-off and scene conversion. Strict
  nested tests, app tests, the universal Release build, and signature checks
  remained green.
- 2026-08-11 01:22:00 JST +0900 - Owen reported that all sprites had vanished.
  Live inspection found a healthy unpaused 1800x1130 scene with 104 nodes, but
  a blank transparent `SKView`. The same failure reproduced in the recoverable
  pre-SurfaceKit build. Disabling explicit AppKit layer backing after
  `presentScene` restored the existing sprites immediately.
- 2026-08-11 02:35:00 JST +0900 - Published the private immutable
  `DesktopSurfaceKit 0.1.0-rc.3` pre-release. It preserves source window and
  front-to-back provenance plus the surviving original side of every visible
  rectangle fragment. Both tag CI runners and the exact-version consumer
  canary passed.
- 2026-08-11 02:45:00 JST +0900 - Integrated platform drop-through, one air
  jump, independent Spacebar control, run-dependent horizontal travel,
  double-tap-and-hold wall run, optional visible side walls, an open player
  ceiling, player dragging, and reversible Game World Mode presentation.
  The full repository check passed with 31 executable-target tests, 11 Swift
  Testing cases, three overlay-host tests, the signed Debug build, generated
  docs, and link checks.
- 2026-08-11 02:50:00 JST +0900 - Recorded the proposed Godot boundary as a
  signed Swift helper and versioned newline-delimited JSON snapshot feed. A
  local process-pipe probe passed; collider implementation remains gated on a
  proven Quartz-to-Godot display transform because this Retina display exposes
  a measured 2x coordinate mismatch.
- 2026-08-11 03:33:00 JST +0900 - Owen's installed acceptance reply reported
  that Down Arrow plus Space did nothing. The physical verdict superseded the
  passing policy test.
- 2026-08-11 03:41:00 JST +0900 - A new regression reproduced the exact input
  failure: macOS carried the Down Arrow's intrinsic Function flag onto Space,
  which the input layer misclassified as a shortcut and used to clear held
  state. The corrected rule preserves that flag only while a tracked arrow is
  held; Command, Control, and Option still fail closed. The same wave changed
  drag mode from whole-overlay interception to cursor-local capture over roots
  explicitly marked draggable, latched only for an active drag.
- 2026-08-11 03:49:00 JST +0900 - An installed exact-event probe showed the
  first input fix reached the scene but exposed a second drop-through defect:
  ignoring only one window ID allowed another overlapping window edge at the
  same support height to catch the player immediately. A red/green policy test
  now requires drop-through to exclude every coincident platform edge at that
  height until the player's feet pass below it. The complete repository check
  then passed with 32 executable-target tests, 12 Swift Testing cases, three
  overlay-host tests, the signed Debug build, generated docs, and link checks.
- 2026-08-11 03:59:00 JST +0900 - Temporary installed logging proved the
  repaired input created and consumed a drop request against a grounded support
  at y=227, yet the player returned to the same edge. The exclusion cleared
  when the current foot crossed the tolerance even though the previous-frame
  foot still satisfied the landing test. A red/green regression now retains
  exclusion until the previous frame is below tolerance. The exact installed
  Down Arrow plus Space event then visibly moved the player from the upper
  yellow platform to the next lower one. Temporary logging was removed.
- 2026-08-11 04:00:00 JST +0900 - The clean universal Release app was rebuilt,
  strictly signature-verified, installed, and launched as PID 46208. With drag
  mode enabled, an empty desktop click changed the frontmost app from Desktop
  Physics Demo to ChatGPT, while a pointer-down on the player's visual region
  captured and moved the player without activating the overlay. On that same
  clean installed build, the exact Function-flagged Down Arrow plus Space
  sequence visibly dropped the player from one yellow window edge to the next
  lower edge. The temporary diagnostic strings are absent from the binary.
- 2026-08-11 04:35:00 JST +0900 - Owen identified the player's rectangular
  sprite capture region as a core usability defect. Confirmed target behavior
  is source-alpha capture on the current rendered animation frame, independent
  from the physics collider. He also confirmed a directional wall traversal:
  Jump while holding into a contacted visible window wall phases across that
  wall; Jump away retains the ordinary wall jump. Separately, DesktopSurfaceKit
  should add optional, permission-truthful focused-window observation rather
  than guessing focus from Window Server z-order.

## Context read

- `docs/orientation/CURRENT_STATE.md`
- `docs/orientation/ARCHITECTURE.md`
- `docs/decisions/adr/ADR-0001-keep-content-and-product-behavior-outside-the-overlay-host.md`
- `docs/product/plans/PLAN-0002-desktop-physics-falsification-demo/`
- `docs/research/RSCH-0002-desktop-physics-overlay-prior-art.md`
- `docs/research/RSCH-0008-macos-window-geometry-reuse-readiness.md`

## Changes

- Checkpointed confirmed reuse and control requirements before implementation.
- Created and accepted the `AREA-DESKTOP-PHYSICS` boundary after research.
- Added varied object spawning, cursor collision, player movement/jump, a
  selective active event tap, explicit permission UI, and visible recovery.
- Added continuous fixed and cursor-collider sizing, an explicit two-handle
  random-size range, selectable player geometry, and WASD/arrows/both modes.
- Added an explicit animation state/facing model, authored CC0 sprite renderer,
  walk/run control split, sit toggle, and wall movement.
- Recorded prior art for responsive platformer control, agent-native desktop
  world runtimes, and per-engine overlay compatibility adapters.
- Converted the demo from a transient SwiftPM executable to a normal signed
  Xcode app that imports the nested library product.
- Added `MacDesktopWindowGeometry` for Accessibility-gated Core Graphics window
  enumeration, filtering, stable IDs, and selected-screen conversion.
- Added full-rectangle loose-object collision, descending-from-above one-way
  player landing, small supported-window following, anti-crush detachment, a
  500 ms lifecycle poll, and live normal-window state callbacks.
- Added physics-free window-platform outlines keyed by the same stable IDs,
  plus independent normal-window visibility control and an explicit visual
  legend for object versus player policy.
- Removed incompatible explicit AppKit layer backing from the transparent
  SpriteKit host and added a regression test against the actual scene view
  controller and presentation order.
- Recorded the exact hardware, public API boundary, private/root prior art, and
  defer/reopen conditions for built-in tilt gravity in `RSCH-0009`.
- Commits produced: none.

## Decisions

- Confirmed: SpriteKit is the engine; custom code is a desktop-world adapter.
- Accepted: keep the adapter as a reusable library target in the nested package
  until a second use justifies standalone publication.
- Confirmed: control mode handles only movement/jump keys and never suppresses
  Command-modified shortcuts.
- Confirmed: requested global exclusive controls use an active Core Graphics
  event tap, require Accessibility permission, start off, and fail off.
- Confirmed: collider and spawned-object size need continuous controls; random
  sizes need an explicit minimum/maximum range.
- Confirmed: Space remains shared while movement/jump key families can be
  limited to WASD, arrows, or both; player physics geometry is selectable.
- Proposed: explore a stable native host plus serializable agent-facing world
  runtime before considering a full visual game-maker.
- Confirmed: Hold Keys owns the snap trigger and binding; Desktop Physics owns
  the parameter-free Spawn Random Object action. App Intents plus a constrained
  saved Shortcut remain the compatibility path. The accepted direct comparison
  is a bundle-bound semantic App Action: a local notification while the target
  is running and a verified custom-URL fallback for cold launch.
- Confirmed: visible window fragments are optional experimental geometry.
  Loose objects use the rectangularly visible portions as solid obstacles. The
  player uses surviving original top and bottom sides as one-way platforms,
  can optionally use surviving original left and right sides as walls, and
  ignores new intrusions so moving windows cannot squish it.
- Accepted adaptation: Core Graphics supplies window IDs and frames while
  Accessibility is the explicit fail-off gate shared with global controls. The
  dated non-git `DesktopSurfaceKit` POC is provenance, not a package dependency
  or current source of truth.
- Deferred: built-in tilt gravity. Physical BMI286 hardware is present, but
  `CMMotionManager` is unavailable on macOS and the known SPU/HID route is
  vendor-defined, motion-restricted, root-only prior art. Reconsider only for a
  supported chassis API or an explicitly approved private local experiment.

## Verification

The repeatable transport protocol, endpoint definitions, aggregate sample table,
and recommendation are preserved in
[EVAL-0001](../evaluations/EVAL-0001-cross-app-spawn-transport-latency-and-ui-intrusion.md).

- Commands run: nested `swift test`, XcodeGen generation, signed Xcode build,
  strict code-signature verification, exact app launch, and process/log check.
- Current automated result before the visualization addition: the refreshed
  `./run check` passed with twenty-three focused nested tests and three root host tests,
  including all animation states/facings and a presented SpriteKit
  grounding/jump/wall-slide/wall-jump path, plus the signed app build,
  continuity documentation, link checks, and diff hygiene.
- Window-platform package result: the historical POC's eight tests passed.
  The active nested package then passed 23 tests after canonical window
  filtering moved into DesktopSurfaceKit. It covers primary/above-main display
  conversion, one-way admission, anti-crush support, object-
  versus-player collision masks, stable-ID node lifecycle coverage, and
  outline tracking/nonphysics coverage.
- Strict package result: all 23 tests passed with complete Swift
  concurrency checking and warnings treated as errors. XcodeGen regenerated
  the app project, the Apple Development-signed Debug app build succeeded, and
  strict code-signature verification plus a certificate-and-identifier
  designated requirement passed.
- Visualization release candidate after the canonical DesktopSurfaceKit
  canary: XcodeGen regenerated the app project, the three executable-target
  semantic-action tests passed, and a universal Release app built at
  `App/ReleaseDerivedData/Build/Products/Release/Desktop Physics Demo.app`.
  Strict signature verification passed with hardened runtime, bundle ID
  `com.owensantoso.DesktopPhysicsDemo`, Apple Development certificate, and team
  `GU93K4U9DN`. Launch Services still resolves the semantic URL to the installed
  app. The candidate was not installed or physically exercised.
- Final full check: after concurrent docs work settled, `./run docs` and
  `./run check` passed the registry refresh, three root tests, all 23 nested
  tests, the signed Debug app build, documentation/link checks, and diff
  hygiene. A separate strict-concurrency warnings-as-errors run of the same 23
  tests and strict code-signature verification also passed.
- Physical pass: varied object shapes, cursor collision, click-through,
  permission flow, and a materially improved rebuilt player controller.
- Physical fail, superseded by the rebuild: arrow input and effective jumping;
  A/D was only partial.
- Physical pass: the newest control-family selector and selectable player
  geometry, including Command-Tab and final control-disable/key-return behavior.
- External-action measurement: saved-Shortcut warm command invocation measured
  about 215 ms median and cold invocation about 1.06 s. Its world mutation was
  sub-millisecond to low-single-digit milliseconds, so the hop dominated and
  macOS also showed distracting Shortcuts menu-bar status UI.
- Direct Launch Services comparison: ten serialized warm runs measured 58.4 ms
  median gesture-equivalent sender-to-world time (42.2–123.1 ms). Three cold
  runs measured 714.0 ms median (692.9–947.1 ms) and preserved ChatGPT as the
  frontmost app. Reopening the already-running target caused visible control-
  window churn, so this is retained only for cold launch.
- Accepted warm direct path: ten synthetic serialized runs measured 1.5 ms
  median sender-to-world time (1.2–2.5 ms). Fifteen installed physical samples
  measured 22.3 ms median from snap resolution to world mutation
  (16.5–31.0 ms); the synchronous notification post itself accounted for a
  20.2 ms median. The physical check spawned objects with no Shortcuts menu-bar
  indicator and no target-window churn. A shared lowercase `run_id` joined
  gesture resolution to `world.spawn.completed` across both processes.
- Packaging pass: the Apple Development-signed Release app is installed at
  `~/Applications/Desktop Physics Demo.app`; Launch Services resolves the
  semantic URL to that bundle. Closing its control window keeps the process and
  world alive, and reopening the app recreated the window in the same PID.
- Unknown: direct object dragging and click-through restoration after leaving
  drag mode.
- Unknown: visual quality and feel of the new idle/walk/run/jump/wall-slide/sit
  animation and wall controller in the signed app.
- Unknown: signed-app window-platform behavior, including live object bounce,
  landing/pass-through, moving and resizing support, covered-window
  expectations, secondary displays, and whether a newly overlapping rectangle
  ejects loose objects too abruptly.
- Installed compositor pass: the corrected signed Release app visibly rendered
  cyan full-window rectangles, yellow player edges, a spawned object, and the
  stick-figure player. Turning only outline visibility off removed the geometry
  while the window-platform feature remained enabled and the player remained
  visible. Live tracking, collision feel, and owner acceptance remain open.
- Sensor boundary: hardware and driver metadata were enumerated read-only; no
  live sample, axis, calibration, latency, power, or gravity-control behavior
  was tested because no supported non-privileged chassis API exists.
- Transparent-renderer regression: the focused production-host test failed
  before the correction because `SKView.wantsLayer` remained true, then passed
  once layer backing was disabled after `presentScene`. A live A/B test on the
  old build independently restored its existing sprites with the same change.
  The freshly built universal Release app was signed, installed, launched from
  `~/Applications`, and captured with both platform outlines and sprites
  visible.
- Visible-region correction: the first visualization exposed 51 full Window
  Server rectangles, including buried windows. Canonical DesktopSurfaceKit now
  provides deterministic front-to-back rectangular subtraction in private
  exact `0.1.0-rc.2` at `79da16b...`; both remote CI runners and the private
  pre-release gates passed. Desktop Physics uses the resulting nonoverlapping
  fragments for loose-object collision.
- Player-edge correction: only fragments that still reach the source window's
  original visible top or bottom become one-way player surfaces. Occlusion-cut
  edges remain object geometry but cannot invent landing ledges. Both real
  edges admit upward passage from below and catch descending landings from
  above; sides remain pass-through.
- Control/tuning correction: outline visibility and character/window collision
  are separate switches under the window-platform feature. A 40-point to near-
  display-height jump slider updates the controller's designer-facing jump
  height and derived launch/tap/wall-jump values.
- Current private package result: immutable `DesktopSurfaceKit 0.1.0-rc.3`
  resolves to `ebc8d34eedd4ad395e488e153d6a6ca83b155095`. Its annotated tag,
  private pre-release, two-runner tag CI, 24 strict package tests, API checks,
  and exact-version Desktop Physics canary passed. The consumer now reads
  fragment source order and surviving original sides from the package rather
  than reconstructing that provenance itself.
- Current mechanics result: 33 executable-target tests and 12 Swift Testing
  cases cover drop-through, double jump, control-family and Spacebar policy,
  wall-run intent, run-dependent horizontal speed, visible-only side
  collision, no-squish resolution, player dragging, open-top boundaries, and
  atomic Reduce Motion Game World Mode state. The complete `./run check` also
  passed three overlay-host tests, the signed Debug app build, docs/link checks,
  and diff hygiene.
- Current signed install: the exact `0.1.0-rc.3` consumer built successfully as
  a universal hardened Release app with arm64 and x86_64 slices. Strict
  signature and designated-requirement verification passed for bundle ID
  `com.owensantoso.DesktopPhysicsDemo` and Apple Development team
  `GU93K4U9DN`. It is installed and running from
  `~/Applications/Desktop Physics Demo.app`; the pre-fix app is recoverable
  from `~/.Trash/Desktop Physics Demo.app.pre-coincident-drop-fix-20260811-035100`.
- Current live compositor result: the installed app reports 39 visible regions
  in the present desktop arrangement. Game World Mode visibly produced an
  opaque white playfield with black enabled platform and wall lines. A bounded
  on/off exercise captured an intermediate translucent frame and the restored
  cyan/yellow desktop-outline end state, proving that the installed transition
  is not an atomic color swap. The clean final install also has positive live
  evidence for cursor-local player dragging, empty-desktop click-through, and
  Down Arrow plus Space drop-through. Broader movement feel remains Owen's
  physical acceptance gate.
- Exact-RC automated result: 28 strict nested tests, three root host tests,
  signed Debug build, generated docs, and link checks pass. Signed universal
  Release install and physical gameplay acceptance are the remaining gates.
- Signed install result: the corrected universal Release app contains arm64 and
  x86_64 slices, passes strict designated-requirement verification with Apple
  Development team `GU93K4U9DN`, and its three executable-target tests pass.
  It replaced the installed copy at `~/Applications/Desktop Physics Demo.app`;
  the prior build is recoverable from
  `~/.Trash/Desktop Physics Demo.app.pre-visible-regions-20260811-015054`.
- Live installed observation: the control window reports 43 visible regions in
  the current desktop arrangement instead of the earlier 51 full-window
  rectangles. The independent outline and character-collision switches plus
  live high-range jump slider are visible and responsive. Owen's traversal and
  visual-line acceptance remains the authoritative physical gate.

## Correction / Reflection

- What happened: “jump on the bottom” was initially interpreted as upward head
  collision with a ceiling.
- What led to it: the agent chose one plausible platformer meaning without
  confirming it against the user's intended traversal.
- Source: agent assumption.
- What changed: the bottom border is now a second ordinary one-way landing
  platform. The player passes upward through it, then can land and stand on it
  while descending; there is no ceiling collision.
- Verification: policy and supported-edge fixtures cover bottom-edge upward
  passage, descending landing, and moving-platform support.

- What happened: pure input-state tests and successful app admission were too
  weak to establish per-key delivery or a usable grounded jump.
- What led to it: the implementation encoded assumed key flags and jump
  constants without runtime key/grounding telemetry or a controller reference
  model.
- Source: agent assumption plus a physical-verification gap.
- What changed: physical acceptance now names each key family and jump behavior;
  diagnostics and established controller research precede further tuning.
- Verification: pending a traced rerun and a new physical receipt.
- Recovery: the new SpriteKit scene test reproduced the original failed jump,
  then passed after ray grounding, buffered admission, and derived motion were
  implemented. A physical rerun improved the result substantially.

- What happened: the first stick-figure renderer technically covered every
  state but looked bad in the signed app; wall-jump direction and player bounce
  also contradicted the intended character feel.
- What led to it: inspectability and avoiding an asset dependency were favored
  without a visual benchmark, even though the request explicitly allowed
  finding authored animation online.
- Source: agent assumption and insufficient visual-source research.
- What changed: the procedural poses were removed, an exact CC0 animation pack
  was adopted with provenance, wall-jump impulse now favors vertical motion,
  and player restitution is zero.
- Verification: resource loading and all seventeen nested tests pass; corrected
  signed-app visual/feel acceptance is pending.
- Follow-up: treat character-art quality as a physical gate before describing
  a renderer choice as complete.

- What happened: the installed overlay reported live objects and a player, but
  every sprite and platform outline was invisible.
- What led to it: the host combined SpriteKit transparency with explicit
  AppKit layer backing. Scene/node tests proved simulation but did not inspect
  the production `SKView` configuration.
- Source: framework-compatibility gap plus insufficient host-level coverage.
- What changed: SpriteKit retains ownership of its transparent backing after
  scene presentation, and the production view controller now has a focused
  regression test.
- Verification: red/green focused test and live old-build A/B both reproduce
  the exact boundary. A fresh installed-build compositor capture now passes;
  Owen's gameplay and visual-feel confirmation remains open.

## Follow-ups

- Diagnose actual event flags and grounded/jump admission before changing feel
  constants; add regression tests for the confirmed cause.
- Physically check object grab/follow/release and click-through restoration.
- Physically check the six stick-figure states, run speed distinction, gradual
  wall slide, repeatable wall jump, and C sit/stand behavior.
- Decide extraction only after a second consumer tests the library API.
- Keep the direct App Action contract narrow and low-risk; distributed
  notifications are local routing, not sender authentication. Do not generalize
  it into arbitrary commands without a new security and lifecycle decision.
- Physically evaluate window platforms using the protocol in `PLAN-0003` before
  calling their collision feel accepted or extracting the geometry product.
- Physically confirm that the outline count matches detected windows, geometry
  tracks within one poll, independent hiding keeps collisions active, platform
  disabling removes both layers, and ordinary desktop clicks still pass
  through.
- Keep built-in tilt out of the product until the `RSCH-0009` reopen condition
  is satisfied; prefer an iPhone Core Motion or public controller provider if
  supported tilt input becomes a separate priority.

## 2026-08-11 Portable Game-State Architecture Checkpoint

Owen confirmed that the desktop game must remain portable to a possible Godot
runtime and that the gameplay-visible world should be easy to encode for a
future multiplayer experience without sending screen contents. He also
required painted-pixel avatar interaction to remain distinct from the physics
collider and portable across engines.

The accumulated demo was first checkpointed as `efaf82d` after the full
`./run check` passed. Three parallel read-only audits then reviewed portable
state, interaction policy, and DesktopSurfaceKit observation. The allocation
and audit results converged on these proposed decisions:

- add one pure nested `DesktopGameCore` target for portable values and small
  deterministic gameplay policies;
- preserve four ownership categories: local macOS observation, canonical game
  state, engine-private solver state, and renderer-only state;
- use one authoritative simulation with snapshot/event replication rather than
  requiring SpriteKit and Godot solver determinism;
- define the canonical world as right-handed X/Y/Z from version 1: X right, Y
  up, positive Z toward the viewer, negative Z into the world, and today's
  collapsed desktop on `Z = 0`;
- send asset, animation-frame, transform, and pick-mask references rather than
  pixels; each engine samples a local immutable mask for pointer selection;
- identify wall contact by its physical plane and player-relative direction so
  toward-wall Jump can phase through all coincident source features until the
  player fully crosses it;
- keep `desktop-window-feed` separate from the privacy-filtered
  `desktop-game-state` protocol;
- keep ordinary DesktopSurfaceKit geometry permission-free and add focus only
  as a separate, nonprompting Accessibility-backed product.

The durable decision and schema sketch are in
[ADR-0005](../../decisions/adr/ADR-0005-separate-portable-game-state-from-observation-and-engine-runtime.md).
It remains proposed until the pure target and a real Godot fixture consumer
validate the contract. Do not add another SpriteKit-only gameplay feature
before that boundary exists.

## 2026-08-11 Portable Game Core Implementation

The first bounded `DesktopGameCore` slice is implemented inside the nested
Desktop Physics package without changing existing SpriteKit or demo-app source.
The new Foundation-only product provides validated X/Y/Z vectors, normalized
quaternions, poses and kinematics, viewport/depth and extruded-surface values,
privacy-filtered snapshots, delta/input/event envelopes, explicit protocol and
schema versions, and atomic world-session/base-sequence application.

The same pure target now owns two engine-independent interaction policies:
front-to-back selection over caller-reported painted coverage, and symmetric
wall traversal scoped to a contacted physical plane within an explicit finite
tolerance until the previous-frame player bounds fully cross it. The initial
direction selects traversal and later determines full-bounds clearance, but an
active phase ignores the relative-direction flip after center crossing. All
coincident source features are excluded during that phase, while distinct
planes remain collidable. It does not decode alpha masks or mutate a physics
body.

The test-first compile failed as expected before the source values existed.
After all review corrections, 32 focused core tests pass. They cover explicit
bottom-left/world-unit viewport wire semantics and top-left conversion,
authority-side despawn-and-never-reuse identity history, duplicate/conflicting
delta construction and decoding, duplicate/reordered admission, optional
unknown JSON fields, atomic replica application, and coincident-plane wall
traversal. The complete nested package passes 33 XCTest tests plus 44 Swift
Testing tests. The frozen JSON fixtures include one planar desktop, one
coordinate-conversion case, and one avatar moving into negative Z with X-axis
rotation. The planar capability admits the planar state and rejects the depth
state.

This is automated contract evidence only. The current SpriteKit scene does not
yet emit or consume these values, Godot has not decoded the fixtures, and no
multiplayer transport or physical gameplay behavior changed in this slice.

### Spec-review correction

- What happened: the first pass described coordinate semantics and entity ID
  nonreuse in prose, accepted ambiguous delta arrays, and scoped wall traversal
  to one source feature ID.
- What led to it: passive value containers and comments were treated as if
  they enforced the reusable protocol invariants.
- Source: implementation assumption exposed by spec review.
- What changed: coordinate origin/units are required wire enums with a
  conversion fixture; a per-session authority ledger retires despawned entity
  IDs; delta initialization and decoding reject duplicate/conflicting IDs; and
  traversal excludes all features coincident with the contacted plane and
  direction within a finite encoded tolerance.
- Verification: focused tests exercise each corrected invariant, including
  malformed JSON at the decode boundary. The final `./run check` passed all
  root and nested tests, the signed Debug app build, generated-doc checks, link
checks, continuity smoke, and diff hygiene.

### Code-review correction

- What happened: active wall exclusion stopped after the player center crossed
  because the candidate-relative direction flipped, and replica admission
  advanced sequence state before caller application could succeed. Planar
  tolerance, equal painted ranks, quaternion sign, and ledger copy/concurrency
  behavior were also ambiguous.
- What led to it: the first state machines modeled the contact sample and
  admission decision as completed state rather than separating the active
  phase from transient observations and validation from application.
- Source: implementation assumption exposed by code review.
- What changed: active traversal matches the stored plane regardless of current
  relative direction until previous-frame full bounds clear; an exclusive
  replica coordinator validates, synchronously applies, and commits each state
  update as one operation;
  stale ticks and unsafe planar tolerances fail closed; equal painted ranks use
  UTF-8 entity-ID order; quaternion signs canonicalize; and the entity ledger
  is one `NSLock`-guarded reference shared by aliases.
- Verification: 31 focused core tests and the complete nested package pass,
  including straddling-after-center-cross, throwing application recovery,
  stale tick,
  rank-order independence, quaternion equivalence, and concurrent ledger
  fixtures. The final `./run check` also passes the root and nested suites,
  signed Debug app build, generated docs, link checks, continuity smoke, and
  diff hygiene.

### Atomic replica-application correction

- What happened: the two-phase admission token prevented premature sequence
  advancement but still let a caller apply an older payload externally before
  learning that its token had lost a race to a newer commit.
- What led to it: validation and commit were protected, but payload application
  remained caller-controlled between them.
- Source: state-ownership mistake exposed by re-review.
- What changed: the public token flow was removed. One locked replica
  coordinator now validates, runs a nonescaping synchronous throwing
  application closure, and advances session/sequence/tick under the same
  exclusive lock. Rejected updates never invoke the closure, and a throwing
  closure never advances the coordinator. The closure must not re-enter that
  coordinator while it owns the exclusive operation.
- Verification: a deterministic competing-update test blocks a newer
  application while an older base-sequence update queues, then proves only the
  newer payload runs and the older closure is never invoked. All 32 focused
  core tests pass. `./run docs && ./run check` passes the 33 XCTest tests, 44
  Swift Testing tests, signed Debug app build, generated documentation, link
  checks, continuity smoke, and diff hygiene.

## 2026-08-11 SpriteKit Interaction Adapter

`IMPL-0003-03` connects the first two pure interaction policies to the live
SpriteKit authority without moving image or engine state into
`DesktopGameCore`.

The stick-figure loader now builds one immutable 8-bit alpha mask beside every
shipped 512-by-512 PNG texture. Masks are cached by the static frame table and
sampled with a 10 percent alpha threshold. Pointer coordinates pass through the
live SpriteKit node transform into normalized bottom-left visual coordinates,
then into the image's top-row storage convention. This covers current-frame
animation, sprite anchor/offset, and directional mirroring. Shape roots use
their filled/stroked vector paths. Physics bodies never participate in picking.
The scene feeds caller-reported coverage into the pure deterministic
front-to-back candidate policy, while the existing mouse-down capture remains
owned by the scene through release.

Visible window side features now have stable adapter IDs containing the source
fragment and left/right side. A fresh buffered Jump plus current/recent window
contact is passed to the pure wall decision. Toward input stores a traversal
state, gives the player a bounded impulse into that plane, and filters every
coincident feature until previous-frame full horizontal bounds clear. Away or
neutral input preserves the prior outward wall jump; distinct X planes remain
collidable. Screen and loose-object walls do not opt into traversal.

The geometry adapter and world command path no longer call
`AXIsProcessTrusted`, expose an Accessibility-required geometry state, or link
ApplicationServices. An injected observation fixture proves an ordinary
window is converted and returned without a permission branch. The independent
global-key controller still uses Accessibility exactly as before.

Test-first compilation failed on the missing mask, injected-observation,
feature-ID, exclusion, and scene-state APIs. The completed nested package then
passed 41 XCTest tests and 44 Swift Testing tests. New tests use the actual CC0
idle/sit pixels, prove a point changes coverage with the current frame, prove
mirroring moves that point, reject transparent texture area, retain capture
after a painted mouse-down, distinguish coincident and later wall planes, and
preserve outward away-wall jumping. Human overlay click precision and traversal
feel remain unverified; no app was installed or launched for this receipt.

### Interaction-adapter review correction

- What happened: the first adapter pass updated overlay capture before the
  animation selected its rendered frame, selected among nearby wall edges by
  dictionary order, and retained stale contact/traversal after source-window
  removal.
- What led to it: current-frame rendering, panel routing, collision probing,
  and live observation reconciliation were reviewed as separate mechanics
  instead of one frame/lifecycle contract.
- Source: implementation assumptions exposed by independent code/contract
  review.
- What changed: capture is refreshed again immediately after animation-frame
  mutation; candidate wall contacts sort by point-to-plane distance and stable
  tie-breakers; exact contacts expire when their source feature disappears;
  active traversal survives source-fragment replacement only while any
  coincident physical plane remains, then clears when that plane disappears.
- Verification: targeted stationary-point routing, two-close-plane,
  contact-removal, coincident-replacement, and plane-disappearance regressions
  pass. Re-review reports no remaining P0 or P1 findings.

## Installed Painted-Picking And Wall-Traversal Acceptance

- 2026-08-11 07:03 JST - Built commit `cf8153a` as a universal `arm64` and
  `x86_64` hardened Release app. Strict signature verification passed with
  bundle identifier `com.owensantoso.DesktopPhysicsDemo`, Apple Development
  team `GU93K4U9DN`, and a certificate-and-identifier designated requirement.
- The installed executable at
  `~/Applications/Desktop Physics Demo.app/Contents/MacOS/Desktop Physics Demo`
  matched the candidate executable's SHA-256 exactly and launched from that
  path. The replaced build is recoverable from
  `~/.Trash/Desktop Physics Demo.app.pre-painted-picking-20260811-065800`.
- Owen completed the installed physical protocol and replied **Both pass**.
  Transparent pixels a few pixels outside the current avatar passed through to
  the underlying app, while a painted-pixel mouse-down retained drag capture
  until mouse-up. Toward-wall plus fresh Jump crossed the complete contacted
  visible-window plane without snagging, and away-wall plus Jump retained the
  ordinary outward wall jump. The same result also covered the stated
  permission check: enabling ordinary visible-window platforms did not itself
  request Accessibility; global keyboard controls retain their separate
  permission boundary.
