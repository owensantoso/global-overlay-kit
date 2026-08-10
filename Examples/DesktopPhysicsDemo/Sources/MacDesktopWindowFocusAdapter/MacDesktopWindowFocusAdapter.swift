import CoreGraphics
import Foundation
import MacDesktopWindowFocusObservation
import MacDesktopWindowObservation

/// A Desktop Physics adapter that treats focused-window observation as optional.
///
/// The package observer never prompts for Accessibility access. Any result that
/// does not identify exactly one represented window clears the consumer's
/// focused source ID. Ordinary window geometry has an independent provider and
/// remains available when focus cannot be observed.
public struct MacDesktopWindowFocusProvider: Sendable {
    private let observation: @Sendable (Set<Int32>) -> MacDesktopFocusedWindowObservation

    public init(minimumWindowDimension: CGFloat = 50) {
        let snapshotter = MacDesktopWindowSnapshotter(
            minimumWindowDimension: minimumWindowDimension
        )
        let observer = MacDesktopFocusedWindowObserver()
        observation = { excludingProcessIDs in
            observer.observe(in: snapshotter.snapshot(
                excludingProcessIDs: excludingProcessIDs
            ))
        }
    }

    init(
        observation: @escaping @Sendable (Set<Int32>) -> MacDesktopFocusedWindowObservation
    ) {
        self.observation = observation
    }

    public func focusedSourceWindowID(
        excludingProcessIDs: Set<Int32> = []
    ) -> UInt32? {
        Self.sourceWindowID(from: observation(excludingProcessIDs))
    }

    static func sourceWindowID(
        from observation: MacDesktopFocusedWindowObservation
    ) -> UInt32? {
        guard case let .focused(windowID) = observation else { return nil }
        return windowID.rawValue
    }
}
