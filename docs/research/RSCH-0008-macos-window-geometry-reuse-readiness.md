---
type: research-survey
id: RSCH-0008
title: macOS Window Geometry Reuse Readiness
domain: research
status: completed
created_at: "2026-08-10 19:01:56 JST +0900"
updated_at: "2026-08-10 21:29:33 JST +0900"
owner:
question: Is the historical DesktopSurfaceKit Accessibility geometry POC ready to supply real macOS window rectangles to Desktop Physics, and what is the smallest durable reuse path?
source:
  type: conversation
  link:
  notes:
external_sources: []
repo_findings:
  - The only local DesktopSurfaceKit copy is a dated Codex POC directory with no git repository, so it is not a durable package dependency or source of truth.
  - Its eight pure geometry and AX-window-matching tests pass, but multi-display conversion, occlusion, SpriteKit collision, and event-driven updates remain explicitly unvalidated.
  - The window IDs and frames used by the POC originate in CGWindowList; Accessibility matching exists to traverse UI elements, not to make the window rectangles authoritative.
agent_notes:
  - Adapt the narrow CG-window seam into a version-controlled macOS-specific target and keep collision meaning in DesktopPhysicsKit.
related_ideas: []
related_evaluations: []
related_adrs: [ADR-0002, ADR-0003]
related_specs: [SPEC-0002]
related_plans: [PLAN-0003]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
linked_paths:
  - Examples/DesktopPhysicsDemo/Sources/MacDesktopWindowGeometry
  - Examples/DesktopPhysicsDemo/Sources/DesktopPhysicsKit/DesktopWindowPlatformPolicy.swift
  - Examples/DesktopPhysicsDemo/Sources/DesktopPhysicsKit/DesktopPhysicsScene.swift
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# RSCH-0008 - macOS Window Geometry Reuse Readiness

## Question

Is the historical `DesktopSurfaceKit` Accessibility geometry POC ready to
supply real macOS window rectangles to Desktop Physics, and what is the
smallest durable reuse path?

## Short Answer

The POC is useful evidence and its rectangle seam is ready to adapt, but the
package itself is not ready to consume as a dependency. Its only local copy is
inside a dated, non-git Codex work directory. Depending on that path would make
an active app rely on a historical snapshot with no durable ownership or
change history.

The selected path is a narrow, version-controlled
`MacDesktopWindowGeometry` target inside the active example package. It adapts
the POC's Core Graphics window-list/filter/coordinate design, not its deep
Accessibility element traversal. `DesktopPhysicsKit` remains the owner of
SpriteKit bodies, one-way landing, and anti-crush behavior.

After that vertical slice proved the contract, the reusable global-Quartz
window observation was promoted into a canonical version-controlled
`DesktopSurfaceKit` repository. The example now depends on its
`MacDesktopWindowObservation` product through a compatibility adapter. The
adapter retains Accessibility fail-off and selected-scene conversion; physics
meaning remains in `DesktopPhysicsKit`. The original non-git POC is still only
provenance, not a dependency.

## Evidence Reviewed

The historical POC contains:

- `DesktopGeometry`, a pure rectangle-to-boundary target;
- `MacAccessibilitySnapshot`, which combines Core Graphics window discovery,
  Accessibility window matching, bounded element traversal, and boundary
  extraction;
- a JSON-lines helper used by an Electron gaze experiment;
- four boundary-extraction tests and four Accessibility frame-matching tests;
- an explainer that explicitly leaves SpriteKit collision, silhouettes,
  occlusion, and multi-display behavior unvalidated.

Fresh verification on 2026-08-10 ran the POC's Swift package tests: all eight
tests passed. This establishes the pure extraction and frame-matching examples,
not readiness as a maintained dependency or live physics provider.

## Readiness Audit

