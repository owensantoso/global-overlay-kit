---
type: adr
id: ADR-0003
title: Stage DesktopSurfaceKit Promotion Through Versioned Compatibility Gates
domain: architecture
status: proposed
created_at: "2026-08-10 19:04:52 JST +0900"
updated_at: "2026-08-10 19:04:52 JST +0900"
areas: [AREA-DESKTOP-PHYSICS]
deciders:
  - project owner
  - Codex recommendation
related_specs:
  - SPEC-0002
related_plans: [PLAN-0003]
related_briefs: []
related_sessions: []
related_issues: []
related_prs: []
supersedes: []
superseded_by: []
linked_paths:
  - Examples/DesktopPhysicsDemo/Package.swift
  - Examples/DesktopPhysicsDemo/Sources/MacDesktopWindowGeometry
  - docs/research/RSCH-0008-macos-window-geometry-reuse-readiness.md
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# ADR-0003 - Stage DesktopSurfaceKit Promotion Through Versioned Compatibility Gates

## Context

Desktop Physics wants to reuse macOS window rectangles first explored in the
historical `DesktopSurfaceKit` package. That package has useful seams and eight
passing unit tests, but its only known copy lives in a dated, non-Git POC
directory. It therefore has no canonical change history, immutable release
tags, owner, compatibility policy, or dependency version for a consumer to
select or roll back to.

The project owner wants to keep improving DesktopSurfaceKit without making
Desktop Physics and future consumers move in lockstep or break silently. This
is the same job npm packages solve for JavaScript, but the native mechanism here
is Swift Package Manager (SwiftPM): a source repository, semantic-version Git
tags, dependency requirements in `Package.swift`, and a resolved version in the
top-level application's `Package.resolved` file.

Versioning protects a released contract; it does not create one. The package
must first state what callers may rely on and distinguish three kinds of
compatibility:

| Compatibility | Meaning | Evidence |
|---|---|---|
| Source | Existing consumer code still compiles against the new release | public API comparison plus consumer builds |
| Behavioral | The same inputs retain documented filtering, coordinate, identity, and failure semantics | fixture and contract tests plus release classification |
| Runtime | The signed app still receives useful geometry under real macOS permission, display, Space, window, and process conditions | signed integration and physical protocols |

Semantic versioning communicates intended source and behavioral compatibility.
It cannot guarantee runtime permission behavior or protect against a macOS
change by itself.

## Decision

Use a staged **adapt now, package after the contract is real** lifecycle.

1. Keep the narrow `MacDesktopWindowGeometry` adapter inside the Desktop Physics
   example package while the first window-platform behavior is being proven.
   Do not add an absolute-path dependency on the historical POC.
2. Treat the historical package as design evidence, not a maintained source of
   truth. Its code and tests should be promoted only into a canonical owned Git
   repository with provenance preserved.
3. Before the first tag, narrow and document the public observation contract.
   Keep game collision policy in `DesktopPhysicsKit`; DesktopSurfaceKit may
   report windows, rectangles, identity, ordering, availability, and source
   limitations, but not floors, bounce, one-way landing, or anti-crush rules.
4. Once the promotion gate below passes, tag a `0.1.0` release and let the
   consumer accept only compatible `0.1.x` releases. During `0.x`, each minor
   line is allowed to redesign the API; patch releases in one minor line are a
   project promise to preserve source and documented behavior.
5. Consumers update deliberately. A new DesktopSurfaceKit tag does not require
   Desktop Physics to update. The consumer reviews the release, updates its
   resolved dependency, runs automated and signed runtime checks, and commits
   that accepted resolution.
6. Move to `1.0.0` only after the public contract has survived at least two real
   consumers and the release, compatibility, migration, and runtime gates are
   routine. After `1.0`, incompatible public API or documented behavioral
   changes require a major version.

### Caller-facing boundary

The first reusable contract should be a small snapshot provider rather than the
POC's combined window, element-tree, boundary-extraction, and helper-process
workflow.

```text
Desktop window observer
  input: observation scope and display context
  output: availability + revision + ordered window snapshots

Window snapshot
  stable-enough ID for one window lifetime
  process identity and optional app name
  frame in one documented coordinate space
  front-to-back ordering
```

The contract must explicitly define:

- coordinate origin, axis direction, units, and multi-display conversion;
- what “on screen” means, including occluded and current-Space windows;
- filtering of desktop, Dock, menu-bar, overlay-owning, nonregular, transparent,
  minimized, and undersized windows;
