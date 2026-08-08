---
type: spec
id: SPEC-0001
title: Global Overlay Surface Host
spec_type: architecture
domain: product
status: approved
created_at: "2026-08-09 03:50:31 JST +0900"
updated_at: "2026-08-09 03:56:00 JST +0900"
owner:
source:
  type: conversation
  link:
  notes: "Approved while separating the reusable overlay substrate from Agent Commander and Live Text Chat presentation code."
areas: [AREA-OVERLAY-HOST]
related_plans: [PLAN-0001]
related_issues: []
related_prs: []
related_adrs: [ADR-0001]
related_sessions:
  - 2026-08-09-project-foundation-and-overlay-boundary
supersedes: []
superseded_by: []
linked_paths:
  - Sources/GlobalOverlayKit/GlobalOverlay.swift
  - Sources/GlobalOverlayKit/GlobalOverlayConfiguration.swift
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# SPEC-0001 - Global Overlay Surface Host

## Summary

Provide a small macOS Swift package that hosts arbitrary native content in a
transparent, cross-application overlay surface. The package owns AppKit surface
mechanics and a SwiftUI convenience path; the consuming application owns every
content and product concern.

## Problem And Opportunity

- Multiple applications may need always-available desktop content without
  rebuilding `NSPanel` behavior each time.
- Agent Commander needs an ambient streaming-message presentation, but its
  message model and speech/agent policies should not become library concepts.
- A future SpriteKit desktop world needs the same surface mechanics with a
  completely different renderer, state model, and input loop.
- Existing packages reviewed provide useful adjacent solutions but not the full
  renderer-neutral macOS boundary required here.

## Goals

- Host arbitrary AppKit content above other applications.
- Preserve a non-activating presentation mechanism and optional pointer
  pass-through.
- Provide explicit configuration for the small set of native mechanics required
  by the initial consumers.
- Make SwiftUI convenient without making it canonical.
- Support fixed frames and a caller-selected screen frame.
- Keep the package clean-room, independently implemented from public Apple APIs.
- Establish tests and evidence language that do not confuse configuration with
  observed physical behavior.

## Non-Goals

- Chat, transcript, message, agent, speech, or notification models.
- Game scenes, physics, animation, render loops, or a pixel engine.
- Global keyboard capture, hotkeys, voice commands, or Accessibility permission
  handling.
- A package-owned overlay fleet, display registry, or topology monitor.
- Product persistence, activation policy, or recovery user interface.
- Circumventing macOS security, privacy, secure surfaces, or application
  boundaries.

## Users And Actors

- AppKit applications supplying an `NSViewController`.
- SwiftUI applications using the convenience initializer.
- Agent Commander as the first message consumer.
- A future SpriteKit desktop-world prototype as an independent falsification
  consumer.
- Maintainers evaluating API changes and evidence.

## Current Behavior And Context

The initial implementation provides a public main-actor `GlobalOverlay`, public
configuration and interaction types, a private `NSPanel`, arbitrary
`NSViewController` hosting, and a generic SwiftUI convenience initializer.
Focused tests inspect panel configuration and mutable frame/interaction
operations. Physical behavior and external consumer integration remain
unverified.

## Requirements

### Host lifecycle

- One `GlobalOverlay` instance must own exactly one native overlay surface.
- The core initializer must accept a caller-provided `NSViewController`.
- The package must keep the native panel private.
- Callers must be able to show and hide the surface without requiring a product
  model inside the package.
- Public surface lifecycle must remain main-actor isolated.

### Surface configuration

- Initial configuration must accept a frame and minimum size.
- Pointer handling must explicitly distinguish pass-through and interactive
  modes.
- Movement, resizing, all-Spaces, full-screen auxiliary, shadow, accessibility
  label, and optional AppKit frame-autosave settings must be independently
  expressible.
- Callers must be able to update interaction and frame without recreating the
  surface.
- A caller may fill one chosen screen using its full or visible frame.
- Screen filling must not imply automatic observation of future display
  topology changes.

### Renderer neutrality

- SwiftUI support must delegate to the same AppKit content seam through
  `NSHostingController`.
- AppKit, SpriteKit, and Metal content must fit without package-owned renderer
  lifecycle protocols.
- The package must not call, schedule, or persist renderer state.

### Ownership and provenance

- The consumer must own content, state, cadence, product input, persistence,
  display policy, and multi-overlay coordination.
- Implementation must be written clean-room from public Apple APIs.
- Prior-art projects may be cited and compared, but their code must not be
  copied into this package.
- Third-party code may be added later only through an explicit dependency and
  license/provenance review; none is required for the initial host.

### Safety and recovery

- “Global” must mean cross-application presentation, not global authority or a
  bypass of macOS restrictions.
- Pointer interaction, activation, key focus, and global input must remain
  separate concepts.
- Consumers that expose interactive controls must provide an external,
  keyboard-reachable recovery path.

## Architecture Notes

The accepted boundary is recorded in
[ADR-0001](../../decisions/adr/ADR-0001-keep-content-and-product-behavior-outside-the-overlay-host.md)
and owned by
[AREA-OVERLAY-HOST](../../architecture/areas/AREA-OVERLAY-HOST.md).

`GlobalOverlay` is the public abstraction because consumers request an overlay
surface. `NSPanel` is the current macOS primitive used to implement it. Public
naming should not force callers to understand or retain the private primitive.

## Open Questions

- Which physical behavior differs across supported macOS versions and display
  configurations?
- Does a second real consumer need automatic display-topology tracking, or is
  caller coordination clearer?
- What activation/focus behavior is required for genuinely interactive
  controls without broadening into global input?
- What minimum API stability and example coverage are required before the first
  tagged release?

These questions must be answered by experiments or consumers, not speculative
configuration fields.

## Test And Validation Expectations

Automated:

- package build
- panel property mapping from configuration
- pointer-mode updates
- frame updates
- structured-doc and link checks

Physical before release-quality claims:

- focus preservation and activation behavior
- click-through and interactive pointer routing
- Space and full-screen transitions
- one and multiple displays, including topology changes
- movement, resizing, autosave/restore, and screen filling
- accessibility/recovery behavior
- sustained SwiftUI and SpriteKit rendering performance

Record each evidence class separately. An automated property assertion must not
be presented as physical proof.

## Paper Trail

| Type | Link | Role |
|---|---|---|
| Research | [RSCH-0001](../../research/RSCH-0001-global-overlay-prior-art-and-package-boundary.md) | Adjacent packages and bounded gap analysis |
| ADR | [ADR-0001](../../decisions/adr/ADR-0001-keep-content-and-product-behavior-outside-the-overlay-host.md) | Durable ownership boundary |
| Plan | [PLAN-0001](../plans/PLAN-0001-clean-room-overlay-host-mvp/PLAN-0001-clean-room-overlay-host-mvp.md) | Initial implementation and closeout |
| Idea | [IDEA-0001](../ideas/IDEA-0001-spritekit-desktop-world-falsification-consumer.md) | Independent falsification consumer |
| Session | [Project foundation](../../repo-health/session-logs/2026-08-09-project-foundation-and-overlay-boundary.md) | Initial research/docs receipt |
