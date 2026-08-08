import AppKit

/// Controls the native macOS surface without prescribing what it renders.
public struct GlobalOverlayConfiguration {
    public var frame: CGRect
    public var minimumSize: CGSize
    public var interaction: GlobalOverlayInteraction
    public var isMovable: Bool
    public var isResizable: Bool
    public var joinsAllSpaces: Bool
    public var appearsAlongsideFullScreenApps: Bool
    public var hasShadow: Bool
    public var accessibilityLabel: String?
    public var frameAutosaveName: String?

    public init(
        frame: CGRect,
        minimumSize: CGSize = CGSize(width: 1, height: 1),
        interaction: GlobalOverlayInteraction = .passThrough,
        isMovable: Bool = false,
        isResizable: Bool = false,
        joinsAllSpaces: Bool = true,
        appearsAlongsideFullScreenApps: Bool = true,
        hasShadow: Bool = false,
        accessibilityLabel: String? = nil,
        frameAutosaveName: String? = nil
    ) {
        self.frame = frame
        self.minimumSize = minimumSize
        self.interaction = interaction
        self.isMovable = isMovable
        self.isResizable = isResizable
        self.joinsAllSpaces = joinsAllSpaces
        self.appearsAlongsideFullScreenApps = appearsAlongsideFullScreenApps
        self.hasShadow = hasShadow
        self.accessibilityLabel = accessibilityLabel
        self.frameAutosaveName = frameAutosaveName
    }

    /// A fixed overlay that covers one display. The caller still owns the
    /// renderer, simulation, input, and response to later display changes.
    @MainActor
    public static func screenFilling(
        _ screen: NSScreen,
        includeMenuBarAndDock: Bool = true,
        interaction: GlobalOverlayInteraction = .passThrough
    ) -> Self {
        Self(
            frame: includeMenuBarAndDock ? screen.frame : screen.visibleFrame,
            interaction: interaction
        )
    }
}

public enum GlobalOverlayInteraction: Sendable {
    /// Pointer events continue to the application underneath the overlay.
    case passThrough

    /// The overlay can receive pointer events.
    case interactive
}

