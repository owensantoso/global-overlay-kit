---
type: data-seams
title: Data Model And Seams
domain: architecture
status: active
created_at: "2026-08-09 03:50:00 JST +0900"
updated_at: "2026-08-09 03:56:00 JST +0900"
owner:
areas: [AREA-OVERLAY-HOST]
related_specs: [SPEC-0001]
related_plans: [PLAN-0001]
related_adrs: [ADR-0001]
related_sessions:
  - 2026-08-09-project-foundation-and-overlay-boundary
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# Data Model And Seams

GlobalOverlayKit intentionally has no product data model. Its small model
describes native surface mechanics while every consumer retains ownership of
the data it renders.

## Canonical Seams Today

- `GlobalOverlayConfiguration` is the public configuration value.
- `GlobalOverlayInteraction` is the pointer-routing vocabulary.
- `NSViewController` is the canonical content boundary.
- `GlobalOverlay` is the lifecycle owner for one private AppKit surface.
- `CGRect` and `NSScreen` are placement inputs, not a package-owned screen
  registry.

## Caller-Facing Interfaces

| Interface | Caller | Hidden Complexity | Owner |
|---|---|---|---|
| AppKit initializer | Native renderer | Panel construction and property mapping | `AREA-OVERLAY-HOST` |
| SwiftUI initializer | SwiftUI renderer | Hosting-controller creation | `AREA-OVERLAY-HOST` |
| Configuration value | Product coordinator | AppKit flags and initial panel setup | `AREA-OVERLAY-HOST` |
| Show/hide | Product coordinator | Window ordering | `AREA-OVERLAY-HOST` |
| Interaction setter | Product coordinator | `ignoresMouseEvents` mapping | `AREA-OVERLAY-HOST` |
| Frame/fill setters | Product coordinator | AppKit frame application | `AREA-OVERLAY-HOST` |

## Persistence Boundary

The package owns no database, file format, user-defaults schema, or restoration
policy. An optional `frameAutosaveName` delegates frame persistence to AppKit;
the caller chooses whether the name is stable and how it fits its product
settings. GlobalOverlayKit must not infer user identity or content state from
that name.

## Compatibility And Private Seams

- The SwiftUI initializer is a convenience adapter, not a second canonical
  model.
- The private `NSPanel` is replaceable implementation plumbing.
- `windowForTesting` is module-internal test access. Exposing it publicly would
  let callers create untracked behavior and dissolve the package boundary.
- `screenFilling(_:)` is a configuration factory, not a display manager.

## Extension Rules

- Extend `GlobalOverlayConfiguration` only for surface mechanics shared by
  independent consumers.
- Extend the `GlobalOverlay` lifecycle only when the host must perform the
  operation to preserve its invariants.
- Keep message, game, speech, render, input-command, and persistence data in the
  consuming product.
- Prefer one more consumer-side line over a new package protocol that merely
  renames a product callback.
- If consumers need coordinated multi-surface behavior, first test whether the
  policy is actually identical in two applications.

## Common Mistakes

- Treating `interactive` as a global keyboard or activation mode.
- Mutating caller state from the overlay host.
- Adding `Message`, `Scene`, `Entity`, `tick`, or `render` concepts here.
- Retaining `NSScreen` as if display topology were stable.
- Animating many native windows when one renderer-owned screen surface would
  work.
- Copying a consumer or prior-art implementation instead of implementing from
  public Apple APIs.

## Terms To Preserve

- `surface` - the stable hosted region visible to the caller.
- `panel` - the current private AppKit primitive.
- `content` - caller-owned native view-controller hierarchy.
- `interaction` - pointer hit testing only in the current API.
- `consumer` - the application that owns product behavior and coordinates one
  or more overlays.

## Read This Before Changing

- [AREA-OVERLAY-HOST](../architecture/areas/AREA-OVERLAY-HOST.md)
- [SPEC-0001](../product/specs/SPEC-0001-global-overlay-surface-host.md)
- [ADR-0001](../decisions/adr/ADR-0001-keep-content-and-product-behavior-outside-the-overlay-host.md)
- `Sources/GlobalOverlayKit/GlobalOverlayConfiguration.swift`
- `Sources/GlobalOverlayKit/GlobalOverlay.swift`
