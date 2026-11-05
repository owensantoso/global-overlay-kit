# Phone world

Owen can scan a QR code in Desktop Physics Demo, place a phone beside an edge of the Mac display, and walk or jump the same character into the phone and back.

This is a usefulness prototype. SpriteKit on the Mac is the sole physics authority. The phone is a camera onto an adjacent rectangle, not another player or simulation. Character identity, velocity, jump state and animation survive crossing. Loose objects remain on the Mac in this slice.

## Surfaces and ownership

- The existing native control window gains a Phone screen section: connect/disconnect, a local QR image, side, alignment and scale. A small diagram shows the actual adjoining rectangles. A reconnect action rotates the pairing capability.
- React and TypeScript own the phone page. `App` owns connection and input lifecycle; `WorldView` owns canvas rendering and viewport measurement; labelled native buttons own touch and keyboard actions. Shared semantic CSS tokens own colour, spacing, focus and disabled states.
- A loopback Node companion serves the built page and relays bounded snapshots and semantic controls. It never reads desktop pixels, window geometry or text. Private Tailscale Serve supplies phone access. The native endpoint requires a separate machine-local secret; the QR fragment grants access to one temporary phone session.
- Pairing is exclusive to one active browser client. Input expires after a missed heartbeat; blur, hidden page, cancellation and disconnection release controls. Disconnection closes the seam and returns an offscreen character safely to the Mac. Layout changes preserve a still-valid position or rescue it.

## Visual direction

Primary purpose: operate and play. The phone opens directly onto the world with a compact connection state above and large Left, Right, Jump and Run controls below. White ground and the shipped black CC0 stick-figure frames retain the native world identity; cyan marks identify the traversable seam. No hero, decorative copy, dropdowns or unrelated app shell.

Native edge choices are visible buttons. Alignment and scale retain native sliders and keyboard operation. Wheel adjustment is declined in the vertically scrolling native controls because scrolling must not change the placement accidentally.

The page continues its background into safe areas, uses at least 16px text inputs if any are added, preserves browser zoom and uses semantic buttons. Rotation updates the phone region through its measured canvas aspect ratio. The controls remain outside the simulated world; the diagram represents the canvas rather than browser chrome.

## Continuity and evidence

Before: the character stops at the Mac boundary. Now: the shared edge opens only while the paired phone is live, and the same native character crosses into the phone rectangle and returns with its velocity intact. No animated handoff or identity replacement occurs. Reduced Motion keeps this same spatial relationship; the phone renders the current authoritative frame.

Verify native boundary geometry, local/remote input merging, stale release, unchanged identity/momentum, layout rescue, pairing rejection and exclusivity. Browser checks cover portrait/landscape canvas, actual React rendering, multi-touch controls, cancellation, hidden-tab release, reconnect, stale native state and console errors. Render the Mac placement diagram and phone page together. A physical iPhone scan, toolbar changes and traversal feel require Owen's check.

Existing Place Game transport is a reference for input cleanup. Its two-participant protocol would introduce a different identity model, so this slice adapts those lifecycle patterns without changing that project. Core Image supplies the native QR code; native controls and the shipped character art are reused.

Structured repository docs remain untouched because the installed Agent Continuity doctor reports v1 migration and owned-tooling drift. This example-local brief records the bounded work without changing those authorities.
