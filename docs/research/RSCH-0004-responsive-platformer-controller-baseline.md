---
type: research-survey
id: RSCH-0004
title: Responsive Platformer Controller Baseline
domain: research
status: completed
created_at: "2026-08-10 01:13:19 JST +0900"
updated_at: "2026-08-10 01:13:19 JST +0900"
owner:
question: Which established controller model gives the SpriteKit player a measurable responsive baseline without inventing a new physics engine?
source:
  type: conversation
  link:
  notes:
external_sources:
  - https://developer.apple.com/documentation/appkit/nsevent/modifierflags-swift.struct/function
  - https://developer.apple.com/documentation/spritekit/skphysicsworld/enumeratebodies(alongraystart:end:using:)
  - https://developer.apple.com/documentation/spritekit/responding-to-frame-cycle-events
  - https://developer.apple.com/documentation/spritekit/making-physics-bodies-move
  - https://www.gdcvault.com/play/1023148/Math-for-Game-Programmers-Building
  - https://docs.godotengine.org/en/latest/tutorials/physics/using_character_body_2d.html
repo_findings:
  - Arrow events were bypassed because the Function flag was treated as a user shortcut modifier even though macOS marks navigation keys with it.
  - One-frame jump requests and contact-flickering caused valid presses to be rejected.
  - The old jump rose only about 56 points over roughly 1.2 seconds to apex.
agent_notes:
  - Derive gravity and velocity from visible jump height and apex time; do not tune unrelated constants independently.
related_ideas: []
related_evaluations: []
related_adrs: [ADR-0002]
related_specs: [SPEC-0002]
related_plans: [PLAN-0003]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
linked_paths:
  - Examples/DesktopPhysicsDemo/Sources/DesktopPhysicsKit/DesktopGameInput.swift
  - Examples/DesktopPhysicsDemo/Sources/DesktopPhysicsKit/DesktopPhysicsScene.swift
  - Examples/DesktopPhysicsDemo/Sources/DesktopPhysicsKit/DesktopPhysicsTypes.swift
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# RSCH-0004 - Responsive Platformer Controller Baseline

## Question

Which established controller model gives the SpriteKit player a responsive,
measurable baseline without replacing SpriteKit's collision engine?

## Context

The first signed-app acceptance run found partial A/D movement, no arrow
movement, and absent or imperceptible jumping despite passing pure input-state
tests.

## External Sources

- Apple documents that navigation keys carry the [Function modifier](https://developer.apple.com/documentation/appkit/nsevent/modifierflags-swift.struct/function).
- SpriteKit provides [physics ray queries](https://developer.apple.com/documentation/spritekit/skphysicsworld/enumeratebodies(alongraystart:end:using:))
  and a distinct [post-physics frame callback](https://developer.apple.com/documentation/spritekit/responding-to-frame-cycle-events).
- Apple supports direct velocity, force, and impulse policies for
  [moving physics bodies](https://developer.apple.com/documentation/spritekit/making-physics-bodies-move).
- Kyle Pittman's [Building a Better Jump](https://www.gdcvault.com/play/1023148/Math-for-Game-Programmers-Building)
  derives gravity and initial velocity from authored jump height and apex time.
- Godot's [CharacterBody2D guidance](https://docs.godotengine.org/en/latest/tutorials/physics/using_character_body_2d.html)
  is a useful semantic reference for floor normals and controlled avatars.

## Repo / Internal Findings

- `.maskSecondaryFn` was in the bypass set. Ordinary arrow events therefore
  passed to the frontmost app instead of entering gameplay.
- `pendingJump` was cleared every rendered frame even when no grounded jump was
  admitted. A press just before landing or during one flickering contact frame
  was permanently lost.
- Edge-loop contact tracking keyed the entire floor/walls/ceiling by one scene
  node, making grounded state unstable.
- `dy = 95` against about `79.8 pt/s²` total gravity yields only about 56.5
  points of rise and a 1.19-second ascent: mathematically small and floaty.
- Player friction and damping competed with explicitly controlled horizontal
  velocity.

## Agent Notes

## Options Compared

1. Increase the impulse only: rejected because it does not repair delivery,
   buffering, or grounding.
2. Continue contact-set grounding: rejected because edge-loop identity and
   begin/end timing remain fragile.
3. Use a small controller profile over SpriteKit: selected.
4. Adopt a full side-scroller engine: deferred as disproportionate.

## Findings

The reusable unit is a designer-facing controller profile, not another engine.
The initial profile uses 520 pt/s run speed, 180-point maximum jump height,
0.36-second apex time, 70-point tap height, 0.10-second coyote time, and
0.12-second jump buffering. Gravity and jump velocity are derived.

Grounding uses two short post-physics ray probes and a floor-normal threshold.
The avatar owns horizontal velocity/acceleration; loose objects continue using
ordinary SpriteKit forces and collision response.

## Risks / Unknowns

- SpriteKit does not expose a deterministic manual physics-step API.
- The starting profile is evidence-based but still requires a subjective
  physical verdict on this display and player scale.
- Runtime measurements at 30/60/120 Hz remain future validation.

## Recommendation

Adopt SpriteKit for rendering, collision response, and ray queries. Keep a
small local `DesktopPlatformerControllerProfile` with measurable authored
outcomes, buffered inputs, coyote time, variable-height release, asymmetric
fall gravity, and explicit horizontal acceleration.

## Follow-Ups

- Physically retest A/D, arrows, W/Up/Space, held versus tapped jump,
  Command-Tab, and control disable/key return.
- Expose the four most useful feel inputs only if live authoring work proves
  that a tuning surface is valuable.
