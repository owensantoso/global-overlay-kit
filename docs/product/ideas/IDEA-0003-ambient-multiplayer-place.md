---
type: idea
id: IDEA-0003
title: Ambient Multiplayer Place
domain: product
status: exploring
created_at: "2026-08-10 05:55:24 JST +0900"
updated_at: "2026-08-10 06:06:13 JST +0900"
owner:
source:
  type: conversation
  link:
  notes: Desktop Multiplayer Presence concept and mockup discussion
areas: [AREA-OVERLAY-HOST, AREA-DESKTOP-PHYSICS]
related_specs: []
related_research: [RSCH-0005, RSCH-0006]
related_issues: []
related_prs: []
related_sessions: []
linked_paths: []
promoted_to: []
repo_state:
  based_on_commit:
  last_reviewed_commit:
---

# IDEA-0003 - Ambient Multiplayer Place

## Raw Thought

Create an ambient multiplayer social place that can remain present while people
use their computers. It is not primarily a game window or messenger window: it
is a small shared world where a person's character, availability, visitors,
interactions, and lightweight messages remain visible around ordinary work.

The default desktop expression is a shallow stage at the bottom of the screen.
The same social place should remain reachable from macOS, Windows, iPhone,
Android, and the browser, including a low-friction Chrome-extension surface.

Confirmed product constraints from the user:

- The experience is intended to stay on all day, so negligible idle battery
  and performance impact is a core requirement, not later optimization.
- Presence is user-controlled. At minimum, the product must distinguish being
  online, busy, unavailable, and open or closed to spontaneous visitors.
- Cross-platform reach is core: macOS, Windows, iPhone, Android, and Chrome or
  the wider web should connect to the same social place.
- Platform expressions do not yet need to be visually or mechanically
  identical; what must be shared is the place, presence, and social continuity.
- The desktop experience needs a polished, legible transition from its default
  flat bottom strip into a 2.5D or 3D world with usable Z-depth. This is a
  defining interaction, not an optional visual flourish.

## Why It Might Matter

- A persistent peripheral world could make remote presence feel continuous
  without demanding another foreground conversation.
- A Chrome path could make joining nearly instant for people unwilling to
  install a desktop app.
- Device-independent identity and place state would let someone remain present
  while moving between desktop, mobile, and browser surfaces.
- Treating energy use as a product contract makes the idea viable as social
  infrastructure rather than a novelty that users close after an hour.

## Possible Shape

Proposed, not decided:

- Keep a renderer-neutral shared model for identity, place membership,
  presence, semantic actions, messages, and durable world state.
- Treat each operating system as a host surface with its own lifecycle,
  permission, and rendering adapter rather than requiring one engine binary to
  behave identically everywhere.
- Use an event-driven render lifecycle: no continuous rendering or physics when
  hidden or unchanged; low-rate or change-only updates for static presence; a
  temporary interactive frame rate only while characters are moving.
- Evaluate a TypeScript world model and Canvas/WebGL renderer as the leading
  cross-platform hypothesis because it maps naturally to Chrome and can run in
  native webviews on desktop. React or Expo may own application interface and
  mobile shells without owning the per-frame sprite loop.
- Preserve the existing native Swift/SpriteKit implementation as the macOS
  performance and integration control. Do not rewrite it before measurement.
- Treat Godot as the leading world-renderer hypothesis now that the flat-to-depth
  transition is a core interaction. One real 3D scene can begin under a
  front-facing orthographic camera with characters compressed onto a shallow
  depth plane, then animate the camera, floor, props, and character depth into
  the expanded perspective view without swapping worlds. Battery behavior,
  Chrome-extension packaging, and platform-shell integration still need
  evidence before this becomes a durable engine decision.
- Keep the default characters compatible with 2D artwork by presenting them as
  camera-facing sprites inside the 3D world; true 3D models can remain optional.
- On desktop, native hosts should own transparent-window behavior, permissions,
  recovery, and operating-system integration even if a shared web renderer owns
  the world pixels.

## Questions

- What exact idle central-processing-unit, graphics-processing-unit, memory,
  wakeup, and network budgets qualify as “leave it on all day”?
- Does a native SpriteKit renderer, a system-webview Canvas/WebGL renderer, or a
  Godot low-processor export have the best measured idle and active energy use
  for the same scene?
- Should the collapsed strip be a true orthographic view of the 3D world, a
  deliberately flattened perspective view, or a short crossfade from a 2D
  render target onto the opening 3D floor? The first option promises the least
  visible identity swap, but needs a motion prototype.
- Which state is truly shared across every surface, and which interactions are
  desktop-only?
- What is the honest mobile expression when iOS cannot maintain a continuously
  rendered overlay above other apps and Android requires special overlay
  permission for the closest equivalent?
- Should the browser surface live inside each page, in extension-owned browser
  interface, or both? It cannot cover browser chrome or other applications like
  a desktop overlay.
- Can one TypeScript package serve the web renderer, Chrome extension, desktop
  webviews, and Expo application logic without coupling authoritative state to
  React components or one platform shell?
- Should richer physics be simulated locally only while visible, or resolved by
  an authoritative shared world service?

## Promotion Criteria

- Define a shared place and presence model that does not depend on one renderer.
- Build one equivalent representative scene in the strongest native, web, and
  Godot candidates and measure idle, static-presence, and interaction phases on
  the same Mac before choosing a universal runtime.
- Demonstrate the web candidate inside both the native macOS overlay host and a
  Chrome content-script surface.
- Prototype the exact collapsed-strip-to-depth transition with persistent
  character identities and verify that no sprite visibly pops, changes scale,
  or changes position at the handoff.
- Define platform-specific product promises for macOS, Windows, iPhone,
  Android, and Chrome without pretending all five permit the same overlay.
- Promote the confirmed user-visible behavior to a dedicated product spec only
  after this idea has a product repository or explicit ownership boundary;
  GlobalOverlayKit itself must remain a renderer-neutral macOS host library.
