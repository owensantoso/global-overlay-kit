# DesktopPhysicsKit example

This nested package is the reusable desktop-world layer built on top of
GlobalOverlayKit and SpriteKit. It is intentionally not part of
GlobalOverlayKit's renderer-neutral API.

```swift
import DesktopPhysicsKit

let world = DesktopPhysicsWorld(screen: screen)
world.show()
world.spawn(.init(shape: .triangle, size: .large))
world.setCursorCollisionEnabled(true)
world.setObjectDraggingEnabled(true)
try world.setWindowPlatformsEnabled(true)
world.spawnPlayer(appearance: .stickFigure)
try world.setControlsEnabled(true)
```

`DesktopPhysicsWorld` owns the ordinary overlay/scene setup, shape bodies,
cursor mapping, player, and selective input lifecycle. SpriteKit remains the
physics engine. The caller still owns its visible controls, Accessibility
permission explanation, and product behavior.

From the repository root, use `./run demo` to build and launch the stable
signed app. Global controls are off by default and require an explicit
Accessibility grant. Cursor collision stays click-through. Explicit object
drag mode can move either a loose object or the player. The scene marks those
roots as draggable and captures pointer input only while the cursor overlaps
one of their visual hit regions or while a drag is already active. Empty
desktop remains click-through. Release velocity is derived from recent motion,
so a flick throws while a stationary release drops.

Down/S plus Jump drops the player through the current support height. The
temporary exclusion applies to every coincident visible-window edge at that
height and remains active until the previous physics frame is fully below the
landing tolerance, so overlapping windows and the original edge cannot catch
the player again.

The optional **Use app windows as platforms** mode is backed by canonical
`DesktopSurfaceKit` window observation plus the narrow
`MacDesktopWindowGeometry` product adapter. Core Graphics supplies stable-
enough window IDs and frames; Accessibility is an explicit product fail-off
gate shared with the global-control permission flow. Loose objects collide
with each remaining visible rectangle. The player ignores those bodies and can
land from above on a visible original top or bottom edge while still jumping
through either edge from below. A separate switch makes only visible original
left/right edges into two-sided player walls. Occlusion-cut edges never become
player surfaces, and moving geometry cannot squish the character.

For this testing build, **Show platform outlines** starts on. Each cyan outline
is a visible rectangle used for loose-object collision; thicker capped yellow
top/bottom edges are one-way player surfaces. The control can hide these
visuals without disabling collision. **Game world mode** independently fades
an opaque white backdrop over the selected desktop area and presents enabled
player platforms/walls as black lines; reversing the switch reverses the same
transition, and Reduce Motion applies the complete end state immediately.

This mode is still experimental. Covered portions are removed through
front-to-back rectangular subtraction, while rounded corners, translucency,
and irregular window shapes remain approximations. A new or moving fragment
can still eject a loose object that it overlaps. Live window motion, outline
tracking/visibility, occlusion expectations, current-Space filtering, and
secondary-display behavior still need signed-app physical checks.

The design originated in the historical non-git `DesktopSurfaceKit` gaze POC;
that dated copy is neither a dependency nor a source of truth. The reusable
window-observation contract now lives in the canonical version-controlled
`DesktopSurfaceKit` repository, while this package retains only product-
specific permission, coordinate, and physics policy. See
[RSCH-0008](../../docs/research/RSCH-0008-macos-window-geometry-reuse-readiness.md).

The consumer pins private `DesktopSurfaceKit` `0.1.0-rc.3`. Its rectangular
front-to-back subtraction removes fully covered window regions. Cyan outlines
show the remaining object colliders; yellow lines show only genuinely visible
source-window top and bottom edges used as one-way landing platforms by the
character. Each fragment now carries its source window, compact front-to-back
index, and surviving original `minX`/`maxX`/`minY`/`maxY` sides directly.
Rounded corners and translucent pixels remain an explicit approximation
boundary.

The normal Release build is installed at
`~/Applications/Desktop Physics Demo.app` with an Apple Development signature.
It remains a regular Dock app: closing the control window does not stop the
desktop world, and reopening the app recreates the control window in the same
process. The executable target—not `DesktopPhysicsKit`—owns App Intents and the
strict `owensantoso-desktopphysics://spawn/random-object` App Action adapter.

The default player uses selected CC0-authored stick-figure frames by Raphael
Gonçalves (`rgsdev`). It has distinct idle, walk, run, jump, wall-slide, and
sit poses with left/right mirroring. Source and license provenance live beside
the bundled frames under `Resources/StickFigureCC0`.
Choose WASD, arrows, or both. Spacebar jump can be disabled independently, so
WASD-only and arrow-only play are available. Hold Shift to run farther during
a jump; vertical jump height is unchanged. Jump again in the air for one double
jump. Hold S/Down and press Jump to drop through only the supporting window
edge. With window sides enabled, double-tap toward a wall and hold the second
press for a short wall run; an ordinary wall slide and wall jump remain. The
player can leave the scene above the screen and fall back into view. C toggles
sitting.

Godot portability is specified separately rather than by leaking SpriteKit
types. The proposed first adapter is a signed Swift helper that imports
DesktopSurfaceKit and streams a versioned NDJSON snapshot feed to a Godot
add-on. A local pipe probe passed, but collider implementation is deliberately
gated on a verified Quartz-to-Godot mapping because the current Retina display
reports 2x pixel geometry in Godot. See
[ADR-0004](../../docs/decisions/adr/ADR-0004-bridge-desktopsurfacekit-to-godot-through-a-versioned-snapshot-feed.md)
and [EXPL-0002](../../docs/orientation/explainers/EXPL-0002-godot-desktop-window-feed-contract.md).

Run library tests directly with:

```bash
swift test --package-path Examples/DesktopPhysicsDemo
```

The target stays nested and unreleased until a second real consumer validates
the API. It should not become a separate engine repository merely because the
first demo works.
