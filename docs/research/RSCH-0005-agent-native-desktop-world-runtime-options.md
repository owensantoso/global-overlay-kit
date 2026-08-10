---
type: research-survey
id: RSCH-0005
title: Agent-Native Desktop World Runtime Options
domain: research
status: completed
created_at: "2026-08-10 01:13:19 JST +0900"
updated_at: "2026-08-10 01:13:19 JST +0900"
owner:
question: What is the smallest useful runtime architecture for agents to inspect, change, run, and observe a macOS desktop world with fast feedback?
source:
  type: conversation
  link:
  notes:
external_sources:
  - https://docs.godotengine.org/en/stable/tutorials/scripting/debug/overview_of_debugging_tools.html
  - https://github.com/satelliteoflove/godot-mcp
  - https://docs.expo.dev/develop/development-builds/use-development-builds/
  - https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements
  - https://vite.dev/guide/features.html
repo_findings:
  - The unique gap is the stable permission-safe macOS desktop-as-world host, not a new general game editor.
  - Data and behavior reload can occur above Swift while native host rebuilds remain a separate slower loop.
agent_notes:
  - Evaluate existing Godot agent tooling before building an editor or scripting system.
related_ideas: [IDEA-0002]
related_evaluations: []
related_adrs: [ADR-0001, ADR-0002]
related_specs: [SPEC-0002]
related_plans: [PLAN-0003]
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
linked_paths:
  - Sources/GlobalOverlayKit
  - Examples/DesktopPhysicsDemo
repo_state:
  based_on_commit: 102cac2110afa282633706e80a33c3a60265cc25
  last_reviewed_commit: 102cac2110afa282633706e80a33c3a60265cc25
---

# RSCH-0005 - Agent-Native Desktop World Runtime Options

## Question

What is the smallest useful runtime architecture for agents to inspect, change,
run, and observe a macOS desktop world with fast feedback?

## Context

The desired outcome is not primarily a manual game editor. Coding agents should
be able to inspect structured live state, change a world, observe visual and
runtime consequences, recover from bad changes, and keep the human focused on
direction and feel.

## External Sources

- Godot provides [remote debugging and inspection](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/overview_of_debugging_tools.html).
- Community [godot-mcp](https://github.com/satelliteoflove/godot-mcp) already
  exposes freeze/step, structured state, input, screenshots, and profiling to
  agents through the Model Context Protocol (MCP).
- Expo documents the distinction between a stable
  [native development build and reloadable JavaScript/assets](https://docs.expo.dev/develop/development-builds/use-development-builds/).
- Apple's [code-signing requirement guidance](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)
  explains why the permission-owning Mac host needs a stable identity.
- Vite supplies web-runtime [Hot Module Replacement](https://vite.dev/guide/features.html).

## Repo / Internal Findings

- GlobalOverlayKit already provides the renderer-neutral native surface.
- DesktopPhysicsKit is a useful SpriteKit proof but lacks a serializable world
  definition, stable entity IDs, seeded randomness, snapshots, command queue,
  pause/step, undo, capture, and agent-facing protocol.
- Native Swift has incremental rebuild/relaunch, not a production-grade React
  Fast Refresh equivalent. An Expo-like loop is possible when the reloadable
  boundary is data, scripts, or a child runtime above the stable signed host.

## Agent Notes

## Options Compared

1. Code-driven SpriteKit: best current native proof, weakest authoring loop.
2. Data-driven SpriteKit: cheapest falsification experiment for agent commands,
   state, capture, and parameter reload without Swift rebuilds.
3. Godot runtime/editor: strongest existing full sandbox and agent-tooling
   candidate; unique overlay behavior still requires a Mac spike.
4. AppKit plus `WKWebView`/Canvas/Vite: closest Expo-style fallback if Godot
   cannot satisfy transparent desktop-window behavior.
5. Swift dynamic plugins/code injection: rejected initially because signing,
   hardened runtime, ABI, and crash-containment costs are disproportionate.

## Findings

“Hot reload” is three separate loops:

- assets/data: reload validated world files without rebuilding
- scene/behavior: reload scripts or behavior presets in the runtime
- native Swift: snapshot, disable controls, rebuild/relaunch the signed host,
  and restore state

The smallest useful product is an agent-native desktop-world runner, not a
GameMaker clone: stable control app, versioned world document, local `worldctl`
command-line interface, structured snapshots, transactional patches, capture,
pause/reset/undo, and last-known-good recovery.

## Risks / Unknowns

- Godot's transparent window must physically prove nonactivation, all Spaces,
  full-screen auxiliary behavior, click-through, and stable permission bridging.
- SpriteKit cannot provide exact manual deterministic physics stepping.
- A cross-engine abstraction created before the Godot/WebKit spikes would be
  speculation.

## Recommendation

Adapt today, adopt before building tomorrow:

- keep current DesktopPhysicsKit narrow and fix its concrete controller
- first prove a data-driven SpriteKit `worldctl` loop
- then evaluate Godot plus existing agent tooling against the unique macOS
  overlay acceptance matrix
- use AppKit plus WebKit/Vite only if Godot's window model fails
- do not build a visual editor, entity-component system, scripting language, or
  general renderer protocol yet

## Follow-Ups

1. Agent edits a JSON world, applies it live, reads state, and captures a result.
2. Make controller parameters reloadable without Swift compilation.
3. Recreate only falling shapes/player in Godot and test overlay behavior plus
   agent freeze/step/state/screenshot.
4. Run a WebKit/Vite fallback spike only if the Godot surface fails.
