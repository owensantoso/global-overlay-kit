import Foundation

public struct DesktopPaintedCandidate: Equatable, Sendable {
    public let entityID: DesktopEntityID
    public let frontToBackRank: Int
    public let isDraggable: Bool
    public let isPaintedAtPoint: Bool

    public init(
        entityID: DesktopEntityID,
        frontToBackRank: Int,
        isDraggable: Bool,
        isPaintedAtPoint: Bool
    ) {
        self.entityID = entityID
        self.frontToBackRank = frontToBackRank
        self.isDraggable = isDraggable
        self.isPaintedAtPoint = isPaintedAtPoint
    }
}

public enum DesktopPaintedCandidateSelection {
    public static func frontmost(
        in candidates: [DesktopPaintedCandidate]
    ) -> DesktopEntityID? {
        candidates
            .filter { $0.isDraggable && $0.isPaintedAtPoint }
            .min {
                if $0.frontToBackRank != $1.frontToBackRank {
                    return $0.frontToBackRank < $1.frontToBackRank
                }
                return $0.entityID.rawValue.utf8.lexicographicallyPrecedes(
                    $1.entityID.rawValue.utf8
                )
            }?
            .entityID
    }
}

public enum DesktopHorizontalDirection: Int, Codable, CaseIterable, Sendable {
    case negativeX = -1
    case neutral = 0
    case positiveX = 1
}

public struct DesktopWallContact: Equatable, Sendable {
    public let featureID: DesktopSurfaceID
    public let directionFromPlayer: DesktopHorizontalDirection
    public let planeX: Double

    public init(
        featureID: DesktopSurfaceID,
        directionFromPlayer: DesktopHorizontalDirection,
        planeX: Double
    ) throws {
        guard directionFromPlayer != .neutral else {
            throw DesktopGameValidationError.invalidValue(field: "wall_direction")
        }
        guard planeX.isFinite else {
            throw DesktopGameValidationError.nonfinite(field: "wall_plane_x")
        }
        self.featureID = featureID
        self.directionFromPlayer = directionFromPlayer
        self.planeX = planeX
    }

}

public struct DesktopHorizontalBounds: Equatable, Sendable {
    public let minX: Double
    public let maxX: Double

    public init(minX: Double, maxX: Double) throws {
        guard minX.isFinite, maxX.isFinite else {
            throw DesktopGameValidationError.nonfinite(field: "horizontal_bounds")
        }
        guard minX <= maxX else {
            throw DesktopGameValidationError.invalidRange(field: "horizontal_bounds")
        }
        self.minX = minX
        self.maxX = maxX
    }
}

public struct DesktopWallTraversalState: Codable, Equatable, Sendable {
    public let featureID: DesktopSurfaceID
    public let direction: DesktopHorizontalDirection
    public let planeX: Double
    public let coincidentTolerance: Double

    public init(
        featureID: DesktopSurfaceID,
        direction: DesktopHorizontalDirection,
        planeX: Double,
        coincidentTolerance: Double = 0.5
    ) throws {
        guard direction != .neutral else {
            throw DesktopGameValidationError.invalidValue(field: "wall_direction")
        }
        guard planeX.isFinite, coincidentTolerance.isFinite else {
            throw DesktopGameValidationError.nonfinite(field: "wall_traversal")
        }
        guard coincidentTolerance >= 0 else {
            throw DesktopGameValidationError.invalidRange(field: "coincident_tolerance")
        }
        self.featureID = featureID
        self.direction = direction
        self.planeX = planeX
        self.coincidentTolerance = coincidentTolerance
    }

    /// Active traversal excludes the contacted physical plane regardless of a
    /// candidate's post-crossing player-relative direction or source ID.
    public func excludes(_ candidate: DesktopWallContact) -> Bool {
        abs(candidate.planeX - planeX) <= coincidentTolerance
    }

    public func shouldClear(
        previousBounds: DesktopHorizontalBounds,
        tolerance: Double = 0
    ) -> Bool {
        let tolerance = tolerance.isFinite ? max(0, tolerance) : 0
        return switch direction {
        case .negativeX:
            previousBounds.maxX < planeX - tolerance
        case .positiveX:
            previousBounds.minX > planeX + tolerance
        case .neutral:
            false
        }
    }

    enum CodingKeys: String, CodingKey {
        case direction
        case featureID = "feature_id"
        case planeX = "plane_x"
        case coincidentTolerance = "coincident_tolerance"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            featureID: container.decode(DesktopSurfaceID.self, forKey: .featureID),
            direction: container.decode(DesktopHorizontalDirection.self, forKey: .direction),
            planeX: container.decode(Double.self, forKey: .planeX),
            coincidentTolerance: container.decode(Double.self, forKey: .coincidentTolerance)
        )
    }
}

public enum DesktopWallJumpDecisionKind: Equatable, Sendable {
    case none
    case outwardWallJump
    case traverse
}

public struct DesktopWallJumpDecision: Equatable, Sendable {
    public let kind: DesktopWallJumpDecisionKind
    public let traversalState: DesktopWallTraversalState?

    public init(kind: DesktopWallJumpDecisionKind, traversalState: DesktopWallTraversalState?) {
        self.kind = kind
        self.traversalState = traversalState
    }
}

public enum DesktopWallTraversalPolicy {
    public static func jumpDecision(
        contact: DesktopWallContact?,
        horizontalIntent: DesktopHorizontalDirection,
        jumpPressed: Bool,
        coincidentTolerance: Double = 0.5
    ) throws -> DesktopWallJumpDecision {
        guard jumpPressed, let contact else {
            return DesktopWallJumpDecision(kind: .none, traversalState: nil)
        }
        guard horizontalIntent == contact.directionFromPlayer else {
            return DesktopWallJumpDecision(kind: .outwardWallJump, traversalState: nil)
        }
        let state = try DesktopWallTraversalState(
            featureID: contact.featureID,
            direction: contact.directionFromPlayer,
            planeX: contact.planeX,
            coincidentTolerance: coincidentTolerance
        )
        return DesktopWallJumpDecision(kind: .traverse, traversalState: state)
    }
}
