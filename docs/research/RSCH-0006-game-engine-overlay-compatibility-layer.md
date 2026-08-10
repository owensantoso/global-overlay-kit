---
type: research-survey
id: RSCH-0006
title: Game Engine Overlay Compatibility Layer
domain: research
status: completed
created_at: "2026-08-10 01:22:45 JST +0900"
updated_at: "2026-08-10 01:22:45 JST +0900"
owner:
question: Can GlobalOverlayKit host Godot, Unity, Bevy, or other engines through a reusable compatibility boundary instead of building a new engine?
source:
  type: conversation
  link:
  notes:
external_sources:
  - https://docs.godotengine.org/en/stable/classes/class_displayserver.html
  - https://github.com/migeran/libgodot
  - https://docs.unity3d.com/6000.0/Documentation/Manual/UnityasaLibrary.html
  - https://docs.rs/bevy/latest/bevy/window/struct.Window.html
  - https://docs.rs/bevy/latest/bevy/remote/index.html
  - https://developer.apple.com/documentation/iosurface
  - https://developer.apple.com/documentation/metal/mtlsharedtexturehandle
repo_findings:
  - A shared lifecycle/surface/input/capture contract is feasible, but each engine needs its own adapter.
  - Godot is the strongest first spike; Unity has no supported macOS Unity-as-a-Library route.
  - Stable host-owned Accessibility input must be forwarded as named actions rather than delegated to engine processes.
agent_notes:
  - Do not standardize scenes, entities, rigid bodies, scripts, or animations across engines.
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

# RSCH-0006 - Game Engine Overlay Compatibility Layer

## Question

Can GlobalOverlayKit host Godot, Unity, Bevy, or other engines through a
reusable compatibility boundary instead of building a new engine?

## Context

The project owner is new to game-engine internals and proposed a compatibility
layer as a possible alternative to reimplementing engine capabilities. The
decision must distinguish a realistic rendering/lifecycle bridge from an
impossible universal translation of engine concepts.

## External Sources

- Godot exposes native window handles and transparent/window behavior through
  [`DisplayServer`](https://docs.godotengine.org/en/stable/classes/class_displayserver.html).
- Experimental [LibGodot](https://github.com/migeran/libgodot) demonstrates a
  host supplying a Metal layer and driving Godot as a library.
- [Unity as a Library](https://docs.unity3d.com/6000.0/Documentation/Manual/UnityasaLibrary.html)
  does not support macOS desktop.
- Bevy exposes transparent/topmost/pointer policy in its
  [window API](https://docs.rs/bevy/latest/bevy/window/struct.Window.html) and
  structured mutation through the [Bevy Remote Protocol](https://docs.rs/bevy/latest/bevy/remote/index.html).
- Apple supports cross-process graphics through
  [`IOSurface`](https://developer.apple.com/documentation/iosurface) and
  [shared Metal texture handles](https://developer.apple.com/documentation/metal/mtlsharedtexturehandle).

## Repo / Internal Findings

An engine is a loop that updates a simulated world and paints frames. Three
integration routes are materially different:

1. engine-owned transparent native window
2. engine library rendering into a host-owned AppKit/Metal surface
3. separate engine process sharing rendered textures with the stable host

The compatibility layer can standardize capabilities, lifecycle, surface
geometry/alpha/scale, input policy, named actions, pause/step/reload/reset,
capture, health, logs, state events, and crash recovery. It cannot honestly
standardize every engine's scenes, entities, physics, scripts, or animation.

## Agent Notes

## Options Compared

| Engine | Engine-owned overlay | Host-owned embedded surface | Isolated shared texture |
|---|---|---|---|
| Godot 4.6 | Strong cheapest spike through native `NSWindow` handle | Credible but experimental through LibGodot/`CAMetalLayer` | Possible but substantial |
| Unity 6 | Possible only through brittle native plug-in work | No supported macOS library embedding | Possible but expensive engine-specific rendering plug-in |
| Bevy 0.19 | Strong transparent/fallthrough primitives | Possible custom Rust/Metal bridge | Possible and open source, but custom |

Godot is the best first adapter because it combines public native handles,
transparent window support, experimental library mode, scene/script reload,
remote inspection, and existing agent tools. Unity should be last because its
supported library embedding excludes macOS. Bevy is the best open-source second
adapter to test whether a shared host contract is real.

## Findings

The idea is feasible as one host contract plus engine-specific adapters. The
stable Apple-signed host should remain the only Accessibility owner and forward
named actions to engines. In-process embedding has the cleanest window behavior
but shares crash fate; a shared-texture child process preserves host/permission
continuity at the cost of synchronization and up to roughly one frame of
latency.

## Risks / Unknowns

- A normal engine `NSWindow` may not match a nonactivating `NSPanel` exactly.
- LibGodot is experimental and macOS AppKit embedding needs a physical spike.
- Cross-process texture sharing needs alpha correctness, Retina resize,
  graphics synchronization, input forwarding, and watchdog recovery.
- A supposed generic adapter may collapse into unrelated per-engine forks.
- Unity licensing/version behavior makes it a poor first proof.

## Recommendation

Start with a separate Godot engine-owned-window spike: transparent bouncing
objects, a tiny Objective-C++ extension using the public native handle, and the
full overlay behavior matrix. If only nonactivation fails, try LibGodot
rendering into a `CAMetalLayer` owned by GlobalOverlayKit. Use Bevy as the second
adapter proof. Do not touch Unity until the contract survives both.

The conceptual adapter boundary is:

```text
capabilities
start / stop / restart / health
surface = ownedWindow | hostMetalLayer | sharedTexture
geometry / scale / alpha / input policy
named actions / engine-specific commands
pause / step / reload / reset / capture
logs / state events / crash events
```

## Follow-Ups

- Create a separate Godot spike rather than refactoring DesktopPhysicsKit.
- Reject the generic layer if exact overlay behavior needs private APIs, engine
  source forks, CPU frame copies, engine-owned Accessibility, or if a second
  adapter shares only method names rather than meaningful lifecycle behavior.
