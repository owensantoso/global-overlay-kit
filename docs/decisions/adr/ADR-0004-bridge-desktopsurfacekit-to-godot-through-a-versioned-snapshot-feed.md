---
type: adr
id: ADR-0004
title: Bridge DesktopSurfaceKit to Godot Through a Versioned Snapshot Feed
domain: architecture
status: proposed
created_at: "2026-08-11 02:31:56 JST +0900"
updated_at: "2026-08-11 04:57:05 JST +0900"
areas: [AREA-DESKTOP-PHYSICS]
deciders:
  - project owner
  - Codex recommendation
related_specs:
  - SPEC-0002
related_plans: [PLAN-0003]
related_briefs: []
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
related_issues: []
related_prs: []
supersedes: []
superseded_by: []
linked_paths:
  - Examples/DesktopPhysicsDemo/Sources/MacDesktopWindowGeometry
  - docs/orientation/explainers/EXPL-0002-godot-desktop-window-feed-contract.md
  - docs/research/RSCH-0006-game-engine-overlay-compatibility-layer.md
repo_state:
  based_on_commit: efaf82d290a31a5cab0142cf1a1afa50112d89b9
  last_reviewed_commit: efaf82d290a31a5cab0142cf1a1afa50112d89b9
---

# ADR-0004 - Bridge DesktopSurfaceKit to Godot Through a Versioned Snapshot Feed

## Context

A future Godot desktop-world project should be able to reuse the real macOS
window geometry already consumed by Desktop Physics. Reuse must not make
`DesktopSurfaceKit` depend on Godot or SpriteKit, copy Core Graphics filtering
into another plug-in, or standardize collision semantics that belong to the
game engine.

The reusable source already has the right internal split:

- `MacDesktopWindowSnapshotter` reports filtered current-Space windows in
  global Quartz coordinates with live IDs and front-to-back order;
- `VisibleRegionExtractor` derives deterministic nonoverlapping fragments and
  preserves axis-neutral source-side provenance;
- Desktop Physics' compatibility adapter owns permission policy and SpriteKit
  conversion;
- the SpriteKit scene owns collision bodies, player one-way platforms, walls,
  anti-crush behavior, and visualization.

Godot 4.6.1 is installed and current SwiftGodot targets Godot 4.6 with Swift
6.3, which is also installed. Godot's supported `OS.execute_with_pipe` API
provides redirected nonblocking child-process IO. A local probe successfully
launched a process and read one JSON line through that API.

Transport feasibility does not establish coordinate readiness. The same Mac
reported a Core Graphics display frame of 1800×1169 and a Godot screen size of
3600×2338 at scale 2.0. `DesktopSurfaceKit` deliberately promises Core Graphics
screen-space units rather than points or pixels, while Godot documents its
screen geometry in pixels. Mixed-scale and multi-display mapping remains a
physical and fixture-test gate.

This feed has one job: deliver local macOS observation facts to whichever game
engine is authoritative on that Mac. It is not the multiplayer replication
protocol. A remote peer receives the privacy-filtered canonical game state
defined by [ADR-0005](ADR-0005-separate-portable-game-state-from-observation-and-engine-runtime.md),
not raw DesktopSurfaceKit metadata.

## Candidates

### Candidate A - Signed Helper With A Versioned Snapshot Feed

A small Swift executable consumes `DesktopSurfaceKit`, polls at a bounded
consumer-owned cadence, and emits newline-delimited JSON (NDJSON) snapshots.
A Godot add-on owns the child lifecycle, validates the protocol, converts
coordinates, and gives Godot-native data to the game.

Strengths:

- reuses the canonical Swift package without exposing Swift ABI to Godot;
- keeps the wire contract fixture-testable in both Swift and GDScript;
- isolates helper failure and supports explicit fail-off/recovery;
- avoids coupling the first bridge to one Godot-minor GDExtension build;
- can serve another engine later if the data contract proves useful.

Costs and risks:

- the exported app must embed, sign, supervise, and terminate another
  executable;
- the protocol needs framing, size limits, revisions, errors, and staleness;
- transfer overhead is unmeasured;
- it does not remove the coordinate-conversion gate.

### Candidate B - SwiftGodot GDExtension

A SwiftGodot native extension links `DesktopSurfaceKit` in-process and exposes a
Godot node or service directly.

Strengths:

- no child-process or JSON lifecycle;
- direct Godot calls/signals can give a compact call site;
- the extension library can ship inside the exported project.

Costs and risks:

