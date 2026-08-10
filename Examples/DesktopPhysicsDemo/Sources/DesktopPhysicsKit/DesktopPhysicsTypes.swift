import CoreGraphics
import Foundation

public enum DesktopPhysicsShape: String, CaseIterable, Sendable {
    case circle
    case square
    case triangle
    case random
}

public enum DesktopPlayerAppearance: String, CaseIterable, Sendable {
    case stickFigure
    case circle
    case square
    case triangle
    case random

    public var displayName: String {
        switch self {
        case .stickFigure: "Stick Figure"
        case .circle: "Circle"
        case .square: "Square"
        case .triangle: "Triangle"
        case .random: "Random"
        }
    }
}

public enum DesktopGameControlScheme: String, CaseIterable, Sendable {
    case wasd
    case arrows
    case both

    public var displayName: String {
        switch self {
        case .wasd: "WASD"
        case .arrows: "Arrows"
        case .both: "WASD + Arrows"
        }
    }
}

public enum DesktopPhysicsSize: Sendable {
    case small
    case medium
    case large
    case diameter(CGFloat)
    case random(in: ClosedRange<CGFloat>)
}

public struct DesktopPhysicsSpawnRequest: Sendable {
    public var shape: DesktopPhysicsShape
    public var size: DesktopPhysicsSize

    public init(
        shape: DesktopPhysicsShape = .random,
        size: DesktopPhysicsSize = .random(in: 32...72)
    ) {
        self.shape = shape
        self.size = size
    }
}

public struct DesktopWindowPlatformState: Equatable, Sendable {
    public let enabled: Bool
    public let windowCount: Int
    public let outlinesVisible: Bool
    public let playerCollisionEnabled: Bool
    public let playerSideCollisionEnabled: Bool
    public let message: String

    public init(
        enabled: Bool,
        windowCount: Int,
        outlinesVisible: Bool,
        playerCollisionEnabled: Bool,
        playerSideCollisionEnabled: Bool,
        message: String
    ) {
        self.enabled = enabled
        self.windowCount = windowCount
        self.outlinesVisible = outlinesVisible
        self.playerCollisionEnabled = playerCollisionEnabled
        self.playerSideCollisionEnabled = playerSideCollisionEnabled
        self.message = message
    }
}

public struct DesktopPhysicsWorldConfiguration: Sendable {
    public var gravity: CGVector
    public var restitution: CGFloat
    public var cursorRadius: CGFloat
    public var trajectoryTracingEnabled: Bool
    public var playerController: DesktopPlatformerControllerProfile

    public init(
        gravity: CGVector = CGVector(dx: 0, dy: -9.8),
        restitution: CGFloat = 0.48,
        cursorRadius: CGFloat = 18,
        trajectoryTracingEnabled: Bool = false,
        playerController: DesktopPlatformerControllerProfile = .init()
    ) {
        self.gravity = gravity
        self.restitution = restitution
        self.cursorRadius = cursorRadius
        self.trajectoryTracingEnabled = trajectoryTracingEnabled
        self.playerController = playerController
    }
}

/// Designer-facing values for a responsive platformer-style character.
///
/// Jump velocity and gravity are derived from height and time-to-apex so callers
/// can tune visible outcomes rather than unrelated physics constants.
public struct DesktopPlatformerControllerProfile: Sendable {
    public var maximumWalkSpeed: CGFloat
    public var maximumRunSpeed: CGFloat
    public var timeToMaximumSpeed: TimeInterval
    public var timeToStop: TimeInterval
    public var reversalAcceleration: CGFloat
    public var airControlRatio: CGFloat
    public var maximumJumpHeight: CGFloat
    public var minimumJumpHeight: CGFloat
    public var timeToJumpApex: TimeInterval
    public var fallGravityMultiplier: CGFloat
    public var terminalFallSpeed: CGFloat
    public var coyoteTime: TimeInterval
    public var jumpBufferTime: TimeInterval
    public var groundProbeDistance: CGFloat
    public var maximumFloorAngleDegrees: CGFloat
    public var wallProbeDistance: CGFloat
    public var maximumWallSlideFallSpeed: CGFloat
    public var wallContactGraceTime: TimeInterval
    public var wallJumpHorizontalSpeed: CGFloat
    public var wallJumpVerticalSpeed: CGFloat
    public var wallJumpSteeringLockTime: TimeInterval

