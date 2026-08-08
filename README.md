# GlobalOverlayKit

GlobalOverlayKit is an early macOS Swift package for placing arbitrary native
content above other applications without forcing that content to become a chat
window, game engine, or SwiftUI-only component.

The public promise is a **global overlay**. Internally, macOS implements that
surface with AppKit windows and panels, which is why window terminology appears
in lower-level architecture and source code.

> Status: initial architecture and buildable API. Automated tests cover the
> configured window contract; focus preservation, Spaces, full-screen apps,
> multiple displays, and real interaction still require physical validation.

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

## Development

```bash
./run check
```

Start with [the current-state document](docs/orientation/CURRENT_STATE.md), then
read [the architecture](docs/orientation/ARCHITECTURE.md) and
[research](docs/research/README.md). The repository uses the complete Agent
Continuity documentation scaffold so decisions and evidence survive beyond one
chat or contributor.

## License

GlobalOverlayKit is available under the [MIT License](LICENSE).

