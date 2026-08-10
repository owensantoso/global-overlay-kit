---
type: idea
id: IDEA-0002
title: Agent-Native Desktop World Sandbox
domain: product
status: exploring
created_at: "2026-08-10 01:02:01 JST +0900"
updated_at: "2026-08-10 01:07:00 JST +0900"
owner:
source:
  type: conversation
  link:
  notes:
areas: [AREA-DESKTOP-PHYSICS, AREA-OVERLAY-HOST]
related_specs: []
related_research: [RSCH-0005, RSCH-0006]
related_issues: []
related_prs: []
related_sessions:
  - 2026-08-10-reusable-desktop-world-and-controls
linked_paths:
  - Examples/DesktopPhysicsDemo
  - Sources/GlobalOverlayKit
promoted_to: []
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# IDEA-0002 - Agent-Native Desktop World Sandbox

## Raw Thought

Explore whether the desktop-physics adapter could become an agent-native
authoring sandbox: a live macOS world that a human can watch and manipulate
while coding agents inspect deterministic world state, receive visual and
telemetry feedback, change behavior, and refresh the running experience with
very little human glue work.

The analogy is React or Expo's fast feedback loop, not necessarily their web
technology. The desired outcome is to close the agent's implementation and
observation loop while keeping the human in control of direction and feel.

## Why It Might Matter

- The user expects agents, not manual coding, to be the main authoring path.
- A visible world plus structured state could give agents faster, less lossy
  feedback than screenshots and prose alone.
- The same substrate could support desktop toys, experiments, agent UI, and
  small games without copying window/physics/input setup each time.
- Data or behavior refresh may deliver most of the useful iteration loop
  without attempting unsafe native Swift hot patching.

## Possible Shape

Proposed, not decided:

- a stable signed macOS host owns overlays, permissions, input, rendering, and
  recovery
- a serializable scene/world document owns entities, shapes, physics profiles,
  controls, and behavior references
- a local command/telemetry interface lets agents inspect, mutate, snapshot,
  reset, and observe the world
- runtime data/assets refresh independently from behavior/script refresh and
  native app rebuild/relaunch
- the human can watch changes live, pause/reset/undo, and provide natural-
  language feedback while the agent iterates

Candidate foundations to compare: native Swift/SpriteKit, a data-driven native
host, a scripting/plugin layer, Godot, a web canvas runtime, or a hybrid.

Compatibility-layer research supports a narrower engine boundary: standardize
host lifecycle, surfaces, input/actions, capture, health, and state transport;
use one adapter per engine and leave scenes/physics/scripts engine-specific.

## Questions

- What is the smallest useful sandbox: scene document plus inspector/commands,
  or a visual editor?
- Which state must be deterministic and serializable for an agent to reason
  about it reliably?
- Can assets, parameters, and behaviors refresh without recompiling Swift?
- When a native rebuild is required, can a supervisor preserve the signed host,
  Accessibility trust, world state, and recovery route?
- What feedback should agents receive: structured telemetry, screenshots,
  video, collision traces, or all of these behind explicit controls?
- Does Swift/SpriteKit remain the right runtime, or only the right first proof?
- Which existing engine/editor already provides enough of this to adapt?
- Can a narrow engine compatibility layer let Godot, Unity, or another runtime
  render through the macOS overlay host without standardizing their scenes,
  physics, or scripting APIs?
- Which integration boundary is viable: engine-owned transparent window,
  embedded native render view/child window, or separate-process frame/texture
  transport into the stable signed host?
- How do undo, crash isolation, permission boundaries, and human takeover work?

## Promotion Criteria

- Research must separate asset/data refresh, script/behavior refresh, and native
  code rebuild rather than calling all three “hot reload.”
- A one-session prototype must show an agent changing a running world through a
  documented interface, observing the result, and recovering from a bad change.
- The chosen runtime must preserve the stable native overlay/permission host or
  provide a clearly better substitute.
- A concrete second authoring use must validate the abstraction before this is
  promoted into a general engine roadmap.
