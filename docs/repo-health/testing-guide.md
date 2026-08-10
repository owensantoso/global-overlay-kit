---
type: testing-guide
title: Testing Guide
domain: repo-health
status: active
created_at: "2026-08-09 03:50:00 JST +0900"
updated_at: "2026-08-10 06:07:00 JST +0900"
owner:
surface: GlobalOverlayKit Swift package
areas: [AREA-OVERLAY-HOST, AREA-DESKTOP-PHYSICS]
related_specs: [SPEC-0001, SPEC-0002]
related_plans: [PLAN-0001, PLAN-0002, PLAN-0003]
related_adrs: [ADR-0001, ADR-0002]
related_sessions:
  - 2026-08-09-project-foundation-and-overlay-boundary
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# Testing Guide

GlobalOverlayKit has automated build, contract, documentation, and hygiene
checks plus a runnable desktop-physics example. Visible rendering has been
observed on one Mac; the broader physical behavior matrix remains open.

## Primary Commands

From the repository root:

```bash
./run build
./run test
./run demo
./run docs
./run check
```

`./run check` is the closeout baseline. It runs:

1. `swift build`
2. `swift test`
3. tests for `Examples/DesktopPhysicsDemo`'s `DesktopPhysicsKit` target
4. Xcode build of the signed Desktop Physics Demo app
5. committed structured-doc validation
6. local Markdown link validation
7. the Agent Continuity smoke test
8. `git diff --check`

Use `./run docs` to refresh generated views after changing source docs, then
commit those outputs before `./run check`. GitHub Actions runs `swift test` and
the documentation checks on macOS 15 for pushes and pull requests. A workflow
file existing on disk is not evidence that a remote run has passed.

## Evidence Matrix

| Evidence class | Current mechanism | What it proves | What it does not prove |
|---|---|---|---|
| Compile | `swift build` | Package source type-checks and links in the local toolchain | Runtime window behavior |
| Automated contract | `swift test` | Constructed panel properties and in-place setters match focused assertions | Cross-process pointer routing, focus, Spaces, or pixels |
| Desktop-world tests | `swift test --package-path Examples/DesktopPhysicsDemo` | Size mapping, cursor coordinates/resizing, shape bodies, control-family filtering, run/sit input, character state/render coverage, derived controller values, buffered input, scene-level grounding/jump/wall-slide/wall-jump admission, and drag lifecycle | Real cursor collision, event-tap admission, drag event routing, animation or movement feel, or Command-Tab delivery |
| Signed app | Xcode build plus `codesign --verify --deep --strict` | Exact app bundle builds with the intended stable identity | Accessibility trust or actual protected key suppression |
| Documentation | `./run docs` | IDs, frontmatter, generated views, local links, and wrapper smoke | Package behavior |
| Diff hygiene | `git diff --check` | No whitespace errors in the diff | Correctness |
| Visual | Screen capture of the clean second demo run | Multiple colored balls rendered over other app content on the main display | Motion quality, click routing, Spaces, or other displays |
| Physical | User rejected the initial fast fall/floor jitter and later accepted the corrected balls, varied object shapes, cursor collision, click-through, and permission flow; the rebuilt controller was “way better,” and the player-shape/control-family/Command-Tab/off protocol was “all good” | The revised physics, controller, selectors, and recovery behavior work on this Mac in the exercised configuration | New direct object dragging, Hide/Show, focus, Spaces, full-screen, window drag/resize |
| Accessibility | Label property is set in code | The requested label is passed to AppKit | VoiceOver navigation or recovery usability |
| Performance | None yet | Nothing yet | Frame pacing, energy, memory, or render throughput |
| Remote CI | Workflow exists | Intended remote baseline | A passing run until GitHub reports one |

## Automated Coverage Today

The focused tests assert:

- `.floating` window level
- transparent non-opaque panel configuration
- pointer pass-through mapping
- `.canJoinAllSpaces` and `.fullScreenAuxiliary` collection flags
- in-place pointer-interaction changes
- in-place frame updates and configuration mirroring
- preservation of the configured initial frame after installing an arbitrary
  controller whose root view has its own size

The thirteen nested desktop-world tests additionally assert:

- explicit and random-range object sizes plus circle, square, and triangle
  physics bodies
- global-to-selected-screen cursor coordinate mapping
- cursor-collider resizing from one point through large values
- WASD-only, arrows-only, and combined key-family capture
- intrinsic Function flags on arrow events and modified-key bypass
- one buffered jump request per physical down/up transition
- controller parameters derived from target jump height and apex time
- grounded jump admission in a presented SpriteKit scene
- object grab/follow/release lifecycle, bounded release velocity, stationary
  drop, and restoration of dynamic physics
