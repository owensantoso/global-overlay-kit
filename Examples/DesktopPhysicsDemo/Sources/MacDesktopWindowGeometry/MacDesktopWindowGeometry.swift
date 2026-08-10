import AppKit
import ApplicationServices
import CoreGraphics
import DesktopGeometry
import Foundation
import MacDesktopWindowObservation

// Design provenance: this target adapts the window-list/filter/coordinate seam
// explored by the historical DesktopSurfaceKit gaze POC. That POC's only local
// copy is outside version control, so it is not used as a package dependency or
// source of truth. This slice deliberately uses CGWindowList for window IDs and
// frames; it does not imply that Accessibility supplies those rectangles.

public enum MacDesktopWindowGeometryAvailability: Equatable, Sendable {
    case available
    case accessibilityRequired
    case unavailable
}

public struct MacDesktopWindow: Equatable, Sendable {
    public let id: String
    public let sourceWindowID: UInt32
    public let fragmentIndex: Int
    public let processID: Int32
    public let applicationName: String?
    public let frame: CGRect
    public let zIndex: Int
    public let hasVisibleTopEdge: Bool
    public let hasVisibleBottomEdge: Bool
    public let hasVisibleLeftEdge: Bool
    public let hasVisibleRightEdge: Bool

    public init(
        id: String,
        sourceWindowID: UInt32,
        fragmentIndex: Int,
        processID: Int32,
        applicationName: String?,
        frame: CGRect,
        zIndex: Int,
        hasVisibleTopEdge: Bool = true,
        hasVisibleBottomEdge: Bool = true,
        hasVisibleLeftEdge: Bool = true,
        hasVisibleRightEdge: Bool = true
    ) {
        self.id = id
        self.sourceWindowID = sourceWindowID
        self.fragmentIndex = fragmentIndex
        self.processID = processID
        self.applicationName = applicationName
        self.frame = frame
        self.zIndex = zIndex
        self.hasVisibleTopEdge = hasVisibleTopEdge
        self.hasVisibleBottomEdge = hasVisibleBottomEdge
        self.hasVisibleLeftEdge = hasVisibleLeftEdge
        self.hasVisibleRightEdge = hasVisibleRightEdge
    }
}

public struct MacDesktopWindowGeometrySnapshot: Equatable, Sendable {
    public let availability: MacDesktopWindowGeometryAvailability
    public let windows: [MacDesktopWindow]
    public let message: String

    public init(
        availability: MacDesktopWindowGeometryAvailability,
        windows: [MacDesktopWindow],
        message: String
    ) {
        self.availability = availability
        self.windows = windows
        self.message = message
    }
}

/// A read-only, macOS-specific adapter from on-screen application windows to
/// stable-enough rectangles in one selected SpriteKit scene.
///
/// Core Graphics owns window enumeration and IDs. Accessibility remains an
/// explicit feature gate so geometry fails off with the app's other global
/// desktop controls instead of silently changing its permission contract.
@MainActor
public final class MacDesktopWindowGeometryProvider {
    public let minimumWindowDimension: CGFloat
    private let snapshotter: MacDesktopWindowSnapshotter

    public init(minimumWindowDimension: CGFloat = 50) {
        snapshotter = MacDesktopWindowSnapshotter(
            minimumWindowDimension: minimumWindowDimension
        )
        self.minimumWindowDimension = snapshotter.minimumWindowDimension
    }

