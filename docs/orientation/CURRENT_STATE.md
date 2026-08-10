---
type: current-state
title: Current State
domain: orientation
status: active
created_at: "2026-08-09 03:50:00 JST +0900"
updated_at: "2026-08-11 06:22:00 JST +0900"
owner:
areas: [AREA-OVERLAY-HOST, AREA-DESKTOP-PHYSICS]
related_specs: [SPEC-0001, SPEC-0002]
related_plans: [PLAN-0001, PLAN-0002, PLAN-0003]
related_adrs: [ADR-0001, ADR-0002, ADR-0003, ADR-0004, ADR-0005]
related_sessions:
  - 2026-08-09-project-foundation-and-overlay-boundary
repo_state:
  based_on_commit: efaf82d290a31a5cab0142cf1a1afa50112d89b9
  last_reviewed_commit: efaf82d290a31a5cab0142cf1a1afa50112d89b9
---

# Current State

GlobalOverlayKit is an untagged macOS 13+ Swift package with an initial
clean-room AppKit implementation. Source and contract tests exist on disk; this
page separates that fact from behavior that still needs to be watched on a real
Mac.

## What Exists Today

- `GlobalOverlay` owns one transparent, non-activating `NSPanel` and hosts any
  caller-provided `NSViewController`.
- A generic SwiftUI initializer wraps content in `NSHostingController` without
  making SwiftUI the core abstraction.
- `GlobalOverlayConfiguration` covers initial frame, minimum size, pointer
  interaction, move/resize flags, all-Spaces/full-screen flags, shadow,
  accessibility label, and an optional AppKit frame-autosave name.
- Callers can show, hide, change pointer pass-through, update a frame, or fill a
  selected `NSScreen`.
- Focused tests inspect the constructed panel contract and in-place interaction
  and frame updates.
- The root `./run` command provides build, test, documentation, and combined
  check paths. GitHub Actions runs package tests and documentation checks.
- The first public GitHub Actions run passed its package and documentation jobs
  on macOS after the repository was pushed.
- `Examples/DesktopPhysicsDemo` is a nested Swift package that consumes the
  public library seam, hosts a transparent `SKView`, and provides a normal
  Spawn/Clear/Show-Hide/Quit control window.
- The first consumer run exposed and fixed a generic construction bug: AppKit
  adopted the supplied controller view's size after installation, overriding
  the configured panel frame. The host now reapplies its owned frame after
  controller installation, with a regression assertion.
- A clean second run visibly rendered multiple colored balls over other app
  content on the main display.
- The first physics tuning used `-980` gravity by incorrectly treating
  SpriteKit units as scene points per second squared. User observation and an
  opt-in trajectory trace exposed the resulting fast fall and floor jitter.
  Gravity now uses SpriteKit's documented Earth value of `-9.8`, collision
  restitution is `0.48`, and a single-ball trace reached a stable floor
  position and zero vertical velocity.
- `./run demo-trace` provides bounded position, velocity, and resting-state
  samples for up to six balls after the latest spawn.
- `Examples/DesktopPhysicsDemo` now exports a separate `DesktopPhysicsKit`
  library target. `DesktopPhysicsWorld` hides overlay, SpriteKit view/scene,
  body construction, cursor mapping, and selective-control setup from callers.
- The nested target supports circle, square, triangle, and random objects at
  small, medium, large, or random sizes, with mass scaled by area.
- An optional global-cursor collider remains inside the selected display and
  does not change the overlay's click-through policy.
- An optional direct-manipulation mode lets spawned objects follow click-drag
  input and resume physics on release. Recent drag motion becomes bounded throw
  velocity; pausing before release drops instead. Only roots explicitly marked
  draggable capture pointer input while hovered or during an active drag;
  empty desktop remains click-through even while the mode is enabled.
- Down/S plus Jump ignores every coincident visible-window edge at the current
  support height until the previous physics frame is fully below its landing
  tolerance. The input path accepts the intrinsic Function flag that macOS
  carries from a held arrow onto Space, while Command, Control, and Option
  still fail closed.
- A selectable sprite-animated stick figure, circle, square, triangle, or random
  player supports horizontal movement, Shift-to-run, grounded jump, sticky
  wall slide, primarily vertical wall jump, and C-to-sit. The stick figure
  renders distinct idle, walk, run, jump, wall-slide, and sit frames with
  directional mirroring and a Reduce Motion path. Selected frames come from a
  CC0 pack with retained source/license provenance. The control family can be
  limited to WASD, arrows,
  or both; Space and C remain available in every mode. Global controls use
  an active Core Graphics event tap, are off by default, require an explicit
  Accessibility grant, bypass modified events, and fail off if macOS disables
  the tap.
- The demo is now a normal Xcode-built app with stable bundle ID
  `com.owensantoso.DesktopPhysicsDemo`, Apple Development signing, a Dock icon,
  a visible controls window, and Command-0 recovery.