- clearing held gameplay state when a modifier becomes active

These are useful mechanism tests. They are not end-to-end proof.

## Required Physical Matrix Before A Release Claim

Use a small example or real consumer on a physical Mac and record observations
separately for:

- showing without stealing application focus
- pass-through clicks reaching the application beneath
- pointer-interactive controls receiving clicks
- a visible recovery route when the surface is interactive
- movement and resizing when enabled
- frame autosave and restoration when configured
- normal Spaces, switching Spaces, and joining all Spaces
- full-screen applications and transitions into/out of full screen
- menu bar/Dock-inclusive and visible-frame screen filling
- one and multiple displays, including changed topology
- VoiceOver label and keyboard reachability appropriate to the consumer
- sustained SwiftUI updates and SpriteKit rendering without unacceptable
  performance or input lag

Record hardware, macOS version, display topology, app activation state, exact
configuration, and observed result. Do not collapse these into “works.”

## Typical Verification Bundles

### Docs-only change

```bash
./run docs
git diff --check
```

### Package API or implementation change

```bash
./run check
```

Then run the smallest physical matrix affected by the change.

### Consumer integration

Run `./run check` here and the consumer's own baseline. Then record physical
behavior in the consumer because product state, controls, and renderer cadence
remain consumer-owned.

For the bundled SpriteKit consumer:

```bash
./run demo
```

The control window automatically spawns one object. Exercise every shape and
size, Clear, Hide/Show, cursor collision, and click-through behavior manually;
do not infer those results from the process staying alive.

For a concrete click-through check, leave the balls visible and click a named
control in another app, such as a Codex task in the left sidebar. Confirm that
the other app performs that exact action; merely seeing another app underneath
the transparent surface is not enough.

For physics diagnostics:

```bash
./run demo-trace
```

The trace samples position, velocity, and SpriteKit resting state for eight
seconds after the latest spawn. Interpret visual jitter from position changes,
not `resting` alone: SpriteKit may report `resting=false` while position and
velocity remain stable at zero.

For character controls:

1. Spawn the player while controls are off.
2. Press **Turn Controls On** and grant Accessibility access if requested.
3. Return to the demo and press the button again; permission alone must not
   silently enable controls.
4. Select **WASD**. Confirm A/D and W work, Space jumps, and arrow keys reach
   the frontmost app rather than controlling the player.
5. Select **Arrows**. Confirm Left/Right and Up work, Space jumps, and WASD
   reaches the frontmost app rather than controlling the player.
6. Select **Both** and confirm both families control the player. Holding a jump
   key must not create repeated jumps.
7. Select **Stick Figure**. Confirm standing has a subtle idle pose, walking
   cycles the limbs and mirrors left/right, and holding Shift is visibly faster
   with a distinct run pose.
8. Jump toward either screen edge. Keep holding toward the edge and confirm the
   figure changes to a wall-slide pose and descends gradually rather than at
   normal fall speed. Press jump while sliding and confirm it launches mostly
   upward with only a modest push away, then repeat once from the opposite edge.
   Confirm landing and wall contact do not make the character bounce.
9. Land, press C, and confirm the figure sits. Press C again to stand; then sit
   once more and confirm movement or jump also stands the character up.
10. Replace the player with Circle, Square, Triangle, and Random in turn;
   confirm both its visible geometry and collisions change.
11. Press Command-Tab and confirm normal app switching.
12. Use a gameplay letter with Command held and confirm the shortcut is not
   swallowed.
13. Turn controls off from the normal window and confirm the keys return to the
    frontmost app.

For direct object manipulation:

1. Turn **Click and drag objects** on and confirm the orange interception
   warning appears.
2. Drag a spawned object by an off-center point and confirm it follows without
   snapping its center to the pointer.
3. Flick-release it and confirm it flies with the gesture, then hold another
   object still before release and confirm it drops instead of using stale
   velocity.
4. Confirm the player is not draggable.
5. Use the still-visible control window to turn drag mode off, then click a
   named control in another app and confirm click-through is restored.

## Interpreting Failures

- A build failure is package/compiler evidence; fix it before interpreting UI.
- A property-test failure means the requested AppKit contract was not applied.
- A physical failure with passing tests means the property contract was too
  weak or macOS behavior differs from the assumption; preserve the evidence and
  update the smallest responsible seam.
- A docs failure may indicate duplicate IDs, invalid statuses, stale generated
  views, or a broken local link. Do not hand-edit generated root registries.

## Current Limits

Passing `./run check` is necessary for closeout, but it remains build,
contract, documentation, and diff evidence. It is not visual, physical,
accessibility, performance, or remote-CI evidence.
