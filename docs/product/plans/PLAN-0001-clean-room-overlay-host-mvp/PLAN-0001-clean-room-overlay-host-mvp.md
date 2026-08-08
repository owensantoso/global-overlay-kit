---
type: plan
id: PLAN-0001
title: Clean-Room Overlay Host MVP
domain: product
status: completed
created_at: "2026-08-09 03:50:32 JST +0900"
updated_at: "2026-08-09 04:05:11 JST +0900"
planned_execution_start: "2026-08-09 03:45:00 JST +0900"
planned_execution_end:
actual_execution_start: "2026-08-09 03:45:00 JST +0900"
actual_execution_end: "2026-08-09 04:05:17 JST +0900"
owner:
sequence:
  roadmap: "1.0"
  sort_key: "001.000"
  lane: product
  after: []
  before: []
areas: [AREA-OVERLAY-HOST]
related_specs: [SPEC-0001]
related_adrs: [ADR-0001]
related_sessions:
  - 2026-08-09-project-foundation-and-overlay-boundary
related_issues: []
related_prs: []
linked_paths:
  - Sources/GlobalOverlayKit
  - Tests/GlobalOverlayKitTests
repo_state:
  based_on_commit:
  last_reviewed_commit: 6ea6bc1f6febe20f156ad045b9e5b0b6ae40a4ae
---

# PLAN-0001 - Clean-Room Overlay Host MVP

**Goal:** Establish the smallest buildable GlobalOverlayKit package that can
host arbitrary native content above other macOS applications without absorbing
content, renderer, or product behavior.

**Architecture:** One main-actor `GlobalOverlay` owns one private AppKit panel.
The canonical content seam is `NSViewController`; SwiftUI is a convenience
adapter. `ADR-0001` and `AREA-OVERLAY-HOST` own the boundary.

**Tech Stack:** Swift Package Manager, Swift 6, macOS 13+, AppKit, SwiftUI
interop, Swift Testing, Agent Continuity docs.

**Source Spec:** [SPEC-0001](../../specs/SPEC-0001-global-overlay-surface-host.md)

## Prerequisites

- Project owner approved creating a separate reusable package.
- The overlay boundary was independently stress-tested against a message
  consumer and a future SpriteKit consumer.
- A bounded prior-art review identified adjacent work but no complete general
  macOS drop-in for the requirements.

## Why Now

Agent Commander otherwise risks copying or coupling to Live Text Chat's
presentation. Establishing the substrate first makes the ownership seam explicit
before either consumer accumulates more window code.

## Product Decisions

- Public identity describes the overlay capability, not the private panel.
- Core API accepts arbitrary AppKit content.
- SwiftUI is convenient but not canonical.
- One instance owns one surface.
- Implementation is clean-room from Apple APIs.
- Automated and physical evidence stay separate.

## Domain Model And Interfaces

- Terms: overlay surface, host, content, panel, pass-through, interactive.
- Public types: `GlobalOverlay`, `GlobalOverlayConfiguration`,
  `GlobalOverlayInteraction`.
- Canonical content seam: `NSViewController`.
- Related area: `AREA-OVERLAY-HOST`.

## Design Rules

- Keep `NSPanel` private.
- Do not add product, renderer, scene, message, or input-command protocols.
- Make pointer pass-through explicit and distinct from activation/focus.
- Keep main-actor ownership visible in the API.
- Add only configuration exercised by the initial use cases.

## Task Dependencies And Parallelization

1. Define the package and boundary docs first.
2. Implement configuration and AppKit host together because their property
   mapping is one contract.
3. Add focused tests after the host surface exists.
4. Research and continuity docs can proceed in parallel with source work as
   long as current state is synchronized before closeout.
5. Run generated-doc and package checks after all source docs settle.

Net: the package seam is foundational; source and research are independent
workstreams until the final evidence-based state update.

## Out Of Scope

- Agent Commander message rendering or integration
- Live Text Chat extraction or modification
- SpriteKit prototype implementation
- demo application and physical verification
- tagged release and public API stability promise
- multi-display coordinator or global input

## File Structure

```text
Package.swift
Sources/GlobalOverlayKit/
  GlobalOverlay.swift
  GlobalOverlayConfiguration.swift
Tests/GlobalOverlayKitTests/
  GlobalOverlayTests.swift
docs/
  architecture, decisions, orientation, product, research, repo-health
```

## Implementation Tasks

### Task 1: Package And Public Configuration

- Define a macOS library product and initial platform floor.
- Model only native surface mechanics required by the two motivating consumers.
- Keep the configuration free of messages, scenes, render cadence, and input
  commands.

Dependencies: prerequisites only.

### Task 2: AppKit Host And SwiftUI Convenience

- Construct one transparent non-activating panel.
- Install arbitrary `NSViewController` content.
- Apply pass-through, collection behavior, frame, and presentation mechanics.
- Add the generic SwiftUI convenience initializer through
  `NSHostingController`.

Dependencies: Task 1. See [IMPL-0001-01](IMPL-0001-01-appkit-host-and-swiftui-convenience.md).

### Task 3: Focused Contract Tests

- Verify important panel properties at construction.
- Verify mutable interaction and frame operations.
- Do not label these tests as physical cross-application evidence.

Dependencies: Task 2.

### Task 4: Durable Docs And Verification

- Complete orientation, area, ADR, spec, plan/brief, research, idea,
  explainer, testing, and session artifacts.
- Regenerate Agent Continuity views.
- Run package, docs, link, smoke, and diff checks.

Dependencies: Tasks 1-3 and research findings.

## Validation

```bash
./run check
```

The command must pass before the plan is marked complete. It proves build,
focused contract tests, docs integrity, and diff hygiene only.

## Completion Criteria

- Public AppKit and SwiftUI construction paths exist.
- Configuration and lifecycle stay within `AREA-OVERLAY-HOST`.
- Focused automated tests cover the initial property contract.
- Clean-room provenance and prior-art evidence are documented.
- Generated docs and local links validate.
- `./run check` passes.
- Physical behavior remains explicitly unverified and queued for a consumer
  milestone rather than silently treated as complete.

No code or product behavior beyond this milestone should be inferred from plan
completion.
