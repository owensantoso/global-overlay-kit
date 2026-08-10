---
type: adr
id: ADR-0002
title: Keep Desktop Physics Reuse Outside GlobalOverlayKit
domain: architecture
status: accepted
created_at: "2026-08-10 00:17:57 JST +0900"
updated_at: "2026-08-10 00:25:11 JST +0900"
areas: [AREA-DESKTOP-PHYSICS, AREA-OVERLAY-HOST]
deciders: [project owner, Codex]
related_specs: [SPEC-0002]
related_plans: [PLAN-0003]
related_briefs: [IMPL-0003-01]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
related_issues: []
related_prs: []
supersedes: []
superseded_by: []
linked_paths:
  - Examples/DesktopPhysicsDemo
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# ADR-0002 - Keep Desktop Physics Reuse Outside GlobalOverlayKit

## Context

The first SpriteKit consumer proved GlobalOverlayKit can host a continuously
rendered physics scene. The project owner now expects to reuse desktop physics
across multiple experiments and does not want each caller to understand AppKit,
SpriteKit scene setup, physics-body construction, cursor mapping, and selective
input capture.

Putting these conveniences into GlobalOverlayKit would violate `ADR-0001` and
make a renderer-neutral surface package own game/product behavior. Leaving them
inside one executable would invite copy/paste. A new public repository could be
correct eventually, but the first API has only one consumer and current prior
art still needs review.

## Decision

Accepted after `RSCH-0002` found no exact reusable match:

- Keep GlobalOverlayKit renderer-neutral and free of SpriteKit/game types.
- Create a separate `DesktopPhysicsKit` library product in the nested consumer
  package.
- Let that product adapt GlobalOverlayKit plus SpriteKit into one desktop-world
  command API.
- Keep demo views and product presentation outside the library.
- Do not tag or extract the library into its own repository until prior-art
  review and at least one additional use validate the contract.
- Prefer domain commands (`spawn`, `show`, `setCursorCollisionEnabled`,
  `setControlsEnabled`) over exposing scene construction steps.

## Consequences

Positive:

- Future local experiments can depend on one product instead of copying setup.
- Callers do not need to know the overlay or SpriteKit construction sequence.
- GlobalOverlayKit remains suitable for Agent Commander, Metal, and other
  non-game renderers.
- The nested target can be extracted later without rewriting call sites.

Costs and risks:

- A nested package is less discoverable than a standalone repository.
- One consumer may still produce the wrong public vocabulary or ownership.
- Cursor/input policy introduces macOS permissions and recovery obligations.
- The repository now contains a reusable consumer layer as well as the core
  package, so docs must keep their promises distinct.

## Alternatives Considered

### Add physics conveniences to GlobalOverlayKit

Rejected because it couples the generic overlay surface to SpriteKit and breaks
the accepted content boundary.

### Keep everything inside the executable target

Rejected because the owner has an explicit repeat-use need and the current
classes force future callers to copy framework setup.

### Create a standalone public repository immediately

Deferred. It may be the right release shape after prior-art review and a second
consumer, but doing it now would freeze naming and API before evidence.

### Build a new engine

Rejected. SpriteKit already provides simulation, contacts, bodies, rendering,
and cadence. The custom gap is desktop-overlay adaptation and safe controls.

## Guardrails

- Do not import SpriteKit from `Sources/GlobalOverlayKit`.
- Do not expose `NSPanel` or make callers coordinate internal setup steps.
- Do not create ECS, level, asset, renderer, or general input abstractions
  without a second concrete need.
- Preserve Command-modified shortcuts and an external visible recovery route.
- Teardown every global input resource when controls disable or the world dies.
- Revisit standalone publication only after a second real consumer.
