---
type: research-survey
id: RSCH-0001
title: Global Overlay Prior Art and Package Boundary
domain: architecture
status: completed
created_at: "2026-08-09 03:50:31 JST +0900"
updated_at: "2026-08-09 03:58:00 JST +0900"
owner:
question: "Does an existing package already provide the required general macOS overlay host, and what is the smallest reusable boundary?"
source:
  type: conversation
  link:
  notes: "Bounded review of official repositories and Apple documentation on 2026-08-09."
external_sources:
  - https://github.com/MrKai77/DynamicNotchKit
  - https://github.com/astzweig/swiftui-window-reference
  - https://github.com/sunghyun-k/swiftui-window-overlay
  - https://developer.apple.com/documentation/swiftui/utilitywindow
  - https://developer.apple.com/documentation/appkit/nswindow
  - https://developer.apple.com/documentation/appkit/nspanel
  - https://developer.apple.com/documentation/appkit/nshostingcontroller
  - https://developer.apple.com/documentation/spritekit/skview
  - https://gist.github.com/bakkiraju/bed042bb7f659fd99c748c7a32b835d5
  - https://gist.github.com/JuniperPhoton/b8e130159541803d71531c7d9320d5d3
repo_findings:
  - "The landed GlobalOverlayKit package implements one AppKit surface with an NSViewController seam and a SwiftUI convenience initializer."
  - "No external package source was copied; implementation provenance is public Apple APIs."
agent_notes:
  - "Earlier local inspection found message-overlay code coupled to consumer message rows and room state, making it a requirements source rather than a safe package extraction."
related_ideas: [IDEA-0001]
related_evaluations: []
related_adrs: [ADR-0001]
related_specs: [SPEC-0001]
related_plans: [PLAN-0001]
related_sessions:
  - 2026-08-09-project-foundation-and-overlay-boundary
linked_paths:
  - Sources/GlobalOverlayKit/GlobalOverlay.swift
  - Sources/GlobalOverlayKit/GlobalOverlayConfiguration.swift
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# RSCH-0001 - Global Overlay Prior Art And Package Boundary

## Question

Does a maintained package already provide a transparent, cross-application,
renderer-neutral macOS overlay host with useful interaction and display
mechanics, or should GlobalOverlayKit exist as a separate package?

## Scope And Method

This was a bounded search, not proof that no obscure project exists. On
2026-08-09 it reviewed the named official repositories, Apple framework
documentation, and two representative GitHub recipes. A complete fit would
need:

- macOS/AppKit rather than an in-app or iOS-only overlay
- arbitrary native content, not only one SwiftUI product presentation
- transparent, non-activating, cross-application placement
- configurable pointer pass-through/interactivity
- all-Spaces/full-screen and caller-selected frame/display primitives
- no ownership of messages, scenes, physics, render cadence, or global input

Maintenance signals below are repository snapshots from the research date and
will age.

## Prior Art