    public init(
        maximumWalkSpeed: CGFloat = 420,
        maximumRunSpeed: CGFloat = 650,
        timeToMaximumSpeed: TimeInterval = 0.12,
        timeToStop: TimeInterval = 0.085,
        reversalAcceleration: CGFloat = 7_000,
        airControlRatio: CGFloat = 0.55,
        maximumJumpHeight: CGFloat = 180,
        minimumJumpHeight: CGFloat = 70,
        timeToJumpApex: TimeInterval = 0.36,
        fallGravityMultiplier: CGFloat = 1.55,
        terminalFallSpeed: CGFloat = 1_700,
        coyoteTime: TimeInterval = 0.10,
        jumpBufferTime: TimeInterval = 0.12,
        groundProbeDistance: CGFloat = 8,
        maximumFloorAngleDegrees: CGFloat = 50,
        wallProbeDistance: CGFloat = 10,
        maximumWallSlideFallSpeed: CGFloat = 180,
        wallContactGraceTime: TimeInterval = 0.12,
        wallJumpHorizontalSpeed: CGFloat = 260,
        wallJumpVerticalSpeed: CGFloat = 1_000,
        wallJumpSteeringLockTime: TimeInterval = 0.14
    ) {
        self.maximumWalkSpeed = maximumWalkSpeed
        self.maximumRunSpeed = maximumRunSpeed
        self.timeToMaximumSpeed = timeToMaximumSpeed
        self.timeToStop = timeToStop
        self.reversalAcceleration = reversalAcceleration
        self.airControlRatio = airControlRatio
        self.maximumJumpHeight = maximumJumpHeight
        self.minimumJumpHeight = minimumJumpHeight
        self.timeToJumpApex = timeToJumpApex
        self.fallGravityMultiplier = fallGravityMultiplier
        self.terminalFallSpeed = terminalFallSpeed
        self.coyoteTime = coyoteTime
        self.jumpBufferTime = jumpBufferTime
        self.groundProbeDistance = groundProbeDistance
        self.maximumFloorAngleDegrees = maximumFloorAngleDegrees
        self.wallProbeDistance = wallProbeDistance
        self.maximumWallSlideFallSpeed = maximumWallSlideFallSpeed
        self.wallContactGraceTime = wallContactGraceTime
        self.wallJumpHorizontalSpeed = wallJumpHorizontalSpeed
        self.wallJumpVerticalSpeed = wallJumpVerticalSpeed
        self.wallJumpSteeringLockTime = wallJumpSteeringLockTime
    }

    var riseGravity: CGFloat {
        let apex = max(0.05, timeToJumpApex)
        return 2 * max(1, maximumJumpHeight) / (apex * apex)
    }

    var jumpVelocity: CGFloat {
        2 * max(1, maximumJumpHeight) / max(0.05, timeToJumpApex)
    }

    var releaseVelocityCap: CGFloat {
        sqrt(2 * riseGravity * max(1, minimumJumpHeight))
    }

    func maximumHorizontalSpeed(running: Bool) -> CGFloat {
        running ? maximumRunSpeed : maximumWalkSpeed
    }
}

enum ResolvedDesktopPhysicsShape: CaseIterable {
    case circle
    case square
    case triangle
}

extension DesktopPhysicsShape {
    func resolve() -> ResolvedDesktopPhysicsShape {
        switch self {
        case .circle: .circle
        case .square: .square
        case .triangle: .triangle
        case .random: ResolvedDesktopPhysicsShape.allCases.randomElement() ?? .circle
        }
    }
}

extension DesktopPhysicsSize {
    var resolvedDiameter: CGFloat {
        switch self {
        case .small:
            return 32
        case .medium:
            return 48
        case .large:
            return 72
        case let .diameter(value):
            return max(1, value)
        case let .random(range):
            let lower = max(1, min(range.lowerBound, range.upperBound))
            let upper = max(lower, max(range.lowerBound, range.upperBound))
            return CGFloat.random(in: lower...upper)
        }
    }
}
