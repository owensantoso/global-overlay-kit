---
type: research-survey
id: RSCH-0002
title: Desktop Physics Overlay Prior Art
domain: research
status: completed
created_at: "2026-08-10 00:18:16 JST +0900"
updated_at: "2026-08-10 00:25:11 JST +0900"
owner:
question: Does a reusable macOS package already combine global transparent overlays with a desktop physics world, cursor interaction, and controllable characters?
source:
  type: conversation
  link:
  notes:
external_sources:
  - https://store.steampowered.com/app/4933570/Screen_Pet_Engine/
  - https://github.com/InsiderX-Pro/desktop-pet-engine
  - https://github.com/euuuuuuan/todak-public
  - https://github.com/pixelomer/libshijima
  - https://www.hammerspoon.org/docs/hs.canvas.html
  - https://github.com/InvadingOctopus/octopuskit
  - https://developer.apple.com/documentation/spritekit
repo_findings:
  - No exact reusable package found in targeted repository and code searches.
  - SpriteKit and GlobalOverlayKit cover the foundations; desktop-world adaptation remains the gap.
agent_notes:
  - Evidence of absence is not proof of nonexistence.
related_ideas: []
related_evaluations: []
related_adrs: [ADR-0002]
related_specs: [SPEC-0002]
related_plans: [PLAN-0003]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
linked_paths: []
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# RSCH-0002 - Desktop Physics Overlay Prior Art

## Question

Does a maintained reusable macOS library already provide the important
combination: transparent cross-application/all-Spaces overlay surface,
SpriteKit or equivalent 2D physics world, desktop objects/characters, cursor
interaction, and safe controls?

## Context

The project already has GlobalOverlayKit plus a working SpriteKit ball demo.
The project owner wants broad reuse but explicitly does not want to recreate an
existing open-source solution. Exact matches must be distinguished from desktop
pets, overlay-window helpers, game engines, screensavers, and one-off demos.

## External Sources

| Candidate | Coverage | License / maturity | Reuse implication |
|---|---|---|---|
| [Screen Pet Engine](https://store.steampowered.com/app/4933570/Screen_Pet_Engine/) | Closest end-user product: macOS pets, gravity after dragging, desktop movement, props, click-through focus mode | Commercial and coming soon; no source or SDK found | UX benchmark only |
| [Desktop Pet Engine for macOS](https://github.com/InsiderX-Pro/desktop-pet-engine) | Transparent AppKit pet window, all Spaces/full-screen auxiliary, drag, cursor reactions, per-pixel click-through; no SpriteKit/physics/global world | Apache-2.0; created July 2026, very new; executable product only | Study alpha hit-testing and pointer routing; not a dependency replacement |
| [Todak](https://github.com/euuuuuuan/todak-public) | Transparent always-on-top Godot pet windows, picking up pets, props, recovery, behavior JSON; no general physics world | Apache-2.0 code with separately licensed assets; public snapshot is new | Adapt reset/recovery, performance budgets, and behavior/rendering separation |
| [libshijima](https://github.com/pixelomer/libshijima) / [Shijima-Qt](https://github.com/pixelomer/Shijima-Qt) | Reusable mascot simulation and platform host; scripted mascot semantics rather than rigid-body desktop world | GPL-3.0; Qt host archived in April 2026 | Conceptual separation only; license/bridge/architecture are poor fit |
| [Hammerspoon `hs.canvas`](https://www.hammerspoon.org/docs/hs.canvas.html) | Mature transparent canvases, window levels, Spaces, primitives, mouse callbacks; no SpriteKit/physics | MIT; mature and actively maintained | Useful rapid prototype/reference, not a native distributable engine dependency |
| [OctopusKit](https://github.com/InvadingOctopus/octopuskit) | Reusable Swift SpriteKit engine with physics, keyboard forces, pointer dragging, ECS; no global desktop overlay | Apache-2.0; maintainer says no longer updated | Too much abandoned engine structure for the missing seam |
| [SpriteKit](https://developer.apple.com/documentation/spritekit) | Native renderer, rigid bodies, gravity, contacts, shapes, joints | Apple platform framework | Adopt as the actual engine |
| [GlobalOverlayKit](https://github.com/owensantoso/global-overlay-kit) | Native arbitrary content, transparent cross-app surface, Spaces and pointer policy | MIT; current project | Keep renderer-neutral as the host foundation |

## Repo / Internal Findings

- GlobalOverlayKit already owns the renderer-neutral macOS surface.
- SpriteKit already owns the physics engine.
- The uncovered gap is a reusable adapter for desktop-world lifecycle, object
  construction, cursor mapping, and safe selective controls.
- Targeted repository/code searches found no indexed Swift matches combining
  `SKPhysicsWorld` or `SKScene` with all-Spaces/full-screen overlay mechanics.

## Agent Notes

No exact match was found as of 2026-08-10. This is evidence of absence, not
proof that no private, unindexed, or newly published project exists.

## Options Compared

1. Adopt an exact library: unavailable in the reviewed set.
2. Adapt a desktop-pet engine: closest products have app-specific semantics and
   omit either reusable packaging or a general physics world.
3. Adopt SpriteKit plus GlobalOverlayKit and build the thin missing adapter.
4. Adopt a full SpriteKit engine such as OctopusKit: disproportionate and stale.

## Findings

- The visual/product idea exists in desktop-pet software, so the experience is
  not novel in the absolute sense.
- The requested reusable native package boundary was not found.
- Existing projects contribute patterns—per-pixel interaction, reset controls,
  performance budgets, behavior/rendering separation—but not the complete
  dependency.
- Custom work is justified only at the integration seam; rebuilding physics,
  rendering, or a general entity-component engine is not justified.

## Risks / Unknowns

- A project may look similar visually while exposing no reusable library.
- GPL projects cannot be casually incorporated into an MIT package.
- Very new pet repositories have weak maintenance evidence.
- Global input introduces Accessibility permission even though cursor polling
  does not.

## Recommendation

Adopt, adapt, and build:

- Adopt SpriteKit for rendering and physics.
- Keep GlobalOverlayKit responsible only for macOS surfaces and pointer policy.
- Build `DesktopPhysicsKit` as the small missing desktop-world adapter.
- Adapt Todak's recovery/performance practices and Desktop Pet Engine's
  pointer-routing ideas where independently appropriate.
- Avoid ECS, level, asset, and general engine abstractions until multiple real
  consumers require them.

## Follow-Ups

- Recheck the market before standalone publication.
- Validate the first caller API in a second local consumer before tagging.
