---
type: session-log
title: Desktop Physics Falsification Demo
domain: repo-health
status: completed
created_at: "2026-08-09 23:45:00 JST +0900"
updated_at: "2026-08-10 00:05:00 JST +0900"
started_at: "2026-08-09 23:35:00 JST +0900"
ended_at: "2026-08-10 00:05:00 JST +0900"
timezone: "JST +0900"
participants: [Owen, Codex]
areas: [AREA-OVERLAY-HOST]
related_plans: [PLAN-0002]
related_briefs: [IMPL-0002-01]
related_specs: [SPEC-0001]
related_adrs: [ADR-0001]
related_todos: []
related_issues: []
related_prs: []
commits: []
---

# 2026-08-09 - Desktop Physics Falsification Demo

## Session metadata

- Started: 2026-08-09 23:35:00 JST +0900
- Ended: 2026-08-10 00:05:00 JST +0900
- Timezone: JST +0900
- Participants: Owen, Codex
- Todo-backed work: none

## Goal

- Determine whether GlobalOverlayKit is ready for a real consumer and, if so,
  build the smallest visible desktop-physics proof.

## Timeline

- 2026-08-09 23:35:00 JST +0900 - Rechecked the clean root package, public
  renderer-neutral seam, passing prior CI baseline, and unverified physical
  behavior.
- 2026-08-09 23:45:00 JST +0900 - Promoted the SpriteKit idea and chose a
  one-display pass-through ball demo with a separate recovery window.
- 2026-08-09 23:48:00 JST +0900 - First physical run failed: controls counted
  spawned balls but no balls were visible.
- 2026-08-09 23:50:00 JST +0900 - Runtime diagnostics showed the panel, view,
  and scene were all 0x0. A failing unit assertion independently showed AppKit
  overriding configured panel geometry with the controller view's size.
- 2026-08-09 23:51:00 JST +0900 - Reapplied the host-owned frame after content
  controller installation; the regression test and full baseline passed.
- 2026-08-09 23:54:00 JST +0900 - Clean run visibly rendered multiple colored
  balls above other app content. Acceptance was dismissed without an explicit
  click-through/controls verdict.
- 2026-08-09 23:58:00 JST +0900 - Project owner reported the initial gravity
  felt too fast and balls jittered at the floor, and asked for position-over-time
  diagnostics.
- 2026-08-10 00:00:00 JST +0900 - Bounded trajectory samples showed the first
  ball reaching about -8265 vertical velocity and repeatedly reversing near the
  floor without settling. The local SpriteKit header confirmed gravity uses
  meters per second squared and Earth gravity is `-9.8`, not `-980`.
- 2026-08-10 00:02:00 JST +0900 - With `-9.8` gravity and `0.48` restitution, a
  clean single-ball trace settled at y=25.3 with zero vertical velocity. Added
  opt-in `./run demo-trace` and relaunched the quiet tuned build.

## Context read

- `docs/orientation/CURRENT_STATE.md`
- `docs/orientation/ROADMAP.md`
- `docs/product/ideas/IDEA-0001-spritekit-desktop-world-falsification-consumer.md`
- `docs/product/specs/SPEC-0001-global-overlay-surface-host.md`
- `docs/decisions/adr/ADR-0001-keep-content-and-product-behavior-outside-the-overlay-host.md`

## Changes

- Promoted `IDEA-0001` to `PLAN-0002` and bounded its first implementation
  brief.
- Product/code/docs areas touched: `AREA-OVERLAY-HOST`, root host construction,
  root contract tests, nested SpriteKit example, run command, and continuity
  docs.
- Commits produced: none; work remains local and uncommitted.
- Most relevant paths: `Examples/DesktopPhysicsDemo`, `run`, `PLAN-0002`.

## Decisions

- Decision: use SpriteKit's built-in physics rather than create a physics
  engine.
  - Why: the desired outcome is a convincing desktop-world interaction proof,
    and macOS already provides the required gravity/collision system.
  - Source of truth: `PLAN-0002`.
- Decision: keep the first display-sized overlay pointer-pass-through and put
  controls in a normal window.
  - Why: a permanently interactive full-screen surface would steal clicks from
    applications underneath it and create a poor recovery path.
  - Source of truth: `PLAN-0002` and `IMPL-0002-01`.
- Decision: reassert `GlobalOverlayConfiguration.frame` after installing the
  caller's content controller.
  - Why: live diagnostics and a failing unit test proved AppKit adopts the root
    view's existing size during controller installation; geometry belongs to
    the host configuration, not the renderer.
  - Source of truth: `GlobalOverlay.swift` and `GlobalOverlayTests.swift`.
- Decision: use SpriteKit's documented Earth-gravity unit and preserve bounded
  trajectory diagnostics behind an opt-in run command.
  - Why: the initial implementation confused scene points with meters per
    second squared, and visual inspection alone did not expose the numerical
    collision loop precisely enough.
  - Source of truth: `DesktopPhysicsScene.swift`, `run`, and the testing guide.

## Correction reflection

- What happened: gravity was set to `-980`, making the demo fall too fast and
  repeatedly jitter at the floor.
- What led to it: the implementation assumed SpriteKit gravity used screen
  points per second squared without checking the SDK unit contract.
- Source: agent assumption; the acceptance wording for click-through was also
  too abstract for a first-time tester.
- What changed: gravity now uses `-9.8`, restitution is reduced to `0.48`, an
  inline unit comment prevents recurrence, `./run demo-trace` exposes future
  trajectories, and the testing guide names a concrete click target.
- Verification: the corrected trace reached stable y=25.3 and zero vertical
  velocity; automated closeout is rerun after documentation settles.
- Follow-up: collect the project owner's tuned-feel and explicit interaction
  verdict without relying on ambiguous wording.

## Verification

- Commands run: `swift test`, consumer builds, repeated `./run demo`,
  `./run check`, `./run docs`, screen captures, and Agent Ping acceptance.
- Automated checks: root build, 3 contract tests, nested consumer build, docs,
  links, continuity smoke, and diff hygiene passed.
- Manual checks: first run visibly failed; clean second run visibly showed
  multiple balls over another app after Spawn was used; project owner reported
  initial fast/jittery motion; corrected numeric trace is stable.
- Not proven: explicit click-through, Hide/Show, subjective bounce quality,
  focus preservation, Spaces, full-screen, multi-display, accessibility, and
  performance.

## Follow-ups

- Open questions: whether click-through, Hide/Show, focus behavior, and motion
  feel meet the human expectation on this Mac.
- Known debt: Spaces, full-screen, multi-display, accessibility, performance,
  and interactive object manipulation remain outside this slice.
- Recommended next step: collect the missing explicit interaction receipt,
  then decide whether temporary click-drag mode is the next experiment.