| Candidate | What the official source provides | Gap against this project | License / maintenance signal |
|---|---|---|---|
| [DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit) | macOS 13+ Swift package for SwiftUI content in a notch/Dynamic Island presentation; owns custom window and safe-area mechanics | Strong adjacent proof, but its public product is notch-specific and SwiftUI-oriented rather than a general arbitrary `NSViewController` surface | MIT; 151-commit repository and [1.1.0 release](https://github.com/MrKai77/DynamicNotchKit/releases/tag/1.1.0) published 2026-04-05 indicate current maintenance |
| [WindowReference](https://github.com/astzweig/swiftui-window-reference) | Retrieves an existing SwiftUI scene's `NSWindow` and places it in the environment | Useful interop seam, but does not create or manage a cross-application overlay | EUPL-1.2; three commits, with the [latest listed commit](https://github.com/astzweig/swiftui-window-reference/commit/1814226af8d3cd215310d845be6abab925dd1b76) on 2024-07-11 and no GitHub release |
| [swiftui-window-overlay](https://github.com/sunghyun-k/swiftui-window-overlay) | SwiftUI modifier that adds an overlay window above an application's window | Official README targets iOS 13+ and UIKit, not macOS/AppKit or global desktop presentation | MIT; seven commits and [1.0.2 release](https://github.com/sunghyun-k/swiftui-window-overlay/releases/tag/1.0.2) on 2025-03-25 |
| [SwiftUI `UtilityWindow`](https://developer.apple.com/documentation/swiftui/utilitywindow) | First-party macOS 15+ floating utility scene with focus-aware palette behavior | Designed for secondary app utilities and hides when the app is inactive; not a persistent cross-application overlay substrate | Apple SDK API; maintained with macOS, not an independently licensed package |
| [2017 transparent-window recipe](https://gist.github.com/bakkiraju/bed042bb7f659fd99c748c7a32b835d5) | Small AppKit example setting opacity, window level, collection behavior, and click-through | A recipe without a package API, lifecycle, tests, arbitrary content boundary, or explicit license | Single older gist; no dependency-quality maintenance signal |
| [2025 floating-overlay recipe](https://gist.github.com/JuniperPhoton/b8e130159541803d71531c7d9320d5d3) | SwiftUI/AppKit example for a borderless resizable window, full-screen auxiliary behavior, and a hotkey | Useful mechanism sketch, but not a library and it mixes app/hotkey decisions with surface setup | Gist active in March 2025; no explicit license shown |

## Apple Framework Findings

Apple's [`NSWindow`](https://developer.apple.com/documentation/appkit/nswindow)
and [`NSPanel`](https://developer.apple.com/documentation/appkit/nspanel) are the
native primitives for the surface. [`NSHostingController`](https://developer.apple.com/documentation/appkit/nshostingcontroller)
bridges SwiftUI content into the AppKit controller seam. [`SKView`](https://developer.apple.com/documentation/spritekit/skview)
is itself an AppKit view, so a consumer can host SpriteKit without a
SpriteKit-specific package API.

These first-party seams support a clean-room implementation. They do not remove
the need to physically validate focus, Spaces, full-screen, mouse routing, and
multiple displays.

## Package Boundary Options

### Agent Commander internal module

This is the smallest change for the first consumer, but it makes the future
SpriteKit consumer either depend on Agent Commander or duplicate the window
mechanics. It also encourages message assumptions to leak into the host.

### Shared local Swift package

A separate package with one AppKit host and a SwiftUI convenience initializer
creates the actual shared seam. Both consumers remain responsible for their
renderers and behavior. The package can be consumed locally or by a branch
before it makes a public stability promise.

### Separately published open-source package

The same shared package can be public from the start for provenance and
collaboration, while delaying a tagged semantic-version release until consumer
and physical evidence exist. Publishing source does not require pretending the
API is mature.

### Multiple core/renderer/coordinator packages

Rejected for now. SwiftUI adds no third-party dependency and is a thin adapter.
There is no proven multi-overlay coordinator or renderer interface worth a
separate target.

## Findings

- The reviewed projects solve real adjacent problems; none is a complete
  general drop-in for the defined macOS boundary.
- The reusable part is smaller than a chat overlay and smaller than a desktop
  game engine: native surface creation plus arbitrary content hosting.
- `NSViewController` is the smallest seam that naturally accepts AppKit,
  SwiftUI through `NSHostingController`, SpriteKit through `SKView`, and Metal
  through `MTKView`.
- Pointer click-through, application activation, key focus, and global keyboard
  capture must remain separate.
- Multiple surfaces should be multiple instances. Shared fleet/display policy
  needs evidence from at least two consumers before entering the package.

## Licensing And Provenance

GlobalOverlayKit is implemented clean-room from public Apple APIs. The projects
above are comparison evidence, not code donors. Do not paste from a repository
or gist merely because it is visible; license compatibility, attribution, and a
deliberate dependency/provenance decision are required. Recipes without an
explicit license are especially unsuitable as donor code.

## Risks And Unknowns

- The bounded search could have missed a smaller or newly released package.
- Repository activity is only a maintenance signal, not a quality guarantee.
- AppKit property configuration may not produce identical behavior across macOS
  versions, Spaces, full-screen apps, and display topologies.
- A real interactive consumer may reveal a renderer-neutral focus/activation
  requirement that the initial API does not model.

## Recommendation

Use one separately housed GlobalOverlayKit Swift package now, with one public
AppKit surface host and one SwiftUI convenience path. Keep source open and
clean-room, but treat the branch API as pre-release. Do not split into multiple
packages or add a coordinator until Agent Commander and the SpriteKit
falsification prototype prove shared requirements.

## Follow-Ups

- Integrate the message renderer as the first physical consumer.
- Promote [IDEA-0001](../product/ideas/IDEA-0001-spritekit-desktop-world-falsification-consumer.md)
  only when the bounded prototype is ready.
- Re-run the package landscape search before a first tagged release because
  prior art and maintenance status may change.
