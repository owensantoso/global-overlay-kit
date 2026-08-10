---
type: implementation-brief
id: IMPL-0003-03
title: Integrate Painted Player Picking And Window Wall Traversal
domain: product
status: completed
created_at: "2026-08-11 06:28:45 JST +0900"
updated_at: "2026-08-11 07:03:23 JST +0900"
parent_plan: PLAN-0003
task_refs: []
owner:
areas: [AREA-DESKTOP-PHYSICS]
depends_on: [IMPL-0003-02, ADR-0005]
parallel_with: []
related_specs:
  - SPEC-0002
related_adrs: [ADR-0005]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
related_issues: []
related_prs: []
linked_paths:
  - Examples/DesktopPhysicsDemo/Package.swift
  - Examples/DesktopPhysicsDemo/Sources/DesktopPhysicsKit
  - Examples/DesktopPhysicsDemo/Sources/MacDesktopWindowGeometry
  - Examples/DesktopPhysicsDemo/Tests/DesktopPhysicsKitTests
repo_state:
  based_on_commit: 4748418e1b0de40395f39dffc27c6c6ab86a1aa7
  last_reviewed_commit: cf8153ae2e738effd84d404a381079794e2fe82b
---

# IMPL-0003-03 - Integrate Painted Player Picking And Window Wall Traversal

## Parent Plan

- PLAN-0003

## Task Goal

Connect the existing pure `DesktopGameCore` interaction policies to the live
SpriteKit authority so player dragging follows the current avatar's painted
pixels, window-wall jumps can traverse one complete coincident physical plane,
and ordinary Quartz window geometry no longer depends on Accessibility trust.

## Scope

In scope:

- make `DesktopPhysicsKit` consume `DesktopGameCore` without moving any
  SpriteKit, AppKit, Core Graphics, or image-decoding type into the pure target;
- decode each immutable stick-figure PNG frame into a cached alpha mask and
  convert scene points through the live node/sprite transforms into mask space;
- preserve geometric painted selection for shape players and spawned shapes;
- resolve draggable candidates front-to-back through
  `DesktopPaintedCandidateSelection`, with the current avatar frame deciding
  stick-figure coverage instead of its texture rectangle or physics collider;
- preserve pointer capture after a painted mouse-down until mouse-up;
- give visible left/right window edges stable feature IDs and plane values,
  begin traversal only on fresh Jump while holding toward the contacted edge,
  exclude every coincident edge until prior-frame player bounds fully clear,
  and retain the existing outward wall jump for neutral/away input;
- remove the Accessibility trust gate from `MacDesktopWindowGeometryProvider`
  and `DesktopPhysicsWorld` while leaving global-key input permission behavior
  unchanged;
- update current-state, testing, area, and session receipts with exact automated
  versus physical evidence.

Out of scope:

- Godot adapters, multiplayer transport, portable-state emission, focus
  observation, DesktopSurfaceKit release work, or message/bubble overlays;
- changing player collider geometry, object physics, non-window wall behavior,
  window occlusion policy, or visual assets;
- installing, tagging, releasing, pushing, or claiming human visual/feel
  acceptance.

## Execution Steps

1. Add focused failing tests for transparent versus painted avatar pixels,
   current-frame changes, mirroring/coordinate conversion, empty click-through,
   drag capture/release, permission-free injected geometry, toward-wall
   traversal, center-cross straddling, coincident planes, distinct planes, and
   away-wall regression.
2. Add a small immutable alpha-mask/cache seam next to
   `DesktopStickFigureNode`; load alpha from the shipped RGBA resources and let
   the figure answer painted coverage through live SpriteKit conversion.
3. Replace first-hit `nodes(at:)` player selection with deterministic candidate
   evaluation through the pure core policy while keeping engine pointer capture
   and physics mutation scene-owned.
4. Extend window-side collision/contact values with feature identity, map them
   into the pure wall policy, and keep one traversal state until previous-frame
   full-bounds clearance.
5. Remove the obsolete Accessibility guard from geometry observation and the
   world command path. Preserve `.unavailable` handling and separate keyboard
   input permission errors.
6. Run focused tests, the complete nested suite, root documentation and full
   checks, and a signed Debug build. Complete independent contract/code review
   before committing.

## Verification

```bash
swift test --package-path Examples/DesktopPhysicsDemo \
  --filter DesktopPhysicsKitTests
swift test --package-path Examples/DesktopPhysicsDemo
./run docs
./run check
codesign --verify --deep --strict \
  "Examples/DesktopPhysicsDemo/App/DerivedData/Build/Products/Debug/Desktop Physics Demo.app"
```

Automated coverage may prove mask sampling, transform conversion, deterministic
selection, pointer-capture state, wall-state transitions, geometry permission
ownership, and signed compilation. It does not prove that clicking feels
pixel-perfect, wall traversal feels natural, or the installed overlay routes
real pointer/key input correctly.

## Done Checklist

- [x] Painted player picking consumes current shipped frame masks
- [x] Pointer capture remains active only after a valid draggable mouse-down
- [x] Window-wall traversal consumes core policy through full-bounds clearance
- [x] Away/neutral and distinct-plane collision regressions pass
- [x] Quartz geometry no longer checks Accessibility trust
- [x] Focused and complete automated verification passes
- [x] Independent contract and code reviews pass
- [x] Paper trail separates automated from pending human acceptance

## Implementation Evidence

`DesktopPhysicsKit` now imports the Foundation-only core and delegates
front-to-back painted-candidate choice and wall jump/traversal decisions to its
pure policies. `DesktopStickFigureNode` loads each shipped RGBA frame once as a
texture plus immutable 8-bit alpha mask and samples the current frame through
SpriteKit's live coordinate conversion. The scene keeps pointer capture and
physics mutation local, and shape roots use their actual fill/stroke paths.

Window-side features now carry stable source-fragment/side IDs and X planes.
The adapter selects the nearest probed feature deterministically, excludes all
features coincident with active traversal, and reconciles contact/traversal as
live window fragments move or disappear. Contact grace requires exact feature
survival; an active traversal survives fragment replacement while any feature
on its physical plane remains. Global-key Accessibility checks remain in the
input controller, while Quartz window geometry no longer branches on trust.

The independent review found and closed three P1 issues: one-frame-stale panel
routing after an animation-frame change, dictionary-order selection among
nearby wall planes, and stale contact/traversal after source removal. It also
corrected reconciliation so a coincident replacement cannot re-enable the wall
before full-bounds clearance. Final re-review reported no P0 or P1 findings.

The final focused adapter suite contains 41 passing XCTest cases. The complete
nested package additionally contains 44 passing Swift Testing cases. Root docs,
the full `./run check`, the Apple Development-signed arm64 Debug build, strict
codesign verification, and diff hygiene pass.

After commit `cf8153a`, a fresh universal `arm64`/`x86_64` hardened Release app
was built, verified with a certificate-and-identifier designated requirement,
installed at `~/Applications/Desktop Physics Demo.app`, and launched from that
exact path. Owen reported **Both pass** for the self-contained installed-app
protocol: transparent pixels immediately around the current avatar passed
through while painted-pixel drag capture persisted through mouse-up; toward-
wall Jump crossed the complete visible-window plane without snagging while an
away-wall Jump remained outward; and enabling ordinary window platforms did
not introduce an Accessibility prompt. The replaced build remains recoverable
from `~/.Trash/Desktop Physics Demo.app.pre-painted-picking-20260811-065800`.
