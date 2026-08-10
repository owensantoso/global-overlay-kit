import AppKit
import SwiftUI

/// A transparent, non-activating macOS overlay that hosts arbitrary content.
///
/// `GlobalOverlay` owns native window mechanics only. The caller owns content,
/// state, rendering cadence, input policy, physics, and product semantics.
@MainActor
public final class GlobalOverlay {
    private let panel: NSPanel

    public private(set) var configuration: GlobalOverlayConfiguration

    public init(
        configuration: GlobalOverlayConfiguration,
        contentViewController: NSViewController
    ) {
        var styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel]
        if configuration.isResizable {
            styleMask.insert(.resizable)
        }

        let panel = NSPanel(
            contentRect: configuration.frame,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = contentViewController
        panel.setFrame(configuration.frame, display: false)
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = configuration.hasShadow
        panel.isMovable = configuration.isMovable
        panel.isMovableByWindowBackground = configuration.isMovable
        panel.contentMinSize = configuration.minimumSize
        panel.ignoresMouseEvents = configuration.interaction == .passThrough
        panel.collectionBehavior = Self.collectionBehavior(for: configuration)

        if let accessibilityLabel = configuration.accessibilityLabel {
            panel.setAccessibilityLabel(accessibilityLabel)
        }
        if let frameAutosaveName = configuration.frameAutosaveName {
            panel.setFrameAutosaveName(frameAutosaveName)
        }

        self.configuration = configuration
        self.panel = panel
    }

    /// Convenience for SwiftUI callers. SpriteKit, Metal, and AppKit callers
    /// can use the `NSViewController` initializer directly.
    public convenience init<Content: View>(
        configuration: GlobalOverlayConfiguration,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            configuration: configuration,
            contentViewController: NSHostingController(rootView: content())
        )
    }

    public var isVisible: Bool {
        panel.isVisible
    }

    public var frame: CGRect {
        panel.frame
    }

    /// Shows the overlay without making it the active application window.
    public func show() {
        panel.orderFrontRegardless()
    }

    public func hide() {
        panel.orderOut(nil)
    }

    public func setInteraction(_ interaction: GlobalOverlayInteraction) {
        configuration.interaction = interaction
        panel.ignoresMouseEvents = interaction == .passThrough
    }

    /// Changes the native surface shadow without recreating the overlay.
    public func setHasShadow(_ hasShadow: Bool) {
        configuration.hasShadow = hasShadow
        panel.hasShadow = hasShadow
    }

    public func setFrame(_ frame: CGRect, display: Bool = true) {
        configuration.frame = frame
        panel.setFrame(frame, display: display)
    }

    public func fill(
        _ screen: NSScreen,
        includeMenuBarAndDock: Bool = true,
        display: Bool = true
    ) {
        setFrame(
            includeMenuBarAndDock ? screen.frame : screen.visibleFrame,
            display: display
        )
    }

    private static func collectionBehavior(
        for configuration: GlobalOverlayConfiguration
    ) -> NSWindow.CollectionBehavior {
        var behavior: NSWindow.CollectionBehavior = []
        if configuration.joinsAllSpaces {
            behavior.insert(.canJoinAllSpaces)
        }
        if configuration.appearsAlongsideFullScreenApps {
            behavior.insert(.fullScreenAuxiliary)
        }
        return behavior
    }

    var windowForTesting: NSPanel {
        panel
    }
}
