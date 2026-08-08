---
type: architecture-area
id: AREA-OVERLAY-HOST
title: Overlay Host
domain: architecture
status: active
created_at: "2026-08-09 03:56:00 JST +0900"
updated_at: "2026-08-09 03:56:00 JST +0900"
owners: []
related_specs: [SPEC-0001]
related_adrs: [ADR-0001]
related_plans: [PLAN-0001]
related_sessions:
  - 2026-08-09-project-foundation-and-overlay-boundary
related_issues: []
related_prs: []
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# AREA-OVERLAY-HOST - Overlay Host

This area owns the reusable native surface beneath product-specific overlays.
Its boundary is deliberately narrower than chat, heads-up display, game, or
agent behavior.

## Owns

- one transparent AppKit overlay surface per `GlobalOverlay` instance
- private construction and configuration of the current `NSPanel`
- content installation through `NSViewController`
- show/hide and frame changes
- pass-through versus pointer-interactive mode
- requested all-Spaces and full-screen auxiliary collection behavior
- SwiftUI-to-AppKit hosting convenience

## Does Not Own

- content models, layout, styling, or state updates
- message streaming, agent queues, speech, or turn-taking
- scenes, physics, animation cadence, drawing loops, or pixel engines
- global keyboard input, hotkeys, voice commands, or Accessibility permission
- consumer persistence, display-selection policy, multi-surface coordination,
  or interactive recovery UI

## Stable Invariants

- The canonical content seam accepts arbitrary `NSViewController` content.
- SwiftUI stays a convenience adapter and cannot become the only renderer.
- The underlying `NSPanel` remains private.
- One host instance owns one surface; no process-global singleton is required.
- Pointer hit testing, application activation, key focus, and global keyboard
  capture remain separate concepts.
- Research repositories and consumer code are not implementation donors.

## Domain Language

| Term | Meaning | Notes |
|---|---|---|
| `GlobalOverlayKit` | The reusable package and public project identity | Named for caller-visible capability |
| overlay surface | A native region presented above other applications | Stable concept independent of the exact AppKit primitive |
| `GlobalOverlay` | The public owner of one overlay surface | Instance-scoped, main-actor type |
| host | The code that creates a surface and installs caller content | Does not direct the content lifecycle |
| content | A caller-owned `NSViewController` hierarchy | May contain AppKit, SwiftUI, SpriteKit, or Metal views |
| panel | The current private `NSPanel` mechanism | Implementation term, not public product identity |
| pass-through | Pointer events ignore the surface and reach content below | Does not describe keyboard input |
| interactive | The surface may receive pointer events | Does not guarantee key-window or app-activation behavior |

## Interfaces And Seams

| Interface | Caller | Owns | Does Not Own |
|---|---|---|---|
| `GlobalOverlay(configuration:contentViewController:)` | AppKit/SpriteKit/Metal consumer | Surface creation and content installation | Renderer or scene state |
| `GlobalOverlay(configuration:content:)` | SwiftUI consumer | `NSHostingController` convenience | SwiftUI state or view semantics |
| `show()` / `hide()` | Product coordinator | Native surface ordering | Product visibility policy |
| `setInteraction(_:)` | Product coordinator | Pointer hit-test mode | Global input or focus strategy |
| `setFrame(_:)` / `fill(_:)` | Product coordinator | Apply requested frame | Display monitoring or placement policy |
| `GlobalOverlayConfiguration` | All consumers | Initial native mechanics | Consumer product configuration |

## Intended Flow

1. The caller creates or describes rendered content.
2. The caller configures surface mechanics.
3. `GlobalOverlay` creates one private panel and installs the content controller.
4. The caller presents and updates the surface through the public lifecycle.
5. The caller continues to own content state, cadence, input commands,
   persistence, and display-change reactions.

## Current Mismatch And Evidence Notes

- The current implementation matches the initial interface boundary.
- Collection flags and pointer properties have automated contract coverage,
  but their real interaction with Spaces, full-screen apps, focus, and other
  processes remains physically unverified.
- `fill(_:)` applies current `NSScreen` geometry once; there is no automatic
  topology observer.
- Only initial all-Spaces/full-screen/movement/resize configuration and two
  in-place mutators are public. Runtime reconfiguration should be added only
  for a proven consumer need.

## Related Docs

- [Architecture overview](../../orientation/ARCHITECTURE.md)
- [SPEC-0001](../../product/specs/SPEC-0001-global-overlay-surface-host.md)
- [ADR-0001](../../decisions/adr/ADR-0001-keep-content-and-product-behavior-outside-the-overlay-host.md)
- [PLAN-0001](../../product/plans/PLAN-0001-clean-room-overlay-host-mvp/PLAN-0001-clean-room-overlay-host-mvp.md)
- [Data and seams](../../repo-health/data-seams.md)
- [Testing guide](../../repo-health/testing-guide.md)

The rule that must survive refactors is: this area hosts a surface; consumers
own everything rendered, simulated, spoken, or commanded inside it.