- SwiftGodot is a community binding and a new workspace dependency;
- the build moves with Godot, SwiftGodot, Swift, dynamic-library staging, and
  `.gdextension` compatibility;
- extension crashes share the Godot process;
- signed macOS exports need native-library validation decisions;
- it still does not solve coordinates;
- lower transfer overhead has no demonstrated value at the current 500 ms
  observation cadence.

## Decision

Choose Candidate A for the first implementation. Keep Candidate B as a measured
optimization only if helper latency, process supervision, or export packaging
fails an explicit budget.

The stable seam is an engine-neutral snapshot domain with explicit lifecycle,
identity, coordinates, availability, revisions, and compatibility. NDJSON is
the first encoding, not a permanent mandate. The helper lives outside
`DesktopSurfaceKit`; replacing its transport must not change observation or
game collision ownership.

Call this schema `desktop-window-feed`. Keep it versioned independently from
the `desktop-game-state` envelope. A Godot replica of a SpriteKit authority
does not need the window feed; it consumes canonical game state. A Godot
authority needs the window feed locally, then emits canonical game state.

The exact proposed caller API, schema, lifecycle, coordinates, packaging,
versioning, and implementation gates live in
[EXPL-0002](../../orientation/explainers/EXPL-0002-godot-desktop-window-feed-contract.md).

This ADR remains `proposed`. Do not create collider-producing adapter code until
the coordinate gate and signed embedded-helper export pass. The local transport
probe is evidence for one mechanism only.

## Consequences

Positive:

- SpriteKit and Godot share one canonical window-observation implementation
  without sharing renderer or physics types.
- `DesktopSurfaceKit` remains synchronous, stateless, and engine-neutral.
- Godot owns its collision policy and can fail off independently.
- A later GDExtension can preserve the snapshot domain if the transport changes.

Costs and risks:

- one more executable and protocol need release and runtime receipts;
- source, helper, add-on, and protocol versions must be distinguished;
- two active consumers may still call the same snapshotter independently;
- editor success cannot prove signed export, sandbox behavior, Spaces, display
  mapping, or collision feel.

## Alternatives Considered

### Put Polling Or Serialization In DesktopSurfaceKit

Rejected. It would make the canonical package own transport and lifecycle that
its current public contract deliberately assigns to consumers.

### Reimplement Observation In A Godot Native Plug-In

Rejected. It would duplicate filtering, identity, ordering, availability, and
visible-region behavior already versioned in `DesktopSurfaceKit`.

### Run One Persistent Machine-Wide Broker

Deferred. It could remove runtime duplicate polling across active consumers,
but adds installation, authentication, upgrade, and stale-daemon recovery. One
child per Godot process is proportional until concurrent use proves otherwise.

### Exchange Snapshot Files

Rejected for the live path. Files add atomic-replacement, stale-session, cleanup,
and another polling cadence. They remain useful as protocol fixtures.

### Add The Bridge To The Existing Flat-To-Depth POC

Rejected without a separate scope decision. That POC proves a visual transition
in an engine-owned normal window; it is not the maintained desktop-world or
overlay consumer.

## Guardrails

- Import `DesktopSurfaceKit`; never copy its Core Graphics observation code.
- Keep Accessibility, selected-screen conversion, and user recovery in the
  product adapter.
- Keep collisions, one-way surfaces, walls, anti-crush, and outlines in Godot.
- Use axis-neutral sides across the wire.
- Clear geometry on unavailable, stale, malformed, incompatible, or dead feeds.
- Treat window IDs as one-live-window/session identities only.
- Keep process IDs, application names, titles, and local window numbers out of
  remote game-state packets by default.
- Never snapshot on the render or physics cadence.
- Prove display mapping and signed export before describing the feed as
  collider-ready or plug-and-play.

## Primary Sources

- Godot [`OS`](https://docs.godotengine.org/en/stable/classes/class_os.html)
  documents redirected child-process pipes and independent process lifetime.
- Godot's [macOS export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_macos.html)
  documents helper executables, sandbox limits, Universal 2 export, and signing.
- Godot's [GDExtension overview](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/what_is_gdextension.html)
  defines the native shared-library route.
- The primary [SwiftGodot repository](https://github.com/migueldeicaza/SwiftGodot)
  documents current Godot 4.6, Swift 6.3, and extension packaging requirements.

## Maintenance Rule

Preserve the snapshot domain even if transport changes. The first implementation
task starts with display conversion and signed export, not collider creation.
