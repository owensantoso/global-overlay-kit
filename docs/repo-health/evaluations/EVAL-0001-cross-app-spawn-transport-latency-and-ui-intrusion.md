---
type: evaluation
id: EVAL-0001
title: Cross-App Spawn Transport Latency and UI Intrusion
domain: product
status: completed
created_at: "2026-08-10 18:52:50 JST +0900"
updated_at: "2026-08-10 18:52:50 JST +0900"
owner: Owen
hypothesis: A bundle-bound direct App Action can remove Shortcuts UI intrusion and materially reduce warm trigger-to-world latency without changing the Desktop Physics domain command.
artifact_root: artifacts/evaluations/EVAL-0001/
dataset_version: 2026-08-10-installed-v1
fixture_digest: local-installed-builds-no-private-payloads
run_command: manual protocol in this document
metrics_version: monotonic-cross-process-v1
baseline_eval:
related_research: []
related_diagnostics: []
related_adrs:
  - ADR-0002
related_specs:
  - SPEC-0002
related_plans:
  - PLAN-0003
related_sessions:
  - docs/repo-health/session-logs/2026-08-10-reusable-desktop-world-and-controls.md
linked_paths:
  - Examples/DesktopPhysicsDemo/App/Sources/ActionLatencyDiagnostics.swift
  - Examples/DesktopPhysicsDemo/App/Sources/DesktopPhysicsAppIntents.swift
  - Examples/DesktopPhysicsDemo/App/Sources/DesktopPhysicsDemoApp.swift
  - Examples/DesktopPhysicsDemo/App/Sources/DesktopPhysicsSemanticAction.swift
  - Examples/DesktopPhysicsDemo/App/Sources/PhysicsDemoModel.swift
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# EVAL-0001 - Cross-App Spawn Transport Latency and UI Intrusion

## Hypothesis

A bundle-bound semantic action should beat a saved macOS Shortcut on both
interaction quality and warm latency. The accepted route must:

- call the same `DesktopPhysicsWorld.spawn` command as the visible Spawn button;
- remove the Shortcuts menu-bar status indicator;
- avoid reopening or activating Desktop Physics while it is already running;
- preserve the foreground application on a cold launch; and
- carry one lowercase `run_id` from Hold Keys gesture resolution to
  `world.spawn.completed` so the measured endpoints are causally joined.

This evaluation compares transports. It does not measure microphone detection,
the configured multi-snap grouping wait, display refresh, or the time at which a
human first perceives the new object.

## Candidates

1. **Saved Shortcut / App Intent.** Hold Keys runs a user Shortcut through
   `/usr/bin/shortcuts`; the Shortcut invokes Desktop Physics' parameter-free
   App Intent.
2. **Direct Launch Services URL.** Hold Keys opens the target's bundle-bound
   semantic URL without requesting activation. This works for cold launch, but
   also asks Launch Services to reopen a warm app.
3. **Hybrid direct App Action.** When Desktop Physics is running, Hold Keys posts
   the same strict semantic URL through a local distributed notification. When
   it is not running, the verified Launch Services route remains the cold
   fallback. Both routes resolve to the same target command.

## Dataset / Fixtures

- Apple Development-signed Release builds of Hold Keys and Desktop Physics on
  the same Mac.
- The installed Desktop Physics app at
  `~/Applications/Desktop Physics Demo.app` and the installed Hold Keys app.
- One parameter-free action: **Spawn Random Object**.
- Warm means Desktop Physics and its world were already running. Cold means the
  app was terminated before the sample.
- Warm samples were serialized so a prior spawn could not overlap the next
  sample. Cold samples began with ChatGPT frontmost.
- Ten warm and three cold Launch Services samples; ten synthetic warm
  distributed-notification samples; fifteen physical installed snap samples.
- The earlier Shortcut warm/cold measurements are retained as the product
  baseline. Their sample-level raw output was not preserved, so they are
  reported as approximate medians and must not be used for percentile claims.

## Metrics

The direct variants use monotonic timestamps and a shared `run_id`:

- `T0`: `gesture.binding.resolved` in Hold Keys for physical samples;
- `T1`: `semantic_action.transport.started` in Hold Keys;
- `T2`: `semantic_action.received` in Desktop Physics;
- `T3`: `world.spawn.completed` in Desktop Physics.

Reported direct metrics are transport handoff (`T2 - T1`), target command
(`T3 - T2`), and total software latency (`T3 - T0` for physical samples, or
`T3 - T1` for the synthetic transport probe). The evaluation separately records
Shortcuts status UI, target-window churn, foreground preservation, exact object
creation, and human-visible success.