- An experimental `MacDesktopWindowGeometry` product observes qualifying
  on-screen application-window IDs and frames through canonical
  `DesktopSurfaceKit`, converts and clips them into the selected display, and
  fails off behind the app's explicit Accessibility permission contract. The
  normal control window exposes live enable/count/error state.
- Loose objects collide with complete window rectangles. The player instead
  uses descending-from-above one-way top surfaces; only an already supported
  player follows a small move/resize, preventing new window intrusions from
  squishing or trapping it.
- A default-on testing visualization outlines each complete window collider in
  cyan and its one-way player top edge with a thicker capped yellow line. The
  normal control window can hide the outlines independently; they carry no
  physics bodies and track the same stable IDs and 500 ms refresh.
- Twenty-four nested-library tests cover continuous and random-range sizes,
  cursor coordinate mapping and resizing, object/player shape construction, selective
  key-family capture, modifier clearing, derived controller parameters,
  buffered jump input, every character animation state and facing, and
  presented-scene grounding, jump, wall slide, and wall-jump admission, plus
  object grab/follow/release lifecycle, window coordinate conversion, one-way
  admission and support, and stable window-body lifecycle.
  The newest lifecycle test also proves that outline nodes track geometry,
  disappear independently, and do not replace or gain collision bodies.
  Canonical DesktopSurfaceKit owns and separately tests the raw global-Quartz
  enumeration/filtering contract; the nested adapter retains product-specific
  permission and coordinate policy.
  A transparent-renderer regression test also requires the production
  `SKView` host to disable explicit AppKit layer backing after scene
  presentation. On the current macOS SpriteKit runtime, the layer-backed form
  simulated normally but rendered every node invisibly.
  The signed app builds and
  its designated requirement is based on bundle ID plus the stable Apple
  Development certificate rather than a binary hash.

## Not Yet Proven Or Built

- No tagged release or semantic-version compatibility promise exists yet.
- No Agent Commander or external repository consumes the package yet; the
  current consumer lives under `Examples/`.
- The project owner explicitly accepted the tuned ball behavior, varied object
  shapes, cursor collision, click-through, and Accessibility permission flow.
  The first player build failed physically because arrows were filtered and
  jump was ineffective; after the input, grounding, and controller changes,
  the owner's verdict was “way better.” The subsequent control-family,
  selectable-player, Command-Tab, and control-disable protocol received “all
  good.” The first animated stick-figure physical run failed: the improvised
  procedural poses looked bad, the wall jump traveled much too far
  horizontally, and the player should not bounce. That renderer has been
  replaced with authored CC0 frames, the wall jump now favors vertical motion,
  and player restitution is zero; this correction awaits a new physical
  verdict. The object drag mode also still awaits physical acceptance.
  Hide/Show, focus
  preservation, all Spaces, full-screen apps, drag/resize, frame restoration,
  accessibility, and multi-display behavior remain unverified.
- Window-platform physics now consumes private exact DesktopSurfaceKit
  `0.1.0-rc.3` rectangular occlusion and source-side provenance. Fully covered regions are removed; cyan
  outlines show remaining object colliders, while yellow lines mark only
  genuinely visible source-window tops and bottoms. Visible original left and
  right edges can independently become player walls. Outline visibility,
  one-way platforms, side walls, and jump height are separate controls.
  Automated coordinate, filtering, all-side provenance, top/bottom landing
  admission, occlusion-cut suppression, anti-crush, collision-mask, and stable-ID lifecycle coverage passes. The prior full-
  rectangle compositor evidence is superseded. The corrected signed universal
  app is installed and reports 43 visible regions in the current arrangement;
  it still needs outline appearance, top/bottom traversal, collision feel,
  secondary-display, and current-Space acceptance from the project owner.
- The current character/controller candidate adds independent Spacebar jump,
  S/Down+Jump support-edge drop-through, exactly one air jump, double-tap-and-
  hold wall run on enabled visible side walls, run-dependent horizontal jump
  travel, a player-only open screen top, and player dragging. Game World Mode
  fades an opaque white SpriteKit backdrop together with black enabled-edge
  presentation; Reduce Motion applies the same end state atomically. These
  mechanics and transition feel still require installed physical acceptance.
- Godot reuse now has two separately versioned proposed seams. ADR-0004's
  `desktop-window-feed` supplies local macOS observation to a future Godot
  authority. ADR-0005's `desktop-game-state` supplies privacy-filtered
  surfaces, entities, assets, and events to replicas. The pure nested
  `DesktopGameCore` target is now implemented with validated Foundation-only
  values, frozen planar/depth JSON fixtures, base-sequence recovery, a planar
  capability gate, deterministic painted-candidate selection, canonical
  quaternion signs, an exclusive replica coordinator that validates, applies,
  and commits synchronously with stale-tick rejection, atomic authority-side
  entity-ID retirement, and
  coincident-plane-scoped wall traversal through full-bounds clearance.
  Version-1 viewport
  JSON fixes the origin at the bottom-left of the screen plane and the units as
  world units; a fixture proves conversion from top-left observation space.
  Deltas reject duplicate and conflicting identity operations at construction
  and decode. The Godot fixture consumer and SpriteKit state adapter are not
  implemented yet. Version-1 state is right-handed X/Y/Z with the collapsed desktop
  on `Z = 0`; SpriteKit remains the first planar authority. A local Godot pipe probe passed, but
  the current 2x Retina mismatch still blocks collider-ready window-feed work.
