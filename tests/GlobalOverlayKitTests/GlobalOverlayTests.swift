import AppKit
import Testing
@testable import GlobalOverlayKit

@MainActor
@Test("Overlay construction applies passive global-window mechanics")
func overlayConstructionAppliesWindowMechanics() {
    _ = NSApplication.shared
    let configuration = GlobalOverlayConfiguration(
        frame: CGRect(x: 40, y: 50, width: 320, height: 180),
        interaction: .passThrough,
        joinsAllSpaces: true,
        appearsAlongsideFullScreenApps: true,
        accessibilityLabel: "Test overlay"
    )
    let overlay = GlobalOverlay(
        configuration: configuration,
        contentViewController: NSViewController()
    )

    #expect(overlay.windowForTesting.level == .floating)
    #expect(overlay.windowForTesting.isOpaque == false)
    #expect(overlay.windowForTesting.backgroundColor == .clear)
    #expect(overlay.windowForTesting.ignoresMouseEvents)
    #expect(overlay.windowForTesting.collectionBehavior.contains(.canJoinAllSpaces))
    #expect(overlay.windowForTesting.collectionBehavior.contains(.fullScreenAuxiliary))
}

@MainActor
@Test("Interaction can change without recreating the overlay")
func interactionCanChangeInPlace() {
    _ = NSApplication.shared
    let overlay = GlobalOverlay(
        configuration: GlobalOverlayConfiguration(
            frame: CGRect(x: 0, y: 0, width: 200, height: 120)
        ),
        contentViewController: NSViewController()
    )

    overlay.setInteraction(.interactive)

    #expect(overlay.configuration.interaction == .interactive)
    #expect(overlay.windowForTesting.ignoresMouseEvents == false)
}

@MainActor
@Test("Frame updates preserve one overlay instance")
func frameUpdatesInPlace() {
    _ = NSApplication.shared
    let overlay = GlobalOverlay(
        configuration: GlobalOverlayConfiguration(
            frame: CGRect(x: 0, y: 0, width: 200, height: 120)
        ),
        contentViewController: NSViewController()
    )
    let updatedFrame = CGRect(x: 70, y: 90, width: 640, height: 360)

    overlay.setFrame(updatedFrame, display: false)

    #expect(overlay.frame == updatedFrame)
    #expect(overlay.configuration.frame == updatedFrame)
}

