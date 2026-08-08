---
type: current-state
title: Current State
domain: orientation
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

## Not Yet Proven Or Built

- No tagged release or semantic-version compatibility promise exists yet.
- No Agent Commander or other external app consumes the package yet.
- No example app has physically demonstrated focus preservation, click-through,
  all Spaces, full-screen apps, drag/resize, frame restoration, accessibility,
  or multi-display behavior.
- Screen-filling configuration is a frame snapshot. The caller still owns
  reacting to display attachment, removal, rotation, or resolution changes.
- There is no multi-overlay coordinator, global keyboard capture, message
  renderer, render loop, physics engine, agent integration, or persistence
  model.

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

The initial package API is implemented. Automated closeout can prove that it
compiles and that configured AppKit properties match the contract; the next
meaningful evidence is a physical Agent Commander consumer, followed by the
independent SpriteKit falsification consumer.

See [ROADMAP.md](ROADMAP.md) and
[PLAN-0001](../product/plans/PLAN-0001-clean-room-overlay-host-mvp/PLAN-0001-clean-room-overlay-host-mvp.md).

## Key Gotchas

- `interactive` only means the panel may receive pointer events. It does not
  grant global keyboard capture or prove key-window behavior.
- `isMovable` cannot be exercised while pointer events pass through the panel.
- All-Spaces and full-screen collection flags are configuration claims until
  their physical behavior is observed.
- `fill(_:)` uses the supplied screen's frame once; it does not monitor display
  topology.
- The public name is GlobalOverlayKit because callers care about the overlay
  surface. Window and panel terminology describes the current implementation,
  not the product boundary.

## Verification Baseline

Use:

```bash
./run check
```

The baseline compiles the package, runs focused Swift tests, refreshes and
checks structured docs, checks local links, runs the continuity smoke test, and
checks diff whitespace. It does not supply visual, physical, accessibility, or
performance evidence.

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