    public var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    public func snapshot(
        selectedScreenFrame: CGRect,
        excludingProcessIDs: Set<Int32> = []
    ) -> MacDesktopWindowGeometrySnapshot {
        guard isAccessibilityTrusted else {
            return MacDesktopWindowGeometrySnapshot(
                availability: .accessibilityRequired,
                windows: [],
                message: "Accessibility access is required. Window platforms are off."
            )
        }
        guard selectedScreenFrame.isFiniteAndNonEmpty else {
            return MacDesktopWindowGeometrySnapshot(
                availability: .unavailable,
                windows: [],
                message: "The selected display frame is invalid. Window platforms are off."
            )
        }

        let observed = snapshotter.snapshot(
            excludingProcessIDs: excludingProcessIDs
        )
        guard observed.status == .available else {
            return MacDesktopWindowGeometrySnapshot(
                availability: .unavailable,
                windows: [],
                message: "macOS did not return an on-screen window list. Window platforms are off."
            )
        }

        let observedByID = Dictionary(
            uniqueKeysWithValues: observed.windows.map { (String($0.id.rawValue), $0) }
        )
        let rectangles = observed.windows.map { window in
            SurfaceRectangle(
                id: String(window.id.rawValue),
                frame: ScreenFrame(
                    x: window.frame.minX,
                    y: window.frame.minY,
                    width: window.frame.width,
                    height: window.frame.height
                )
            )
        }
        let visibleFragments = VisibleRegionExtractor().extract(from: rectangles)
        let mainDisplayHeight = CGDisplayBounds(CGMainDisplayID()).height
        let windows = visibleFragments.compactMap { fragment -> MacDesktopWindow? in
            guard let observedWindow = observedByID[fragment.sourceRectangleID],
                  let sceneFrame = Self.sceneFrame(
                    quartzFrame: CGRect(
                        x: fragment.frame.x,
                        y: fragment.frame.y,
                        width: fragment.frame.width,
                        height: fragment.frame.height
                    ),
                    selectedScreenFrame: selectedScreenFrame,
                    mainDisplayHeight: mainDisplayHeight
                  ) else {
                return nil
            }
            return MacDesktopWindow(
                id: fragment.id,
                sourceWindowID: observedWindow.id.rawValue,
                fragmentIndex: fragment.fragmentIndex,
                processID: observedWindow.processID,
                applicationName: observedWindow.applicationName,
                frame: sceneFrame,
                zIndex: observedWindow.zIndex,
                hasVisibleTopEdge: fragment.sourceSides.contains(.minY),
                hasVisibleBottomEdge: fragment.sourceSides.contains(.maxY),
                hasVisibleLeftEdge: fragment.sourceSides.contains(.minX),
                hasVisibleRightEdge: fragment.sourceSides.contains(.maxX)
            )
        }

        return MacDesktopWindowGeometrySnapshot(
            availability: .available,
            windows: windows,
            message: windows.count == 1
                ? "1 visible window region is active."
                : "\(windows.count) visible window regions are active."
        )
    }

    nonisolated static func sceneFrame(
        quartzFrame: CGRect,
        selectedScreenFrame: CGRect,
        mainDisplayHeight: CGFloat
    ) -> CGRect? {
        guard quartzFrame.isFiniteAndNonEmpty,
              selectedScreenFrame.isFiniteAndNonEmpty,
              mainDisplayHeight.isFinite else {
            return nil
        }
        let appKitFrame = CGRect(
            x: quartzFrame.minX,
            y: mainDisplayHeight - quartzFrame.maxY,
            width: quartzFrame.width,
            height: quartzFrame.height
        )
        let clipped = appKitFrame.intersection(selectedScreenFrame)
        guard clipped.isNull == false, clipped.isFiniteAndNonEmpty else { return nil }
        return CGRect(
            x: clipped.minX - selectedScreenFrame.minX,
            y: clipped.minY - selectedScreenFrame.minY,
            width: clipped.width,
            height: clipped.height
        )
    }

    nonisolated static func visibleSourceEdges(
        quartzFragmentFrame: CGRect,
        sourceWindowFrame: CGRect,
        tolerance: CGFloat = 0.001
    ) -> (top: Bool, bottom: Bool, left: Bool, right: Bool) {
        (
            top: abs(quartzFragmentFrame.minY - sourceWindowFrame.minY) < tolerance,
            bottom: abs(quartzFragmentFrame.maxY - sourceWindowFrame.maxY) < tolerance,
            left: abs(quartzFragmentFrame.minX - sourceWindowFrame.minX) < tolerance,
            right: abs(quartzFragmentFrame.maxX - sourceWindowFrame.maxX) < tolerance
        )
    }

}

private extension CGRect {
    var isFiniteAndNonEmpty: Bool {
        origin.x.isFinite
            && origin.y.isFinite
            && width.isFinite
            && height.isFinite
            && width > 0
            && height > 0
    }
}