`NSWorkspace` open completion and `/usr/bin/shortcuts` process exit are not the
visual endpoint. They only indicate transport/process completion.

## Run Command

Build and verify the target first:

```bash
./run check
./run demo
```

Then stream the two structured log categories, invoke one sample at a time, and
join events by lowercase `run_id`:

```bash
log stream --style compact \
  --predicate 'category == "ActionLatency"'
```

Warm protocol: keep Desktop Physics running, issue ten serialized actions, and
confirm the object count advances once per joined run. Cold protocol: terminate
Desktop Physics gracefully, keep the same foreground app, issue the action, and
repeat three times. Physical protocol: restore the real single-snap binding,
collect fifteen joined samples, and separately confirm that an object appears
without Shortcuts UI or target-window churn.

## Output Format

The durable join contract is one structured event per line containing:

```json
{"run_id":"<lowercase UUID>","event":"<event name>","monotonic_ns":0,"duration_ms":0}
```

Unified logging was the run artifact. Sample-level logs were intentionally not
committed; the aggregate results and protocol are durable here.

## Good-Enough Criteria

These criteria were fixed after observing the Shortcut baseline and before
accepting the final warm direct route:

- one invocation produces exactly one completed world spawn;
- warm software latency is materially below the approximately 215 ms Shortcut
  baseline;
- no Shortcuts menu-bar status UI appears;
- no Desktop Physics control-window churn occurs while the app is warm;
- cold invocation preserves the previously frontmost app;
- invalid or wrong-bundle semantic URLs fail closed; and
- the saved Shortcut remains available as a compatibility fallback.

## Results

| Candidate and condition | Samples | Measured software result | Interaction result |
|---|---:|---|---|
| Saved Shortcut, warm | prior baseline | about 215 ms median command invocation | Spawn worked; Shortcuts status UI appeared |
| Saved Shortcut, cold | prior baseline | about 1.06 s median command invocation | Spawn worked; Shortcuts status UI appeared |
| Launch Services, warm | 10 | 58.4 ms median `T3 - T1`; 42.2–123.1 ms range | Faster, but reopening the running app caused control-window churn |
| Launch Services, cold | 3 | 714.0 ms median `T3 - T1`; 692.9–947.1 ms range | ChatGPT remained frontmost; accepted as cold fallback |
| Distributed notification, warm synthetic | 10 | 1.494 ms median `T3 - T1`; 1.221–2.495 ms range | No target reopen; target receipt median 1.024 ms and target command median 0.466 ms |
| Hybrid direct action, installed physical snap | 15 | 22.299 ms median `T3 - T0`; 16.513–31.013 ms range | Objects appeared with no Shortcuts indicator and no target-window churn |

For the installed physical samples, the synchronous distributed-notification
post returned after a 20.221 ms median. Target receipt followed the post by about
1.022 ms and the target command took about 0.485 ms. The configured 450 ms
single/double/triple-snap grouping window occurs before `T0` and is therefore not
hidden inside these transport numbers.

The physical verdict establishes that objects appeared and the surrounding UI
remained stable. It does not establish a camera-derived photon-to-photon latency.

## Recommendation / ADR Input

Use the hybrid direct App Action for this local integration:

- distributed notification for the running-app path;
- strict bundle-handler verification plus non-activating Launch Services for
  cold launch; and
- the saved Shortcut as the user-visible compatibility route.

Do not use warm Launch Services merely because its benchmark is faster than
Shortcuts; its window churn fails the interaction criterion. Keep the action
narrow and parameter-free. Distributed notifications are not an authenticated
interprocess protocol, so this is appropriate for the local demo action but not
a general authority-bearing automation bus.

## Reproduction Notes

- Disable Hold Keys' trigger heads-up display for timing comparisons so its draw
  work does not affect one candidate differently; restore it for normal use.
- Use only one installed target copy. Stale DerivedData bundles can register the
  same URL scheme and invalidate handler or cold-start conclusions.
- Confirm the selected URL handler's bundle identifier before every cold series.
- Keep all snap counts and the grouping threshold unchanged across physical
  comparisons. Report grouping latency separately from the post-resolution hop.
- Compare UUIDs case-insensitively if reading older logs; the current sender and
  target normalize `run_id` to lowercase.
- A rerun should save sanitized sample rows under `artifact_root` if percentile
  analysis or regression thresholds become necessary.

## Artifact Policy

Commit summaries and sanitized excerpts. Keep raw private JSONL, transcripts, media, and payload dumps local unless explicitly sanitized.