| Concern | POC evidence | Readiness verdict |
|---|---|---|
| Package and API | Separate pure geometry and macOS snapshot products; one snapshot mixes windows, elements, and boundaries | Good conceptual split, but too broad for the window-only caller |
| Permission and fail-off | Explicit trust check returns an empty untrusted snapshot; prompt is a separate method | Good fail-off shape; exact signed-app runtime trust still needs live verification |
| Enumeration and filtering | On-screen, non-desktop, layer-zero, nontransparent windows; 50-point minimum; 30-window bound | Useful baseline; own-process and nonregular-app exclusion were missing |
| AX and Core Graphics matching | CG window frames are matched to AX windows by same process and approximate frame | Necessary for element traversal, unnecessary for the window-only physics slice |
| Coordinates | Global top-left rectangles are clipped and translated by the Electron host | Primary-display path existed; reusable multi-display conversion was not tested |
| Update ownership | Electron polls focused mode at 500 ms and all-window mode at 1.5 seconds with no overlapping request | Cadence lived outside the package; no event or lifecycle contract existed |
| Stable identity | CG window number is stable enough for one window lifetime; element IDs use tree paths | Window IDs are suitable for incremental bodies; element IDs are not needed here |
| Hidden, minimized, desktop, Dock, menu bar | `optionOnScreenOnly`, desktop exclusion, and layer filtering remove most non-app surfaces | Appropriate baseline; current Spaces only and regular-app filtering must be explicit |
| Occlusion | Covered portions of on-screen windows remain in full | Accepted experimental limitation; no visible-silhouette claim |
| Stale geometry | Bounded polling refreshes snapshots | Useful, but moving/resizing bodies and overlap feel require physical evaluation |
| Live evidence | Prior signed helper reported focused and all-window geometry and drew outlines | Does not prove multi-display mapping or SpriteKit collision behavior |
| Source of truth | Only one local copy; its enclosing POC is not a git worktree | Hard blocker for direct package reuse |

## Interface Choice

### Candidate A: Depend On The Historical Package

```text
DesktopPhysicsKit -> absolute/path/DesktopSurfaceKit
```

This preserves its types directly but makes the active app depend on a dated,
non-versioned work path. It also imports element traversal and boundary output
that the first window-platform slice does not use. Rejected.

### Candidate B: Adapt The Narrow Window Seam

```text
MacDesktopWindowGeometry
  CGWindowList -> filtered stable window IDs -> selected-screen rectangles

DesktopPhysicsKit
  rectangles -> object bodies + player one-way surface policy
```

This creates a version-controlled source of truth, keeps macOS observation out
of the generic overlay host, and lets the game own physical meaning. Selected.

The initial nested implementation was later replaced by a local dependency on
the canonical `DesktopSurfaceKit` repository after its API passed explicit
compatibility gates. This resolves the source-of-truth blocker without moving
product permission, coordinate, or collision policy into the reusable package.

The provider uses `CGWindowList` for window IDs and frames. Accessibility is an
explicit fail-off feature gate because this app already presents window
platforms beside global player controls under one permission/recovery contract.
The implementation does not claim that Accessibility supplies the rectangles.

## Collision Policy

- Loose objects collide with the complete clipped rectangle of each qualifying
  on-screen app window and retain normal object restitution.
- The player never collides with those rectangle bodies. A separate policy
  admits landing only while descending and crossing a top edge from above.
- A player already supported by the same stable window ID follows a small move
  or resize. A jump, large geometry step, lost horizontal overlap, invalid
  destination, new intrusion, or missing ID detaches support.
- Because sides, bottoms, and new intrusions never collide with the player, a
  moving or resizing window cannot squeeze the player between window bodies.

This favors predictable platformer behavior over physical realism. It also
means the player can pass through the side or underside of a real window, which
is intentional.

## Accepted Limitations And Risks

- Covered or partially occluded windows still contribute their full frame.
  Objects can appear to bounce on geometry whose pixels are covered by another
  app window.
- The selected world still covers one display. Pure conversion tests cover a
  display above the main display, but live multi-display behavior is unproven.
- Window geometry is polled every 500 ms. Stable IDs preserve same-sized bodies,
  but resized bodies are recreated.
- A newly created, moved, or resized full rectangle may overlap a loose object.
  SpriteKit may eject or accelerate that object abruptly. The effect is not yet
  physically evaluated.
- Core Graphics reports on-screen window frames, not opaque visible regions or
  semantic platform suitability.
- The historical element-boundary and silhouette ideas remain outside this
  slice; this implementation consumes only application-window rectangles.

## Recommendation

Keep `MacDesktopWindowGeometry` nested and experimental until the signed app
passes a physical protocol covering object bounce, one-way landing from above,
pass-through from below, moving/resizing support, sudden overlap behavior,
current-Space filtering, and at least one secondary-display arrangement.

Do not restore a dependency on the historical POC path. If the full
`DesktopSurfaceKit` element-boundary work resumes, first migrate it into a real
owned repository and reconcile its window contract with this narrower target.