- window-ID lifetime and what happens when a window disappears or is recreated;
- permission states and fail-off behavior;
- synchronous versus asynchronous ownership, concurrency, cancellation, and
  refresh cadence;
- bounds, partial results, timeouts, and the distinction between no windows and
  unavailable observation.

Element traversal and boundary extraction may remain separate package products,
but the window-only caller must not be forced through those broader APIs.

### Dependency declarations

During co-development, a path dependency uses whatever source is currently on
disk. It provides no version isolation and should not be the released consumer
contract:

```swift
dependencies: [
    .package(path: "../../DesktopSurfaceKit")
]
```

For a `0.1.x` release line, accept patches but require an explicit decision to
cross to `0.2.0`:

```swift
dependencies: [
    .package(
        url: "<canonical DesktopSurfaceKit Git URL>",
        .upToNextMinor(from: "0.1.0")
    )
]
```

Do not use `from: "0.1.0"` during initial development. In SwiftPM that means
“up to the next major,” so it can accept any release below `1.0.0`, including a
deliberately breaking `0.2.0`.

After `1.0.0`, the usual compatible-major requirement is appropriate:

```swift
dependencies: [
    .package(
        url: "<canonical DesktopSurfaceKit Git URL>",
        from: "1.2.0"
    )
]
```

An exact requirement is a temporary containment tool, not the normal library
contract:

```swift
.package(url: "<canonical DesktopSurfaceKit Git URL>", exact: "0.1.3")
```

It prevents the resolver from selecting any other release, but SwiftPM warns
that exact requirements can create dependency-graph conflicts. Prefer a bounded
range plus the leaf application's committed `Package.resolved` file.

Branch and revision requirements are also development tools. Branches move and
can silently change at the next update; revisions receive no fixes. SwiftPM also
prevents a package with branch- or revision-based dependencies from being used
as a version-based dependency until those requirements are removed.

### What `Package.resolved` does

`Package.swift` states the acceptable range. The top-level application's
`Package.resolved` records the exact accepted tag and revision inside that
range. Commit the leaf app's resolved file so local and continuous-integration
builds use the same dependency version.

A library package's own `Package.resolved` does not pin versions when another
project consumes that library. The final app or workspace owns the effective
resolution. When the nested Desktop Physics package is tested directly, it is
the top level for that command; when the Xcode app consumes it, the app or
workspace resolution is authoritative.

### Update and rollback workflow

1. Develop DesktopSurfaceKit changes on its canonical main branch. Released
   consumers stay on their current resolved tag.
2. Run package tests, public API comparison, behavior contracts, and consumer
   canaries against the candidate source.
3. Classify the change, write release notes and migration guidance, and create
   a new immutable semantic-version tag. Never move or rewrite an existing tag.
4. In Desktop Physics, explicitly update DesktopSurfaceKit, inspect the
   `Package.resolved` diff, build, run contract tests, and perform the required
   signed runtime protocol.
5. Commit the consumer change only after acceptance. Other consumers may remain
   on the older tag until they are ready.

Rollback means reverting the consumer code and `Package.resolved` to the last
accepted release. If a bad release was tagged, do not retag it: restore
compatibility in a new patch, temporarily tighten the consumer range, or pin the
known-good release while the fix is prepared. If live permission behavior
fails, the feature must fail off even when a source rollback is available.

### Compatibility test strategy

DesktopSurfaceKit's continuous integration should run:

- all package unit and fixture tests on the minimum and current supported Swift
  toolchains and macOS deployment targets;
- a release build with strict concurrency and warnings treated as errors;
- `swift package diagnose-api-breaking-changes <last-compatible-tag>` for each
  public library product once the package has Git history and a baseline tag;
- deterministic fixture contracts for filtering, ordering, coordinates,
  stable-enough identity, unavailable/empty states, and encoded data if Codable
  remains public;
- a candidate-source build and test of every supported consumer, initially
  Desktop Physics plus the original gaze use case or its replacement;
- a latest-released-version consumer lane, proving the documented dependency
  still resolves independently of main-branch work.

Compilation and API diagnostics prove only source compatibility. Release gates
must separately exercise a consistently signed helper/app with Accessibility
denied, granted, and revoked; window creation, movement, resize, and teardown;
current-Space and occlusion behavior; and representative multi-display layouts.

### Minimum promotion gate

Do not tag or consume DesktopSurfaceKit as a reusable dependency until all of
these are true:

- [ ] one canonical owned Git repository contains `Package.swift` at the
      package root, source history, license/provenance, and CI;
- [ ] product and module names, supported macOS/Swift versions, owner, and
      release policy are documented;
