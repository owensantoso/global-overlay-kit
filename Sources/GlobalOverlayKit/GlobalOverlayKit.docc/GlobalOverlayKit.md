# ``GlobalOverlayKit``

Host arbitrary native content in transparent, non-activating macOS overlays.

## Overview

GlobalOverlayKit separates operating-system window mechanics from the content
inside the overlay. SwiftUI callers can use the view-builder initializer;
AppKit, SpriteKit, and Metal callers can provide an `NSViewController`.

```swift
let overlay = GlobalOverlay(
    configuration: GlobalOverlayConfiguration(
        frame: CGRect(x: 80, y: 80, width: 520, height: 220),
        interaction: .interactive,
        isMovable: true
    )
) {
    Text("Overlay content")
        .padding()
}

overlay.show()
```

The package does not own application state, render loops, physics, global
keyboard capture, or the meaning of the content being presented.

## Topics

### Creating an overlay

- ``GlobalOverlay``
- ``GlobalOverlayConfiguration``
- ``GlobalOverlayInteraction``

