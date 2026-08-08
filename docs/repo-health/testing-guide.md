---
type: testing-guide
title: Testing Guide
domain: repo-health
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

# Testing Guide

GlobalOverlayKit has automated build, contract, documentation, and hygiene
checks. It does not yet have a demo app or a physical macOS behavior receipt.

## Primary Commands

From the repository root:

```bash
./run build
./run test
./run docs
./run check
```

`./run check` is the closeout baseline. It runs:

1. `swift build`
2. `swift test`
3. structured-doc generation and validation
4. local Markdown link validation
5. the Agent Continuity smoke test
6. `git diff --check`

GitHub Actions runs `swift test` and the documentation checks on macOS 15 for
pushes and pull requests. A workflow file existing on disk is not evidence that
a remote run has passed.

## Evidence Matrix

| Evidence class | Current mechanism | What it proves | What it does not prove |
|---|---|---|---|
| Compile | `swift build` | Package source type-checks and links in the local toolchain | Runtime window behavior |
| Automated contract | `swift test` | Constructed panel properties and in-place setters match focused assertions | Cross-process pointer routing, focus, Spaces, or pixels |
| Documentation | `./run docs` | IDs, frontmatter, generated views, local links, and wrapper smoke | Package behavior |
| Diff hygiene | `git diff --check` | No whitespace errors in the diff | Correctness |
| Visual | None yet | Nothing yet | Actual appearance and frame placement |
| Physical | None yet | Nothing yet | Mouse, focus, Spaces, full-screen, drag/resize, display behavior |
| Accessibility | Label property is set in code | The requested label is passed to AppKit | VoiceOver navigation or recovery usability |
| Performance | None yet | Nothing yet | Frame pacing, energy, memory, or render throughput |
| Remote CI | Workflow exists | Intended remote baseline | A passing run until GitHub reports one |

## Automated Coverage Today

The focused tests assert:

- `.floating` window level
- transparent non-opaque panel configuration
- pointer pass-through mapping
- `.canJoinAllSpaces` and `.fullScreenAuxiliary` collection flags
- in-place pointer-interaction changes
- in-place frame updates and configuration mirroring

These are useful mechanism tests. They are not end-to-end proof.

## Required Physical Matrix Before A Release Claim

Use a small example or real consumer on a physical Mac and record observations
separately for:

- showing without stealing application focus
- pass-through clicks reaching the application beneath
- pointer-interactive controls receiving clicks
- a visible recovery route when the surface is interactive
- movement and resizing when enabled
- frame autosave and restoration when configured
- normal Spaces, switching Spaces, and joining all Spaces
- full-screen applications and transitions into/out of full screen
- menu bar/Dock-inclusive and visible-frame screen filling
- one and multiple displays, including changed topology
- VoiceOver label and keyboard reachability appropriate to the consumer
- sustained SwiftUI updates and SpriteKit rendering without unacceptable
  performance or input lag

Record hardware, macOS version, display topology, app activation state, exact
configuration, and observed result. Do not collapse these into “works.”

## Typical Verification Bundles

### Docs-only change

```bash
./run docs
git diff --check
```

### Package API or implementation change

```bash
./run check
```

Then run the smallest physical matrix affected by the change.

### Consumer integration

Run `./run check` here and the consumer's own baseline. Then record physical
behavior in the consumer because product state, controls, and renderer cadence
remain consumer-owned.

## Interpreting Failures

- A build failure is package/compiler evidence; fix it before interpreting UI.
- A property-test failure means the requested AppKit contract was not applied.
- A physical failure with passing tests means the property contract was too
  weak or macOS behavior differs from the assumption; preserve the evidence and
  update the smallest responsible seam.
- A docs failure may indicate duplicate IDs, invalid statuses, stale generated
  views, or a broken local link. Do not hand-edit generated root registries.

## Current Limits

Passing `./run check` is necessary for closeout, but it remains build,
contract, documentation, and diff evidence. It is not visual, physical,
accessibility, performance, or remote-CI evidence.
