# Phone world

Owen can scan one QR code from several phones, arrange their screens by dragging them on the Mac, and walk or jump the same character between adjoining screens.

This is a usefulness prototype. SpriteKit on the Mac is the sole physics authority. Each phone is a camera onto one rectangle in the same world. Character identity, velocity, jump state and animation survive crossing. Loose objects remain on the Mac. Owen confirmed the single-phone round trip on 2026-11-05: “yeah it works, i can go into the phone and back.” PR #1 was merged after that acceptance; multiple-phone arrangement is the next unaccepted slice.

## Surfaces and ownership

- The native Phone screen window contains the QR, connection state, and a draggable arrangement canvas. Mac is a fixed anchor; each phone has a stable numbered label matching its browser. Dragging previews a placement; release snaps a screen to a compatible edge of the Mac or another phone. Invalid overlaps or disconnected drops revert. The transform stays fixed during a drag. Selection exposes a corner resize handle, scale slider, quarter-turn control, and keyboard movement. Resize previews use the same transactional reflow as committing the scale; dependent screens preview their new positions too. Direction/alignment buttons and their explanatory copy are removed.
- React and TypeScript own the phone page. `App` owns connection and input lifecycle; `WorldView` owns canvas rendering and viewport measurement; labelled native buttons own touch and keyboard actions. Shared semantic CSS tokens own colour, spacing, focus and disabled states.
- A loopback Node companion serves the page and relays bounded snapshots and semantic controls. Private Tailscale Serve supplies phone access. The native endpoint has separate machine-local authorization. The QR grants access to this temporary shared session; each browser receives its own stable screen identity. Pairing is bounded to eight screen slots.
- The connected world is a non-overlapping graph of edge-touching rectangles rooted at the Mac. Shared openings connect phone to phone as well as Mac to phone. A removed or stale middle screen makes its downstream component inactive until reattached. Inactive screens stay identifiable in the layout; their phone page explains that its screen needs connecting. A character stranded by removal returns safely to Mac with its identity preserved.
- Each phone has its own request sequence and 400 ms input expiry. Live controls merge into one character: opposing directions cancel. Blur, hidden pages and pointer cancellation release only that phone's input. Browser orientation changes the measured viewport; an explicit 0/90-degree view turn swaps world dimensions and rotates the phone canvas to match. The movement controls remain upright and use world directions. Resizing and turning preserve attachment when possible; invalidated placement needs reattachment rather than overlapping a neighbour.

## Visual direction

Primary purpose: operate and play. The phone opens directly onto the world with a compact connection state above and large Left, Right, Jump and Run controls below. White ground and the shipped black CC0 stick-figure frames retain the native world identity; cyan marks identify the traversable seam. No hero, decorative copy, dropdowns or unrelated app shell.

The canvas shows the topology directly: labelled screens, selected screen, snapped edge openings, and a ghost during a drag. Connected and inactive states have visible text as well as colour. Native drag and resize gestures, a selected-screen scale slider and Rotate view control adapt the existing SwiftUI surface; no component package is needed. Wheel adjustment remains declined in the scrolling controls. The canvas uses fixed committed bounds throughout a drag so its content does not move under the pointer. One QR joins additional phones without evicting earlier ones; resetting the session explicitly retires all pairings.

The page continues its background into safe areas, uses at least 16px text inputs if any are added, preserves browser zoom and uses semantic buttons. Rotation updates the phone region through its measured canvas aspect ratio. The controls remain outside the simulated world; the diagram represents the canvas rather than browser chrome.

## Continuity and evidence

Before: the character stops at the Mac boundary. Now: the shared edge opens only while the paired phone is live, and the same native character crosses into the phone rectangle and returns with its velocity intact. No animated handoff or identity replacement occurs. Reduced Motion keeps this same spatial relationship; the phone renders the current authoritative frame.

Verify a Mac → Phone 1 → Phone 2 → Phone 1 → Mac round trip using one identity and elapsed physics; pairwise boundary subtraction, reachable height changes, stale per-phone input, reconnect and middle-screen loss. Exercise dragging, resize previews, invalid drops, keyboard adjustment, scale and quarter-turns in the actual native canvas. An edit cancels when its source screen changes or disappears, and Escape cannot poison the next gesture. Browser tests use simultaneous isolated clients and confirm each receives its own viewport and matching screen label, with no input or identity swap. Physical multiple-phone traversal, browser chrome and interaction feel need Owen's check.

Existing Place Game transport is a reference for input cleanup. Its two-participant protocol would introduce a different identity model, so this slice adapts those lifecycle patterns without changing that project. Core Image supplies the native QR code; native controls and the shipped character art are reused.

Structured repository docs remain untouched because the installed Agent Continuity doctor reports v1 migration and owned-tooling drift. This example-local brief records the bounded work without changing those authorities.
