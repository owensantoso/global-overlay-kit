---
type: architecture-area
id: AREA-DESKTOP-PHYSICS
title: Desktop Physics Adapter
domain: architecture
status: active
created_at: "2026-08-10 00:18:00 JST +0900"
updated_at: "2026-08-11 02:25:37 JST +0900"
owners: []
related_specs: [SPEC-0002]
related_plans: [PLAN-0003]
related_adrs: [ADR-0001, ADR-0002]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
related_issues: []
related_prs: []
linked_paths:
  - Examples/DesktopPhysicsDemo
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# AREA-DESKTOP-PHYSICS - Desktop Physics Adapter

## Purpose

Provide a reusable caller-facing desktop-world layer over GlobalOverlayKit and
SpriteKit without changing either underlying engine's ownership.

## Owns

- one selected display's overlay plus SpriteKit scene integration
- desktop-world object vocabulary, spawning, and diagnostics
- cursor-to-scene coordinate mapping and optional cursor collider
- explicit spawned-object direct manipulation and its overlay interaction mode
- one shape-selectable player, responsive controller profile, selectable
  WASD/arrows/both input family, independently optional Spacebar jump,
  drop-through, double jump, wall run, and bounded game-control lifecycle
- object collision and one-way top/bottom landing policy for selected-display
  visible window fragments
- independent player-platform, visible-side-wall, and nonphysical
  debug-presentation controls
- runtime jump-height tuning expressed in the existing controller profile's
  designer-facing units
- player direct manipulation and a player-only open top-screen boundary
- the reversible desktop-to-white-game presentation transition, including
  Reduce Motion behavior and black enabled-edge rendering
- library-facing show/hide/clear/count commands

## Does Not Own

- native overlay mechanics below the `GlobalOverlay` API
- SpriteKit's physics solver, renderer, or cadence
- arbitrary game architecture, levels, assets, ECS, or persistence
- general global-key remapping or macOS automation
- external trigger detection, gesture sequence policy, or cross-application
  action catalogs
- Accessibility UI-element traversal or pixel-visible window silhouettes
- demo control-panel layout or product branding

## Canonical Caller

The first caller is `DesktopPhysicsDemo`, which depends on the library product
and owns only SwiftUI state/presentation.

## Boundary Flow

```text
DesktopPhysicsDemo controls, one-shot App Intent, or strict semantic App Action
  -> DesktopPhysicsWorld commands
    -> MacDesktopWindowGeometry observation (optional)
      -> DesktopSurfaceKit observation plus rectangular visible-region geometry
      -> product-owned Accessibility gate and scene coordinates
    -> SpriteKit scene/controller and collision policy
      -> GlobalOverlayKit surface
        -> private AppKit panel
```

## Invariants

- Command-modified input always passes through.
- Pointer collision never requires the overlay to accept pointer clicks.
- The world tears down every input resource when control mode ends.
- GlobalOverlayKit remains free of desktop-world and SpriteKit types.
- DesktopPhysicsKit remains free of App Intents, transport notifications, and
  Hold Keys types; external invocation is an executable-target adapter over its
  domain commands.
- `MacDesktopWindowGeometry` reports selected-scene rectangles; it does not
  import SpriteKit or decide collision meaning.
- Canonical `DesktopSurfaceKit` owns raw global-Quartz window observation. The
  nested compatibility adapter owns only this product's permission gate,
  selected-display conversion, and legacy `MacDesktopWindow` surface.
- Core Graphics supplies window IDs/frames. Accessibility is a visible fail-off
  gate and must not be described as the rectangle source.
- Visible-fragment rectangle bodies collide with loose objects but never with
  the player; one-way top/bottom landing and supported-window reconciliation
  are game-owned policy.
- Fragment edges created only by subtraction are not player platforms. The
  reusable geometry fragment preserves which original source sides survive,
  and only those edges enter player platform or wall policy.
- DesktopSurfaceKit owns live source-window identity, owning-process metadata,
  front-to-back source order, and axis-neutral source-side provenance. The
  consumer alone maps global Quartz sides to visual top/bottom/left/right and
  assigns collision meaning.
- Window-platform outlines are parallel SpriteKit presentation nodes keyed by
  stable window-plus-fragment IDs. They never own or alter physics bodies, and
  their visibility is independent from player collision.
- Keyboard input emits intent; pure controller policy owns bounded jump-count
  and double-tap timing; the SpriteKit scene alone owns collision queries,
  support-edge suppression, body mutation, and drag lifecycle.
- The scene is the sole owner of the Game World Mode transition so backdrop
  opacity and edge styling cannot diverge during reversal. Gameplay and input
  state are invariant across that presentation-only transition.
- Public API growth requires a concrete caller job, not speculative engine
  flexibility.

## Current Status

Implemented as the nested `DesktopPhysicsKit` library and consumed by the
separate signed `Desktop Physics Demo.app`. Cursor behavior, the revised player
controller, player shapes, and control families have positive physical
evidence. The newest direct-manipulation mode remains physically unverified
before the API is considered ready for extraction.

The experimental window-platform slice is implemented behind the normal
control window. DesktopSurfaceKit's rectangular visible-region operation
removes fully covered geometry before selected-display conversion. Cyan
outlines show remaining object-collision fragments; yellow lines mark only
original visible source-window tops and bottoms used by player policy.
Visualization and character collision have independent controls. Package tests
cover the pure policy, occlusion-cut suppression, and lifecycle, but signed-app
physical feel, live permission behavior, translucent/nonrectangular window
expectations, and multi-display behavior remain unproven.

The historical non-git `DesktopSurfaceKit` POC informed this seam but is not a
dependency or source of truth. Its reusable observation contract has since
been promoted into the canonical version-controlled `DesktopSurfaceKit`
repository and is consumed through the narrow compatibility adapter. The
provenance and readiness transition are recorded in
[RSCH-0008](../../research/RSCH-0008-macos-window-geometry-reuse-readiness.md).

The normal Release app is installed at
`~/Applications/Desktop Physics Demo.app`. Its standard Dock reopen recreates
the control window in the existing process. Its executable target accepts the
strict `owensantoso-desktopphysics://spawn/random-object` action through the
shared semantic resolver without putting automation concerns in the library.

## Maintenance Rule

Update this area when ownership, public commands, permission behavior, or
extraction status changes. Runtime receipts belong in session logs and testing
guides.
