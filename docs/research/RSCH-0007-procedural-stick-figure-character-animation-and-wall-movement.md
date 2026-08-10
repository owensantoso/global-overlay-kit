---
type: research-survey
id: RSCH-0007
title: Procedural Stick Figure Character Animation And Wall Movement
domain: research
status: completed
created_at: "2026-08-10 05:36:34 JST +0900"
updated_at: "2026-08-10 06:07:00 JST +0900"
owner:
question: How should the desktop character gain a reusable animated stick-figure appearance, run, sit, wall slide, and wall jump without importing a second engine or an external asset dependency?
source:
  type: conversation
  link:
  notes:
external_sources:
  - https://developer.apple.com/documentation/spritekit/responding-to-frame-cycle-events
  - https://developer.apple.com/documentation/spritekit/getting-started-with-actions
  - https://developer.apple.com/documentation/spritekit/searching-the-world-for-physics-bodies
  - https://developer.apple.com/documentation/spritekit/working-with-inverse-kinematics
  - https://developer.apple.com/documentation/appkit/nsworkspace/accessibilitydisplayshouldreducemotion
  - https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html
  - https://opengameart.org/content/animated-stick-figure-character-2d-free-cc0
repo_findings:
  - DesktopPhysicsScene already owns frame-rate-independent horizontal control, authored jump outcomes, post-physics ground probes, and a SpriteKit player body.
  - DesktopGameInputState already has a safe global event-tap boundary but currently treats Shift as a bypass modifier and has no sit action.
agent_notes:
  - The first procedural pose renderer failed physical visual acceptance and was replaced by an authored CC0 frame set.
related_ideas: []
related_evaluations: []
related_adrs: []
related_specs: [SPEC-0002]
related_plans: [PLAN-0003]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
linked_paths:
  - Examples/DesktopPhysicsDemo/Sources/DesktopPhysicsKit
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# RSCH-0007 - Procedural Stick Figure Character Animation And Wall Movement

## Question

How should the desktop character gain a reusable animated stick-figure
appearance, run, sit, wall slide, and wall jump without importing a second
engine or an external asset dependency?

## Context

The user wants the global desktop world to feel like a small platform game:
idle/walk/run/jump/wall-slide animations, Shift-to-run, C-to-sit, wall
stickiness, and repeatable wall jumping. The current player is a single shape
with authored but visually unanimated movement.

## External Sources

- Apple places gameplay decisions in `update(_:)`, physics-derived contact
  interpretation after simulation, and final rendering afterward in the
  SpriteKit frame cycle.
- Apple supports node/action interpolation and inverse kinematics (IK), but IK
  is aimed at solving an end-effector target through joint constraints rather
  than authoring a small fixed set of readable locomotion poses.
- Apple documents physics-world ray searches as the native way to inspect
  bodies along a segment, which fits short left/right wall probes.
- AppKit exposes Reduce Motion through `NSWorkspace`; movement remains
  functional while decorative limb cycling should simplify.
- Godot's established `CharacterBody2D` vocabulary separately models floor,
  wall, and ceiling contacts and treats wall sliding as controlled character
  response rather than rigid-body friction alone. This is a useful behavior
  model even though the runtime remains SpriteKit.
- Raphael Gonçalves's OpenGameArt pack is CC0 and includes authored Idle, Walk,
  Run, Jump, Slide, and Wall Slide sequences on consistent 512-point canvases.

## Repo / Internal Findings

- The existing post-physics floor probes are the correct seam to extend with
  side probes; no new collision engine is needed.
- The current physics node also owns the visible shape. A stick figure needs a
  neutral player root whose physics body remains stable while a child renderer
  changes pose.
- Shift cannot become run by simply checking event flags: it is currently in
  the shortcut-bypass set, so Shift clears held movement. Input ownership must
  distinguish gameplay Shift from Command/Control/Option/Fn shortcuts.

## Agent Notes

State graph: `idle <-> walk <-> run`, any locomotion state -> `jump`, falling
against a wall -> `wallSlide`, wall-slide + jump -> `jump` away from the wall,
and grounded `idle <-> sit`. Movement or jump exits sit. Direction is an
orthogonal facing value so left/right poses mirror rather than duplicate.

## Options Compared

1. External sprite sheet: fastest art path, but adds asset search, licensing,
   fixed frame dimensions, and poor agent-level pose inspectability.
2. SpriteKit inverse kinematics: useful when hands/feet must reach arbitrary
   targets, but unnecessarily indirect for seven authored locomotion states.
3. Procedural vector pose renderer: initially selected for inspectability, but
   the first physical run showed visibly poor motion. Rejected for this demo.
4. Authored CC0 sprite frames: adds a small resource dependency and provenance
   requirement, but supplies the exact requested locomotion set with actual
   animation craft. Selected after the procedural visual failure.

## Findings

- Adopt SpriteKit's existing physics and frame lifecycle.
- Adapt the current controller with authored walk/run speeds, side probes,
  capped wall-slide fall speed, wall-contact grace, and a primarily vertical
  wall-jump velocity with a short steering lock.
- Keep the explicit character state resolver, but render it with selected
  authored CC0 frames. Do not add another engine, a skeletal asset pipeline, or
  a general animation framework.
- Keep collision geometry stable across animation. Sitting and limb poses are
  visual/controller states, not per-frame physics-body reshaping.

## Risks / Unknowns

- The screen edge is the guaranteed first wall; large physics objects may also
  qualify when side-probe normals are sufficiently horizontal. Physical testing
  must establish whether that is understandable without a visible practice
  wall.
- Wall-slide speed, wall-jump horizontal push, and pose timing remain
  subjective until tested in the signed app.
- Reduce Motion should preserve character state and movement while suppressing
  repeated limb cycling; this needs a physical accessibility check later.

## Recommendation

Implement the state/controller extension inside `DesktopPhysicsKit` and map its
states to selected authored CC0 frames. Default new players to Stick Figure
while retaining the geometric appearances. Use W/Up/Space to jump, Shift to
run, and C as a sit/stand toggle; any movement or jump input stands the
character up. Keep player restitution at zero and tune wall jumps primarily
upward with only a modest horizontal push.

## Follow-Ups

- Add focused input, state-resolution, run-speed, wall-slide, and wall-jump
  tests before physical tuning.
- If the invisible screen edge is insufficient for testing, add one explicit
  practice-wall entity as a separate follow-up rather than inventing a level
  editor now.
