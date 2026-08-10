import Foundation
import os

enum ActionLatencyDiagnostics {
    static let subsystem = "com.owensantoso.DesktopPhysicsDemo"
    static let category = "ActionLatency"

    static let logger = Logger(subsystem: subsystem, category: category)
    static let signposter = OSSignposter(subsystem: subsystem, category: category)

    static func monotonicNanoseconds() -> UInt64 {
        DispatchTime.now().uptimeNanoseconds
    }

    static func milliseconds(from start: UInt64, to end: UInt64) -> Double {
        Double(end &- start) / 1_000_000
    }
}
