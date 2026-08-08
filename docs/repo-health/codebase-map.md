---
type: codebase-map
title: GlobalOverlayKit Codebase Map
domain: orientation
status: active
created_at: "2026-08-09 03:50:00 JST +0900"
updated_at: "2026-08-09 03:56:00 JST +0900"
owner:
surface: GlobalOverlayKit Swift package
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

# GlobalOverlayKit Codebase Map

This is a map of what exists on disk today. Read
[CURRENT_STATE.md](../orientation/CURRENT_STATE.md) first for evidence limits.

## Read Order

1. `AGENTS.md`
2. `Package.swift`
3. `Sources/GlobalOverlayKit/GlobalOverlayConfiguration.swift`
4. `Sources/GlobalOverlayKit/GlobalOverlay.swift`
5. `Tests/GlobalOverlayKitTests/GlobalOverlayTests.swift`
6. `docs/repo-health/testing-guide.md`

## Top-Level Layout

```text
Package.swift                         Swift package manifest
Sources/GlobalOverlayKit/             public package source
Tests/GlobalOverlayKitTests/          focused contract tests
.github/workflows/ci.yml              macOS package/docs CI
run                                   local command menu
docs/                                 Agent Continuity source and generated views
scripts/agent-continuity-docs         pinned docs-tool wrapper
tests/agent-continuity-docs-smoke.sh  docs tooling smoke check
```

## Public Package Source

### `GlobalOverlayConfiguration.swift`

- `GlobalOverlayConfiguration` is the caller-owned value for initial surface
  mechanics.
- `GlobalOverlayInteraction` distinguishes pointer pass-through and
  pointer-interactive modes.
- `screenFilling(_:)` snapshots one `NSScreen` frame into a configuration.

### `GlobalOverlay.swift`

- `GlobalOverlay` is the main-actor lifecycle owner for one surface.
- The designated initializer accepts any `NSViewController`.
- The generic convenience initializer hosts a SwiftUI view.
- The private `NSPanel` applies configuration and is visible to tests only
  through the module-internal `windowForTesting` seam.

## Verification

### `GlobalOverlayTests.swift`

The current tests cover:

- panel level, transparency, pass-through, all-Spaces, and full-screen flags
- in-place pointer interaction changes
- in-place frame changes and mirrored configuration state

They do not show a window to a human or verify cross-process behavior.

### `./run`

- `./run build` compiles the package.
- `./run test` runs Swift tests.
- `./run docs` refreshes and validates structured docs.
- `./run check` combines the package, docs, and diff-hygiene baseline.

## Important Seams

- Canonical: public `NSViewController` content boundary.
- Convenience: generic SwiftUI initializer via `NSHostingController`.
- Private implementation: `NSPanel` construction and property mapping.
- Test-only: `windowForTesting`; consumers must not use it.
- Forward validation: independent Agent Commander and SpriteKit consumers.

## What Is Intentionally Missing

- executable demo or example application
- public `NSWindow` or `NSPanel` access
- overlay manager, registry, or multi-display coordinator
- automatic screen topology observation
- renderer, message, scene, render-loop, or input protocols
- package-owned persistence or global keyboard capture
- tagged release

Do not add one of these merely to make the package look complete. Add it only
when a consumer and verification plan make the ownership clear.
