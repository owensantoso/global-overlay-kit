---
type: implementation-brief
id: IMPL-0003-02
title: Add Portable 3D Game Core
domain: product
status: completed
created_at: "2026-08-11 05:15:00 JST +0900"
updated_at: "2026-08-11 06:22:00 JST +0900"
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
  based_on_commit: 3882275
  last_reviewed_commit: 3882275
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
- right-handed X-right/Y-up/Z-toward-viewer semantics, bottom-left screen-plane
  origin, world-unit coordinates, and `Z = 0` desktop;
- planar-subset validation for SpriteKit without importing SpriteKit;
- pure front-to-back drag-selection policy over caller-reported painted
  coverage;
- pure coincident-plane-scoped wall-traversal state and clearance policy;
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
quaternions, privacy-safe defaults, enforced ID nonreuse, duplicate and
conflicting deltas, duplicate/reordered admission, unknown optional JSON
fields, explicit coordinate conversion, atomic replica validation/application/
commit, competing-update serialization, application-failure recovery,
stale-tick rejection, bounded planar tolerance, deterministic painted-rank
ties, canonical quaternion hemispheres, atomic shared ID retirement,
snapshot/delta base sequencing, planar Z=0 projection, distinct desktop layer
rank versus world Z, and symmetric coincident-plane wall traversal through
full-bounds clearance.

## Done Checklist

- [x] Pure product and target compile
- [x] Golden state fixtures pass
- [x] Planar/nonplanar capability checks pass
- [x] Drag and wall policies pass
- [x] Full repository check passes
- [x] Paper trail reflects exact implemented versus deferred scope

## Implementation Evidence

Re-review found that the two-phase token API still allowed a caller to mutate
external state before discovering that an older token could no longer commit.
The replacement now serializes validation, synchronous throwing payload
application, and sequence/tick commit as one exclusive operation.

The code-review correction addressed that the first implementation allowed active wall
exclusion to depend on a relative direction that flips after center crossing,
mutated replica sequence state before caller application succeeded, and left
planar tolerance, equal painted ranks, quaternion sign, and ledger ownership
underspecified.

Implemented one nested `DesktopGameCore` product and target using Foundation
only. It owns validated three-dimensional values, stable protocol/version and
identity vocabulary, snapshots/deltas/inputs/events, privacy-safe asset and
surface references, bounded planar capability checks, an exclusive synchronous
replica validation/application/commit coordinator, deterministic
painted-candidate selection, a locked shared
per-session authority entity-ID ledger, and coincident-plane-scoped wall
traversal/clearance.

The frozen version-1 fixtures cover today's planar `Z = 0` desktop, required
bottom-left/world-unit viewport semantics, conversion from top-left observation
space, and a nonplanar avatar with negative-Z movement, X-axis rotation, and
three-axis kinematics. Delta initialization and decoding reject duplicate IDs,
remove/upsert conflicts, and avatar/object identity collisions. Replica
application rejects duplicate/reordered state payloads and stale ticks
without invoking the caller; successful synchronous application and committed
sequence advancement occur under one lock, while a thrown application leaves
the coordinator state unchanged.
Quaternion signs use one canonical hemisphere, painted-rank ties use UTF-8
entity-ID order, and active traversal ignores post-center-cross direction
changes until previous-frame full bounds clear. Public wire-facing constructors
and decoders validate instead of trapping.

SpriteKit-specific application remains deliberately outside this brief, so the
existing scene behavior did not change. A Godot fixture consumer remains the
next independent compatibility gate.

Verification on 2026-08-11:

- the expected test-first compile failed because the new API did not exist;
- the second review's test-first compile failed on the absent admission token,
  commit/tick state, and reference-ledger API;
- the final re-review's test-first compile failed on the absent exclusive
  replica coordinator;
- 32 focused `DesktopGameCore` Swift Testing tests passed;
- the complete nested package passed 33 XCTest tests plus 44 Swift Testing
  tests;
- `./run docs && ./run check` passed the three root overlay tests, complete
  nested package, signed Debug app build, and documentation smoke checks.