- DesktopSurfaceKit geometry itself is permission-free. The current consumer's
  Accessibility trust guard around geometry is an ownership bug to remove;
  global keyboard capture and the proposed optional focus observer retain
  their separate Accessibility behavior.
- Screen-filling configuration is a frame snapshot. The caller still owns
  reacting to display attachment, removal, rotation, or resolution changes.
- There is no multi-overlay coordinator, general keyboard remapper, custom
  physics engine, entity-component system, message renderer, agent integration,
  or persistence model.
- This Mac has a Bosch BMI286 accelerometer and gyroscope, but macOS exposes no
  public non-privileged chassis-motion API for them. Desktop Physics therefore
  has no tilt-gravity toggle or private/root sensor integration. The evidence
  and reopen conditions are in
  [RSCH-0009](../research/RSCH-0009-macos-built-in-inertial-sensor-readiness.md).

## Current System Model

- `GlobalOverlay` is the public surface host.
- `NSPanel` is a private AppKit implementation primitive.
- `NSViewController` is the renderer-neutral content seam.
- SwiftUI is a convenience adapter through `NSHostingController`.
- Each caller owns its content, state, cadence, input policy, and product
  semantics.
- One `GlobalOverlay` instance represents one surface; an app creates and
  coordinates multiple instances when needed.

Source docs:

- [Architecture](ARCHITECTURE.md)
- [Overlay host area](../architecture/areas/AREA-OVERLAY-HOST.md)
- [Approved baseline](../product/specs/SPEC-0001-global-overlay-surface-host.md)
- [Boundary decision](../decisions/adr/ADR-0001-keep-content-and-product-behavior-outside-the-overlay-host.md)

## Roadmap Position

The initial package API and ball-demo milestone are complete. The reusable
desktop-world target and signed control app are implemented under `PLAN-0003`;
physical acceptance of object dragging and the newest character behaviors are
the remaining gates.
Agent Commander remains the independent message consumer.

See [ROADMAP.md](ROADMAP.md),
[PLAN-0001](../product/plans/PLAN-0001-clean-room-overlay-host-mvp/PLAN-0001-clean-room-overlay-host-mvp.md),
and [PLAN-0002](../product/plans/PLAN-0002-desktop-physics-falsification-demo/PLAN-0002-desktop-physics-falsification-demo.md).
The active work is [PLAN-0003](../product/plans/PLAN-0003-reusable-desktop-world-and-character-controls/PLAN-0003-reusable-desktop-world-and-character-controls.md).

## Key Gotchas

- `interactive` only means the panel may receive pointer events. It does not
  grant global keyboard capture or prove key-window behavior.
- `isMovable` cannot be exercised while pointer events pass through the panel.
- All-Spaces and full-screen collection flags are configuration claims until
  their physical behavior is observed.
- `fill(_:)` uses the supplied screen's frame once; it does not monitor display
  topology.
- Core Graphics, not Accessibility, supplies window IDs and rectangles for the
  experimental platform provider. Accessibility is the explicit fail-off gate
  shared with global player controls.
- Installing an `NSViewController` can cause AppKit to adopt the controller
  view's existing size. The host must reassert its configured frame after
  installation; the construction test protects this invariant.
- The public name is GlobalOverlayKit because callers care about the overlay
  surface. Window and panel terminology describes the current implementation,
  not the product boundary.

## Verification Baseline

Use:

```bash
./run check
```

The baseline compiles the package and desktop-physics example, runs focused
Swift tests, checks committed structured docs, checks local links, runs the
continuity smoke test, and checks diff whitespace. Use `./run docs` when
source-doc changes need generated views refreshed. The command still supplies
no visual, physical, accessibility, or performance evidence by itself.

For the evidence matrix, see [the testing guide](../repo-health/testing-guide.md).

## Where To Look

| Need | Read |
|---|---|
| Package walkthrough | [ONBOARDING.md](ONBOARDING.md) |
| Boundary and flow | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Ordered next evidence | [ROADMAP.md](ROADMAP.md) |
| Public requirements | [SPEC-0001](../product/specs/SPEC-0001-global-overlay-surface-host.md) |
| Source entry points | [Codebase map](../repo-health/codebase-map.md) |
| Interface ownership | [Data and seams](../repo-health/data-seams.md) |
| Prior-art evidence | [RSCH-0001](../research/RSCH-0001-global-overlay-prior-art-and-package-boundary.md) |

## Maintenance Rule

Update this page only when package truth, verification evidence, or roadmap
position changes. Keep session chronology in session logs and design rationale
in ADRs.
