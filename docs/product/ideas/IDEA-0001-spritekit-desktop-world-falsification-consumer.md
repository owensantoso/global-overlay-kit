---
type: idea
id: IDEA-0001
title: SpriteKit Desktop World Falsification Consumer
domain: product
status: promoted
created_at: "2026-08-09 03:50:33 JST +0900"
updated_at: "2026-08-09 23:45:00 JST +0900"
owner:
source:
  type: conversation
  link:
  notes: "Future desktop-game concept used to stress-test whether the overlay host is genuinely renderer-neutral."
areas: [AREA-OVERLAY-HOST]
related_specs: [SPEC-0001]
related_research: [RSCH-0001]
related_issues: []
related_prs: []
related_sessions:
  - 2026-08-09-project-foundation-and-overlay-boundary
linked_paths: []
promoted_to: [PLAN-0002]
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# IDEA-0001 - SpriteKit Desktop World Falsification Consumer

## Raw Thought

Turn the macOS desktop into a small game world: a controllable stick character
runs and jumps along the bottom or edge of a display while balls can be thrown,
fall under gravity, and bounce against screen boundaries. A later version might
use a pixel-art renderer.

## Why It Might Matter

This is both a product idea and an architecture test. Agent Commander's message
stack is SwiftUI and event-driven; a SpriteKit world is continuously rendered,
physics-driven, and input-sensitive. If both fit through the same
`NSViewController` content seam, GlobalOverlayKit is likely abstracting the
right layer. If the package needs game-specific lifecycle APIs, the boundary
has probably drifted.

## Possible Shape

- One fixed transparent screen-sized `GlobalOverlay` for each selected display.
- A caller-owned `NSViewController` containing one `SKView`.
- A caller-owned `SKScene`, `SKPhysicsWorld`, entities, controls, and render
  cadence.
- Screen geometry translated into the scene's coordinate system by the game.
- Characters and balls move inside the scene; the app does not animate one
  native window per object.
- Global keyboard or controller input, if needed, is a separate app-level input
  service and permission decision.

## Falsification Prototype

The smallest useful prototype should:

1. host an `SKView` through the existing `NSViewController` initializer
2. draw a character standing on the screen edge
3. run left/right, jump under gravity, throw a ball, and bounce the ball from
   scene boundaries
4. toggle the overlay between pass-through and interactive pointer modes
5. run on one display, then one surface per display
6. coexist with a separate SwiftUI message overlay
7. exercise display resize or topology change while recording what owns the
   response

## What Would Falsify The Current Boundary

- SpriteKit content cannot be hosted without exposing the private panel.
- Correct frame or coordinate behavior requires a renderer-specific package
  hook rather than caller layout.
- Multiple surfaces need identical lifecycle coordination in both the game and
  Agent Commander, demonstrating a real shared layer.
- Focus and input cannot be made safe without a renderer-neutral activation
  concept that belongs beside pointer interaction.

Performance trouble inside `SKScene` or `SKView` alone does not falsify the
overlay host; it remains renderer-owned until evidence points to panel behavior.

## Questions

- Should the first prototype use the full screen frame or visible frame?
- Is pointer interaction needed, or are controls entirely app-level?
- How should the game react to menu bar/Dock changes and display hotplug?
- Does a transparent `SKView` and panel sustain acceptable frame pacing and
  energy use?
- What external recovery surface turns the world off if input fails?

## Promotion Criteria

Promote this idea to a spec and evaluation only when someone is ready to build
the bounded prototype and record visual, physical, input, and performance
evidence. Do not add SpriteKit types to GlobalOverlayKit in anticipation.

## Promotion Receipt

Promoted to [PLAN-0002](../plans/PLAN-0002-desktop-physics-falsification-demo/PLAN-0002-desktop-physics-falsification-demo.md)
on 2026-08-09 when the project owner chose the physics overlay as the first real
consumer. The approved first slice is deliberately smaller than the full idea:
one pass-through display surface, gravity, bouncing balls, and a separate
control window. Character control, click-drag, global input, and multiple
displays remain future experiments.
