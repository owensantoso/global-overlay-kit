# GlobalOverlayKit

GlobalOverlayKit is an early macOS Swift package for placing arbitrary native
content above other applications without forcing that content to become a chat
window, game engine, or SwiftUI-only component.

The public promise is a **global overlay**. Internally, macOS implements that
surface with AppKit windows and panels, which is why window terminology appears
in lower-level architecture and source code.

> Status: initial architecture, buildable API, and a runnable signed SpriteKit
> physics example. Automated tests cover the configured window contract and
> desktop-world adapter. Balls, shapes, cursor collision, and player controls
> have positive physical evidence on one Mac; drag mode, Spaces, full-screen
> apps, and multiple displays still require physical validation.

## What it owns

- Transparent, floating native macOS surfaces.
- Non-activating presentation.
- All-Spaces and full-screen auxiliary behavior.
- Click-through or interactive pointer handling.
- Fixed, movable, resizable, restored, or screen-sized placement primitives.
- Arbitrary AppKit content, with a SwiftUI convenience initializer.

## What it does not own

- Message models or chat rendering.
- Physics, animation, or render loops.
- SpriteKit, Metal, or pixel-engine state.
- Global keyboard capture.
- Speech, agents, or application-specific actions.

Those boundaries allow the same substrate to host an ambient message stack, a
SpriteKit desktop world, a HUD, a teleprompter, or a custom Metal renderer.

## Package use

Before the first tagged release, Swift Package Manager consumers can track the
main branch:

```swift
.package(
    url: "https://github.com/owensantoso/global-overlay-kit.git",
    branch: "main"
)
```

Create an overlay from SwiftUI:

```swift
import GlobalOverlayKit
import SwiftUI

@MainActor
func makeOverlay() -> GlobalOverlay {
    GlobalOverlay(
        configuration: GlobalOverlayConfiguration(
            frame: CGRect(x: 80, y: 80, width: 520, height: 220),
            interaction: .interactive,
            isMovable: true,
            isResizable: true,
            accessibilityLabel: "Example overlay"
        )
    ) {
        Text("Hello from above your other apps")
            .padding()
    }
}
```

SpriteKit, Metal, and ordinary AppKit callers can instead provide any
`NSViewController`.

## Try the desktop physics example

From the repository root:

```bash
./run demo
```

The command builds and launches a stable Apple Development-signed app. It opens
a normal control window and a transparent, display-sized SpriteKit overlay.
Choose circles, squares, or triangles with continuous or randomized size
ranges; resize and enable cursor collision; or spawn an animated stick figure
or geometric player with WASD, arrow, or combined controls. Walk with the
selected movement keys, hold Shift to run, jump with W/Up/Space, press C to
sit, hold Down/S and press Jump to drop through every coincident platform edge
at the player's feet, and hold toward a screen edge while falling to slide and
wall-jump.
Optional drag mode lets spawned objects follow the pointer; flicking throws
them, while pausing before release drops them. Only a draggable object or
player hit region temporarily captures the pointer; empty desktop remains
click-through throughout the mode.

Global movement controls are off by default. Turning them on explicitly asks
for macOS Accessibility access, then captures only the chosen movement keys,
Space, C, and gameplay Shift. Command-, Control-, Option-, and Function-modified
shortcuts—including Command-Tab—always pass through. Use the visible button,
the Dock, or Command-0 to recover the control window.

The first example deliberately uses SpriteKit's built-in gravity and collision
system. Physics stays in the consumer; GlobalOverlayKit only hosts its
`NSViewController`.

For bounded position, velocity, and resting-state samples after each spawn:

```bash
./run demo-trace
```

The trace runs for eight seconds after the latest spawn and prints at most six
objects/player samples. It is opt-in so ordinary demo use stays quiet.

## Development

```bash
./run check
```

`./run check` also tests the nested `DesktopPhysicsKit` library and builds the
signed app consumer so both package seams cannot silently drift.

Start with [the current-state document](docs/orientation/CURRENT_STATE.md), then
read [the architecture](docs/orientation/ARCHITECTURE.md) and
[research](docs/research/README.md). The repository uses the complete Agent
Continuity documentation scaffold so decisions and evidence survive beyond one
chat or contributor.

## License

GlobalOverlayKit is available under the [MIT License](LICENSE).
The nested physics example also bundles selected CC0 stick-figure animation
frames; their source and license are retained beside those resources.
