---
type: implementation-brief
id: IMPL-0003-02
title: Add Portable 3D Game Core
domain: product
status: in_progress
created_at: "2026-08-11 05:15:00 JST +0900"
updated_at: "2026-08-11 05:15:00 JST +0900"
parent_plan: PLAN-0003
task_refs:
  - PLAN-0003-task-9
owner:
areas: [AREA-DESKTOP-PHYSICS]
depends_on: [ADR-0005]
parallel_with: []
related_specs:
  - SPEC-0002
related_adrs: [ADR-0005]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
related_issues: []
related_prs: []
linked_paths:
  - Examples/DesktopPhysicsDemo/Package.swift
  - Examples/DesktopPhysicsDemo/Sources
  - Examples/DesktopPhysicsDemo/Tests
repo_state:
  based_on_commit: 7d49376
  last_reviewed_commit: 7d49376
---

# IMPL-0003-02 - Add Portable 3D Game Core

## Parent Plan

- [PLAN-0003](PLAN-0003-reusable-desktop-world-and-character-controls.md)

## Goal

Create the first pure, renderer-neutral implementation of the versioned
three-dimensional game-state contract and the small deterministic policies that
the SpriteKit and Godot adapters must share.

## Scope

In scope:

- nested `DesktopGameCore` library product/target with no Apple UI/graphics or
  engine imports;
- finite `Double` X/Y/Z vectors, normalized quaternions, pose, kinematics,
  viewport, depth range, rules, surface, avatar, object, asset/mask reference,
  snapshot, input, event, delta, and envelope values;
- explicit world/entity/surface/session identity and protocol/schema versions;
- right-handed X-right/Y-up/Z-toward-viewer semantics and `Z = 0` desktop;
- planar-subset validation for SpriteKit without importing SpriteKit;
- pure front-to-back drag-selection policy over caller-reported painted
  coverage;
- pure feature-scoped wall-traversal state and clearance policy;
- golden JSON fixtures, compatibility/privacy assertions, and focused tests.

Out of scope:

- changing current SpriteKit scene behavior or models;
- alpha-mask decoding, textures, nodes, physics bodies, contacts, or pointer
  capture;
- a Godot plug-in, networking transport, matchmaking, server, asset transfer,
  binary encoding, or deterministic physics solver;
- package extraction or a new repository.

## Execution

1. Add failing public-value, validation, Codable, privacy, planar, drag, and
   wall-traversal tests.
2. Add the product and pure source target with the smallest API satisfying the
   fixtures.
3. Encode one planar desktop fixture and one nonplanar depth fixture.
4. Prove planar state is accepted while nonplanar authority state is rejected
   by the SpriteKit capability check.
5. Run the nested package and root repository checks.

## Verification

```bash
swift test --package-path Examples/DesktopPhysicsDemo
./run check
```

Required fixtures cover invalid/nonfinite vectors, non-normalizable
quaternions, privacy-safe defaults, ID nonreuse assumptions, snapshot/delta
base sequencing, planar Z=0 projection, distinct desktop layer rank versus
world Z, and symmetric wall traversal.

## Done Checklist

- [ ] Pure product and target compile
- [ ] Golden state fixtures pass
- [ ] Planar/nonplanar capability checks pass
- [ ] Drag and wall policies pass
- [ ] Full repository check passes
- [ ] Paper trail reflects exact implemented versus deferred scope
