---
type: implementation-brief
id: IMPL-0001-01
title: AppKit Host and SwiftUI Convenience
domain: product
status: completed
created_at: "2026-08-09 03:50:32 JST +0900"
updated_at: "2026-08-09 04:05:11 JST +0900"
planned_execution_start: "2026-08-09 03:45:00 JST +0900"
planned_execution_end:
actual_execution_start: "2026-08-09 03:45:00 JST +0900"
actual_execution_end: "2026-08-09 04:05:17 JST +0900"
parent_plan: PLAN-0001
task_refs:
  - PLAN-0001-task-2
  - PLAN-0001-task-3
owner:
areas: [AREA-OVERLAY-HOST]
depends_on: []
parallel_with:
  - RSCH-0001
related_specs: [SPEC-0001]
related_adrs: [ADR-0001]
related_sessions:
  - 2026-08-09-project-foundation-and-overlay-boundary
related_issues: []
related_prs: []
linked_paths:
  - Sources/GlobalOverlayKit/GlobalOverlay.swift
  - Sources/GlobalOverlayKit/GlobalOverlayConfiguration.swift
  - Tests/GlobalOverlayKitTests/GlobalOverlayTests.swift
repo_state:
  based_on_commit:
  last_reviewed_commit: 6ea6bc1f6febe20f156ad045b9e5b0b6ae40a4ae
---

# IMPL-0001-01 - AppKit Host And SwiftUI Convenience

## Parent Plan

- [PLAN-0001](PLAN-0001-clean-room-overlay-host-mvp.md)

This brief groups the configuration, host, and focused contract tests because
they form one bounded public API slice.

## Task Goal

Implement one renderer-neutral macOS overlay host and prove its initial AppKit
property contract without adding product behavior.

After this task:

- AppKit consumers can supply any `NSViewController`.
- SwiftUI consumers can use a generic convenience initializer.
- callers can control initial mechanics and basic lifecycle.
- focused tests can detect accidental property-mapping regressions.

## Scope

In scope:

- library manifest and macOS platform floor
- surface configuration and pointer interaction vocabulary
- private `NSPanel` creation
- arbitrary content controller and SwiftUI hosting
- show/hide, pointer interaction, frame update, and screen-fill operations
- focused construction and setter tests

Out of scope:

- message or game rendering
- renderer protocol, render loop, global input, or display observer
- demo application and physical behavior receipt
- release tagging and consumer migration

## Ownership

- Owns: `Sources/GlobalOverlayKit/**` and focused package tests.
- Adjacent consumer work owns: Agent Commander views and SpriteKit scene code.
- Docs work owns: boundary, provenance, current state, and evidence limits.
- Integration expectation: a self-contained package API; consumers follow in
  separate milestones.

## Preserve

- `NSViewController` remains the canonical seam.
- `NSPanel` stays private.
- SwiftUI stays a convenience.
- Product state and cadence remain caller-owned.
- Pointer interaction stays distinct from global keyboard input.

## Dependencies And Parallelization

- Depends on: parent-plan prerequisites and `SPEC-0001`.
- Can run in parallel with: prior-art research and continuity doc drafting.
- Write-conflict notes: source/test implementer and docs implementer must keep
  ownership disjoint, then synchronize current state before closeout.

## Entry Point

- Start from: `Package.swift`
- Main seam: `GlobalOverlay(configuration:contentViewController:)`

## Files

```text
Sources/GlobalOverlayKit/GlobalOverlayConfiguration.swift
Sources/GlobalOverlayKit/GlobalOverlay.swift
Tests/GlobalOverlayKitTests/GlobalOverlayTests.swift
```

## Execution Steps

### 1. Define the native configuration

Model frame, minimum size, pointer interaction, movement/resizing, collection
behavior, shadow, accessibility label, and optional frame autosave name. Avoid
renderer and product vocabulary.

### 2. Build one private panel host

Create a transparent non-activating panel, install the supplied content
controller, apply configuration, retain it for show/hide, and keep all public
operations on the main actor.

### 3. Add the SwiftUI adapter

Wrap generic view-builder content in `NSHostingController` and delegate to the
same designated initializer.

### 4. Add only proven lifecycle operations

Expose show/hide, pointer interaction change, frame update, and selected-screen
fill. Leave display monitoring and general reconfiguration outside.

### 5. Add focused contract tests

Inspect private panel state through a module-internal test seam. Assert
construction mapping and in-place updates without claiming physical behavior.

## Verification

```bash
swift build
swift test
./run docs
git diff --check
```

Full closeout:

```bash
./run check
```

Manual smoke is intentionally not part of this bounded source brief. It belongs
to the first consumer milestone and must be reported as physical evidence.

## Risks And Traps

- `NSPanel` property assertions may pass while macOS behaves differently across
  Spaces, full-screen apps, and focus states.
- An interactive non-activating panel may not satisfy keyboard-control needs.
- `fill(_:)` may be misread as ongoing screen management.
- Exposing the panel would let consumers bypass the seam.
- Adding convenience for one renderer could quietly become product ownership.

## Review Focus

- Spec reviewer: confirm every public concept is a surface mechanic.
- Code reviewer: confirm the private panel, main-actor lifecycle, and SwiftUI
  delegation preserve the accepted boundary.
- Evidence reviewer: confirm automated results are not described as physical
  observations.

## Done Checklist

- [x] Package and public configuration exist.
- [x] AppKit host accepts arbitrary `NSViewController` content.
- [x] SwiftUI convenience delegates through `NSHostingController`.
- [x] Focused contract tests exist.
- [ ] Full `./run check` passes.
- [ ] Parent plan and current-state closeout are synchronized.
