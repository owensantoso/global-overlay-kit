---
type: onboarding
title: Project Onboarding
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

# Project Onboarding

GlobalOverlayKit is a small macOS Swift package that lets an application place
arbitrary native content above other applications. It exists so consumers can
reuse the difficult window mechanics without sharing chat models, a game
engine, or any other product behavior.

## Why The Name Is GlobalOverlayKit

The public promise is a global overlay surface:

- **Global** means presentation can remain visible across application context,
  Spaces, and full-screen applications when macOS permits and the caller opts
  in. It does not mean a singleton or global input surveillance.
- **Overlay** means a native surface above other applications, not SwiftUI's
  in-view `.overlay` modifier.
- **Kit** means a reusable library rather than a standalone product.

AppKit implements the current surface with `NSPanel`, which is a specialized
window. Windows and panels are implementation primitives; they are not the
product-level abstraction or a promise that the implementation can never
change.

## Fast Reading Path

1. [README](../../README.md) - public package front door.
2. [CURRENT_STATE.md](CURRENT_STATE.md) - what exists and what remains
   unverified.
3. [ARCHITECTURE.md](ARCHITECTURE.md) - ownership boundary and consumer flows.
4. [SPEC-0001](../product/specs/SPEC-0001-global-overlay-surface-host.md) -
   approved requirements.
5. [ADR-0001](../decisions/adr/ADR-0001-keep-content-and-product-behavior-outside-the-overlay-host.md) -
   why product behavior stays outside.
6. [ROADMAP.md](ROADMAP.md) - evidence-first sequencing.
7. [Testing guide](../repo-health/testing-guide.md) - what each check proves.

## Package Flow

1. The consumer creates its own content controller. That may be an ordinary
   AppKit controller, a `SKView`-hosting controller, a Metal controller, or a
   SwiftUI view through the convenience initializer.
2. The consumer chooses surface configuration such as frame, pointer
   interaction, movement, resizing, and Space/full-screen collection behavior.
3. `GlobalOverlay` creates one private `NSPanel`, installs the content, and
   applies the requested AppKit properties.
4. The consumer calls `show()`, `hide()`, `setFrame(_:)`, `fill(_:)`, or
   `setInteraction(_:)` as its product state changes.
5. The consumer remains responsible for content updates, input commands,
   display-change policy, persistence semantics, and recovery UI.

## Core Mental Model

```text
product coordinator
  owns messages, game state, input, persistence, cadence
        |
        v
NSViewController or SwiftUI View
  owns rendered content
        |
        v
GlobalOverlay
  owns one native overlay surface
        |
        v
private NSPanel
  current AppKit mechanism
```

The content seam is stable. Product models and renderers should not depend on
the private panel.

## Two Intended Consumers

Agent Commander is the first practical consumer. It should keep message rows,
streaming state, turn-taking, and text-to-speech policy in its own code, then
give the rendered message stack to GlobalOverlayKit.

The proposed SpriteKit desktop world is a deliberate falsification consumer.
Its app owns `SKScene`, physics, balls, characters, render cadence, and controls;
the package only hosts the `SKView`. If the package cannot support both without
renderer-specific hooks, the boundary needs revision.

## Contribution Entry Points

- Public host lifecycle: `Sources/GlobalOverlayKit/GlobalOverlay.swift`
- Configuration vocabulary: `Sources/GlobalOverlayKit/GlobalOverlayConfiguration.swift`
- Contract tests: `Tests/GlobalOverlayKitTests/GlobalOverlayTests.swift`
- Build and verification menu: `./run`
- Open-source workflow: [EXPL-0001](explainers/EXPL-0001-using-and-contributing-to-globaloverlaykit.md)

Run `./run check` before closeout. Passing it is build and contract evidence,
not proof of physical macOS window behavior.

## What Not To Trust Alone

- Do not treat intended architecture as evidence that a behavior works.
- Do not treat unit tests as proof of Spaces, full-screen, focus, or pointer
  routing.
- Do not copy implementation from prior-art packages or consumer applications.
- Do not add product-specific protocols merely because one consumer needs them.
- Do not expose the private `NSPanel` to let a caller bypass the package seam.

The boundary to remember is simple: GlobalOverlayKit owns the surface; the
consumer owns what happens inside it.
