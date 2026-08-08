---
type: adr
id: ADR-0001
title: Keep Content and Product Behavior Outside the Overlay Host
domain: architecture
status: accepted
created_at: "2026-08-09 03:50:31 JST +0900"
updated_at: "2026-08-09 03:56:00 JST +0900"
areas: [AREA-OVERLAY-HOST]
deciders:
  - project owner
  - Codex
related_specs: [SPEC-0001]
related_plans: [PLAN-0001]
related_briefs: [IMPL-0001-01]
related_sessions:
  - 2026-08-09-project-foundation-and-overlay-boundary
related_issues: []
related_prs: []
supersedes: []
superseded_by: []
linked_paths:
  - Sources/GlobalOverlayKit/GlobalOverlay.swift
  - Sources/GlobalOverlayKit/GlobalOverlayConfiguration.swift
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# ADR-0001 - Keep Content and Product Behavior Outside the Overlay Host

## Context

The first motivating use is Agent Commander's streaming message overlay, but a
future desktop game may host a live SpriteKit world over the same macOS desktop.
Those consumers share transparent cross-application surface mechanics and
almost nothing about their content lifecycle.

If the package abstracts “an overlay” at the product level, it risks owning
messages, transitions, input, render cadence, scenes, or physics. That would
make the first consumer convenient and the second consumer awkward. If the
package exposes only raw `NSWindow`, every consumer must rebuild the subtle
surface mechanics and the package adds no useful seam.

The public name is GlobalOverlayKit because the reusable capability is an
overlay surface. `NSWindow` and `NSPanel` are AppKit mechanisms beneath that
capability.

## Decision

- GlobalOverlayKit owns one native surface per `GlobalOverlay` instance.
- The canonical content seam is a caller-supplied `NSViewController`.
- The package supplies a generic SwiftUI convenience initializer through
  `NSHostingController`.
- The current private mechanism is `NSPanel`; callers do not receive the panel.
- Surface configuration may cover window mechanics such as frame, pointer hit
  testing, movement, resizing, collection behavior, shadow, and accessibility
  label.
- Consumers own all rendered content, domain state, update cadence, physics,
  speech, input commands, persistence, and multi-surface policy.
- The implementation is clean-room from public Apple APIs. Prior-art and donor
  applications may inform requirements, but their code is not copied.

## Interface Candidates

### Candidate A: One renderer-neutral surface host

```text
GlobalOverlay(configuration, NSViewController)
  show / hide
  setInteraction
  setFrame / fill screen

SwiftUI convenience -> NSHostingController -> same initializer
```

Strengths:

- hides real AppKit surface complexity
- accepts AppKit, SwiftUI, SpriteKit, and Metal content
- keeps call sites small and lifecycle visible
- lets tests inspect a focused host contract
- does not invent a renderer or product protocol

Costs:

- each consumer coordinates multiple overlays and display changes itself
- the API does not provide message-level or scene-level convenience
- some physical macOS behavior still needs consumer-level validation

### Candidate B: General overlay engine and coordinator

```text
OverlayManager
  register OverlayContent protocol
  route input
  schedule updates
  coordinate screens and surfaces
  persist placement
```

Strengths:

- could centralize future fleets, transitions, and policies
- might reduce code if multiple consumers eventually share identical behavior

Costs:

- invents lifecycle and renderer protocols before consumers prove them
- risks conflating pointer routing, activation, global keyboard input, and
  product commands
- pulls message and game cadence toward one false abstraction
- makes SpriteKit/Metal integration adapt to a package-owned engine
- creates more API compatibility surface before a first release

## Consequences

Positive:

- Agent Commander can reuse native surface mechanics while keeping its message
  model and turn-taking independent.
- A desktop world can provide a controller containing `SKView` and keep all
  scene/physics behavior in the game.
- `NSPanel` can change behind the public seam.
- The package can remain one small module until shared policy is demonstrated.

Negative or deferred:

- consumers repeat some display-change and multi-overlay coordination
- interactive recovery UX remains an application concern
- no generic transition, persistence, renderer, or input system is provided
- future evidence may require an additive renderer-neutral correction or a
  superseding ADR

## Alternatives Considered

### Extract Agent Commander's message overlay wholesale

Rejected because message rows, streaming state, chat layout, and speech policy
are product-specific. It would also violate the clean-room provenance rule.

### Publish a SwiftUI-only view modifier

Rejected because SpriteKit, Metal, and AppKit callers would become second-class
or require a parallel API. SwiftUI remains a useful convenience, not the core.

### Expose an `NSPanel` factory

Rejected because callers would configure around the package and depend on its
private mechanism. A host with lifecycle operations hides enough complexity to
form a real seam.

### One package per renderer

Rejected for now. A core package plus SwiftUI/SpriteKit packages would multiply
targets without isolating a proven independent responsibility. Revisit only if
dependencies or release cadence create a real split.

## Guardrails

- Do not add message, speech, agent, scene, entity, physics, or render-loop
  types to GlobalOverlayKit.
- Do not add a multi-overlay manager until at least two consumers demonstrate
  the same coordination policy.
- Do not treat pointer interaction as application activation or global keyboard
  capture.
- Do not expose the private panel for convenience.
- Do not copy code from prior-art projects or local consumer applications.
- When an independent consumer cannot fit, first falsify the content seam with a
  minimal prototype. Change the package only for renderer-neutral evidence.

Candidate A is the accepted boundary. Candidate B remains a possible future
layer, not part of GlobalOverlayKit's current promise.
