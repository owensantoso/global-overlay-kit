enum DesktopPlatformerJumpAction: Equatable, Sendable {
    case none
    case dropThrough
    case groundJump
    case airJump
}

/// Tracks the single optional air jump independently from input buffering.
///
/// A grounded/coyote jump preserves the air jump. Landing restores it. A
/// drop-through request only changes platform support in the scene and never
/// consumes the ground jump or the optional air jump.
struct DesktopPlatformerJumpState: Equatable, Sendable {
    private(set) var remainingAirJumps = 1

    mutating func land() {
        remainingAirJumps = 1
    }

    mutating func decide(
        jumpRequested: Bool,
        dropThroughRequested: Bool,
        canUseGroundJump: Bool
    ) -> DesktopPlatformerJumpAction {
        if dropThroughRequested {
            return .dropThrough
        }
        guard jumpRequested else { return .none }
        if canUseGroundJump {
            return .groundJump
        }
        guard remainingAirJumps > 0 else { return .none }
        remainingAirJumps -= 1
        return .airJump
    }
}
