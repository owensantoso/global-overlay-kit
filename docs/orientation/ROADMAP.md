---
type: roadmap
title: Roadmap
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

# Roadmap

GlobalOverlayKit should grow through consumer evidence, not imagined framework
flexibility. The next phase is to prove the narrow host in a real message
overlay before adding coordination or renderer-specific capability.

## Status Legend

- **Implemented** - source exists and has focused automated coverage.
- **Needs physical evidence** - mechanism exists but has not been observed.
- **Not started** - no package or consumer implementation exists.
- **Captured** - preserved as an idea, not approved work.

## Roadmap Snapshot

| Band | Status | Why it sits here |
|---|---|---|
| Clean-room package foundation | Implemented; automated closeout pending | Establishes the smallest reusable seam |
| Agent Commander consumer | Not started | Proves the actual message-overlay need |
| SpriteKit falsification consumer | Captured | Tests renderer neutrality with radically different content |
| Public release hardening | Not started | Should follow real consumer and physical evidence |

## 1. Package Foundation

[PLAN-0001](../product/plans/PLAN-0001-clean-room-overlay-host-mvp/PLAN-0001-clean-room-overlay-host-mvp.md)
owns the initial host:

- arbitrary `NSViewController` content
- SwiftUI convenience
- transparent non-activating panel mechanics
- pass-through and pointer-interactive modes
- all-Spaces/full-screen configuration
- frame and selected-screen placement
- focused contract tests and continuity docs

The source is present. Closeout requires the documented automated baseline; it
does not turn unobserved physical behavior into evidence.

## 2. First Real Consumer: Agent Commander

Build a tiny integration in Agent Commander that:

1. renders its own streaming message stack through the SwiftUI convenience
   initializer
2. switches between pass-through and interactive pointer modes
3. keeps turn-taking, speech, agent state, message rows, and controls outside
   this package
4. provides a visible recovery route outside the overlay
5. records physical results for focus, Spaces, full-screen, pointer routing,
   drag/resize if used, and display placement

This consumer should identify concrete API friction before the package adds
more policy.

## 3. Independent Falsification Consumer

Use [IDEA-0001](../product/ideas/IDEA-0001-spritekit-desktop-world-falsification-consumer.md)
to prototype one screen-sized `SKView` with a controllable character, gravity,
and bouncing balls.

The prototype succeeds when GlobalOverlayKit remains unchanged or needs only a
small renderer-neutral correction. A demand for message, game, scene, or tick
APIs falsifies the current abstraction.

## 4. Evidence-Driven Hardening

Only after the consumers above:

- decide whether automatic display-topology tracking is truly shared
- test one and multiple overlays on one and multiple displays
- test focus/activation and recovery behavior with real controls
- add accessibility and performance evidence appropriate to actual consumers
- settle minimum platform support from observed compatibility needs
- tag a semantic version and replace branch-based installation instructions
  with a released version range

## 5. Explicit Backlog

Do not pull these forward without evidence from two consumers:

- an overlay fleet or screen coordinator
- a renderer protocol or scene abstraction
- built-in animation/transition systems
- global hotkeys, keyboard capture, or Accessibility permission handling
- message, speech, game, physics, or persistence models

The sequencing principle is: prove the surface twice, then abstract only the
policy both consumers actually share.