- [ ] the public window contract defines coordinates, scope, filtering,
      identity lifetime, permission, concurrency, update, and error behavior;
- [ ] broad Accessibility element traversal is separated from the window-only
      product or is demonstrably optional to that caller;
- [ ] pure contract tests cover multi-display coordinates, filtering,
      ordering, identity churn, empty/unavailable results, and limits;
- [ ] public API comparison has a stored Git baseline and is a required CI gate;
- [ ] Desktop Physics builds and passes its geometry/platform policy tests
      against the release candidate without copying package internals;
- [ ] a consistently signed runtime has passed denied/granted/revoked
      Accessibility and live window movement/resize checks;
- [ ] release notes, migration notes, immutable tag rules, and rollback steps
      exist before `0.1.0`;
- [ ] the consuming app commits its accepted `Package.resolved` resolution.

## Consequences

Positive:

- Desktop Physics work can continue now without coupling itself to an unstable,
  non-versioned POC directory.
- DesktopSurfaceKit can change freely on its main branch while consumers remain
  on known-good releases.
- Every consumer opts into upgrades and can roll back independently.
- A narrow package contract can replace the temporary adapter later without
  moving collision policy into the observation layer.
- Compatibility failures become classifiable and testable instead of appearing
  as an undifferentiated “the package update broke the game.”

Costs and risks:

- The adapter and candidate package will temporarily duplicate a small amount
  of window-observation logic.
- Tags and `Package.resolved` prevent surprise source updates, but they do not
  prove behavior or real macOS permission state.
- Pre-`1.0` consumers must intentionally cross each minor version and may need
  migrations.
- Maintaining consumer canaries and signed runtime protocols adds release work.
- The current POC remains unready until canonical ownership and Git history are
  established; passing eight unit tests does not remove that blocker.

## Alternatives Considered

### Depend directly on the historical path now

Rejected. SwiftPM path dependencies ignore version constraints and use the
files currently present at that path. The POC has no Git source of truth, and a
change would affect every local consumer immediately with no tag or rollback
record.

### Copy or adapt a narrow seam inside Desktop Physics indefinitely

Accepted only as the current proving stage. It isolates the game from the POC
and is the smallest reversible path, but indefinite duplication would allow the
observation contract to drift once a second maintained consumer exists.

### Co-develop in one repository using path dependencies

Useful after a canonical repository exists and when coordinated changes truly
need one atomic commit. It gives the fastest development loop, but all local
consumers see the current source and therefore receive no release isolation.
Use it for candidate development or a temporary SwiftPM editable dependency,
not as proof that downstream releases are safe.

### Consume a branch or commit

Deferred to exceptional experiments. A branch is mutable; a commit is frozen
but receives no compatible fixes. Both complicate publishing a version-based
dependency and provide weaker release communication than semantic tags.

### Create and tag a standalone package immediately

Rejected until the promotion gate passes. A tag would make the current broad
API look supported without defining its coordinate, update, permission,
behavior, or compatibility promises.

### Never extract a package

Rejected once two maintained consumers rely on the same observation semantics.
At that point copied implementations create more drift risk than a versioned
dependency. Extraction is earned by the shared contract, not by code volume.

## Guardrails

- Do not make Desktop Physics wait for DesktopSurfaceKit hardening; keep the
  temporary adapter narrow and replaceable.
- Do not depend on the dated absolute path or call it a released package.
- Do not place game collision semantics in DesktopSurfaceKit.
- Do not use a floating branch for a released consumer.
- Do not treat `Package.resolved`, compilation, API diagnostics, or semantic
  version numbers as runtime Accessibility evidence.
- Do not modify or reuse a released tag. Correct it with a new release.
- Deprecate before removal and provide a migration window whenever a supported
  line permits it.
- A behavioral change to filtering, coordinates, identity, availability, or
  update timing is compatibility-significant even when public Swift signatures
  remain unchanged.

## References

- [SwiftPM: Adding dependencies](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/addingdependencies/)
- [SwiftPM: Resolving and updating dependencies](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/resolvingpackageversions/)
- [SwiftPM: Releasing and publishing a package](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/releasingpublishingapackage/)
- [Swift PackageDescription dependency requirements](https://docs.swift.org/package-manager/PackageDescription/PackageDescription.html#Package-Dependency)
- [Semantic Versioning 2.0.0](https://semver.org/)

The protective boundary is deliberate promotion: main can keep moving, tags
stay immutable, and each consumer chooses when a tested release becomes its
new resolved version.
