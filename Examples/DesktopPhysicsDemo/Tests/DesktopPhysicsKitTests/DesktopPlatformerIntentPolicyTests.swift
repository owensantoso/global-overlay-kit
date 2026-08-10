import CoreGraphics
import Foundation
import Testing
@testable import DesktopPhysicsKit

private final class IntentTestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var value: TimeInterval = 100

    func now() -> TimeInterval {
        lock.withLock { value }
    }

    func advance(by interval: TimeInterval) {
        lock.withLock {
            value += interval
        }
    }
}

@Suite("Desktop platformer input intent")
struct DesktopPlatformerInputIntentTests {
    @Test("Spacebar jump can be disabled independently of the key family")
    func spacebarJumpConfiguration() {
        let state = DesktopGameInputState()
        state.activate()
        state.setControlScheme(.both)
        state.setSpacebarJumpEnabled(false)

        #expect(state.spacebarJumpEnabled == false)
        #expect(state.shouldDiscard(type: .keyDown, keyCode: 49, flags: []) == false)
        #expect(state.shouldDiscard(type: .keyDown, keyCode: 13, flags: []))
        #expect(state.consumeSnapshot().jumpPressedAt != nil)
        #expect(state.shouldDiscard(type: .keyUp, keyCode: 13, flags: []))

        state.consumeJumpRequest()
        #expect(state.shouldDiscard(
            type: .keyDown,
            keyCode: 126,
            flags: .maskSecondaryFn
        ))
        #expect(state.consumeSnapshot().jumpPressedAt != nil)
    }

    @Test("Spacebar remains an optional jump key for every control scheme")
    func spacebarEnabledAcrossSchemes() {
        for scheme in DesktopGameControlScheme.allCases {
            let state = DesktopGameInputState()
            state.activate()
            state.setControlScheme(scheme)
            state.setSpacebarJumpEnabled(true)

            #expect(state.shouldDiscard(type: .keyDown, keyCode: 49, flags: []))
            #expect(state.consumeSnapshot().jumpPressedAt != nil)
        }
    }

    @Test("Changing Spacebar behavior clears all owned and buffered input")
    func spacebarChangeFailsClosed() {
        let clock = IntentTestClock()
        let state = DesktopGameInputState(monotonicTime: clock.now)
        state.activate()

        #expect(state.shouldDiscard(type: .keyDown, keyCode: 2, flags: []))
        #expect(state.shouldDiscard(type: .keyUp, keyCode: 2, flags: []))
        clock.advance(by: 0.15)
        #expect(state.shouldDiscard(type: .keyDown, keyCode: 2, flags: []))
        #expect(state.consumeSnapshot().wallRunIntentDirection == 1)
        #expect(state.shouldDiscard(type: .keyDown, keyCode: 49, flags: []))

        state.setSpacebarJumpEnabled(false)
        let snapshot = state.consumeSnapshot()
        #expect(snapshot.horizontalDirection == 0)
        #expect(snapshot.jumpPressedAt == nil)
        #expect(snapshot.dropThroughPressedAt == nil)
        #expect(snapshot.runHeld == false)
        #expect(snapshot.wallRunIntentDirection == 0)
    }

    @Test("Shortcut modifiers fail closed without capturing the shortcut")
    func shortcutModifierFailsClosed() {
        let state = DesktopGameInputState()
        state.activate()
        #expect(state.shouldDiscard(type: .keyDown, keyCode: 2, flags: []))
        #expect(state.shouldDiscard(type: .keyDown, keyCode: 49, flags: []))

        #expect(state.shouldDiscard(
            type: .keyDown,
            keyCode: 0,
            flags: .maskCommand
        ) == false)
        var snapshot = state.consumeSnapshot()
        #expect(snapshot.horizontalDirection == 0)
        #expect(snapshot.jumpPressedAt == nil)

        #expect(state.shouldDiscard(
            type: .flagsChanged,
            keyCode: 55,
            flags: .maskCommand
        ) == false)
        snapshot = state.consumeSnapshot()
        #expect(snapshot.horizontalDirection == 0)
        #expect(snapshot.jumpPressedAt == nil)
        #expect(snapshot.jumpHeld == false)
        #expect(snapshot.wallRunIntentDirection == 0)
    }

    @Test(
        "Down intent follows the selected key family",
        arguments: [
            (DesktopGameControlScheme.wasd, CGKeyCode(1), true),
            (DesktopGameControlScheme.wasd, CGKeyCode(125), false),
            (DesktopGameControlScheme.arrows, CGKeyCode(1), false),
            (DesktopGameControlScheme.arrows, CGKeyCode(125), true),
            (DesktopGameControlScheme.both, CGKeyCode(1), true),
            (DesktopGameControlScheme.both, CGKeyCode(125), true)
        ]
    )
    func downwardIntent(
        scheme: DesktopGameControlScheme,
        keyCode: CGKeyCode,
        captured: Bool
    ) {
        let state = DesktopGameInputState()
        state.activate()
        state.setControlScheme(scheme)

        #expect(state.shouldDiscard(
            type: .keyDown,
            keyCode: keyCode,
            flags: keyCode == 125 ? .maskSecondaryFn : []
        ) == captured)
        #expect(state.consumeSnapshot().downwardIntent == captured)
    }

    @Test("Down plus jump emits only a drop-through request")
    func downJumpRequestsDropThrough() {
        let state = DesktopGameInputState()
        state.activate()
        state.setControlScheme(.wasd)

        #expect(state.shouldDiscard(type: .keyDown, keyCode: 1, flags: []))
        #expect(state.shouldDiscard(type: .keyDown, keyCode: 13, flags: []))
        var snapshot = state.consumeSnapshot()
        #expect(snapshot.downwardIntent)
        #expect(snapshot.jumpHeld)
        #expect(snapshot.jumpPressedAt == nil)
        #expect(snapshot.dropThroughPressedAt != nil)

        state.consumeDropThroughRequest()
        snapshot = state.consumeSnapshot()
        #expect(snapshot.dropThroughPressedAt == nil)
        #expect(snapshot.jumpPressedAt == nil)
    }

    @Test("Down Arrow plus Space keeps the arrow's intrinsic Function flag")
    func downArrowSpaceRequestsDropThrough() {
        let state = DesktopGameInputState()
        state.activate()
        state.setControlScheme(.both)

        #expect(state.shouldDiscard(
            type: .keyDown,
            keyCode: 125,
            flags: .maskSecondaryFn
        ))
        #expect(state.shouldDiscard(
            type: .keyDown,
            keyCode: 49,
            flags: .maskSecondaryFn
        ))
        let snapshot = state.consumeSnapshot()
        #expect(snapshot.downwardIntent)
        #expect(snapshot.jumpHeld)
        #expect(snapshot.jumpPressedAt == nil)
        #expect(snapshot.dropThroughPressedAt != nil)
    }

    @Test("Wall-run intent requires a timely second directional press held down")
    func wallRunDoubleTapAndHold() {
        let clock = IntentTestClock()
        let state = DesktopGameInputState(monotonicTime: clock.now)
        state.activate()

        #expect(state.shouldDiscard(type: .keyDown, keyCode: 0, flags: []))
        #expect(state.consumeSnapshot().wallRunIntentDirection == 0)
        #expect(state.shouldDiscard(type: .keyUp, keyCode: 0, flags: []))
        clock.advance(by: DesktopGameInputState.wallRunDoubleTapInterval * 0.8)
        #expect(state.shouldDiscard(type: .keyDown, keyCode: 0, flags: []))
        #expect(state.consumeSnapshot().wallRunIntentDirection == -1)

        #expect(state.shouldDiscard(type: .keyUp, keyCode: 0, flags: []))
        #expect(state.consumeSnapshot().wallRunIntentDirection == 0)
    }

    @Test("Directional presses outside the double-tap interval do not wall-run")
    func wallRunDoubleTapExpires() {
        let clock = IntentTestClock()
        let state = DesktopGameInputState(monotonicTime: clock.now)
        state.activate()

        #expect(state.shouldDiscard(type: .keyDown, keyCode: 2, flags: []))
        #expect(state.shouldDiscard(type: .keyUp, keyCode: 2, flags: []))
        clock.advance(by: DesktopGameInputState.wallRunDoubleTapInterval + 0.01)
        #expect(state.shouldDiscard(type: .keyDown, keyCode: 2, flags: []))
        #expect(state.consumeSnapshot().wallRunIntentDirection == 0)
    }
}

@Suite("Desktop platformer jump policy")
struct DesktopPlatformerJumpPolicyTests {
    @Test("Takeoff allows exactly one air jump until landing")
    func exactlyOneAirJump() {
        var state = DesktopPlatformerJumpState()

        #expect(state.decide(
            jumpRequested: true,
            dropThroughRequested: false,
            canUseGroundJump: true
        ) == .groundJump)
        #expect(state.remainingAirJumps == 1)
        #expect(state.decide(
            jumpRequested: true,
            dropThroughRequested: false,
            canUseGroundJump: false
        ) == .airJump)
        #expect(state.remainingAirJumps == 0)
        #expect(state.decide(
            jumpRequested: true,
            dropThroughRequested: false,
            canUseGroundJump: false
        ) == .none)

        state.land()
        #expect(state.remainingAirJumps == 1)
        #expect(state.decide(
            jumpRequested: true,
            dropThroughRequested: false,
            canUseGroundJump: false
        ) == .airJump)
    }

    @Test("Drop-through does not consume either jump opportunity")
    func dropThroughDoesNotConsumeJump() {
        var state = DesktopPlatformerJumpState()

        #expect(state.decide(
            jumpRequested: false,
            dropThroughRequested: true,
            canUseGroundJump: true
        ) == .dropThrough)
        #expect(state.remainingAirJumps == 1)
        #expect(state.decide(
            jumpRequested: true,
            dropThroughRequested: false,
            canUseGroundJump: true
        ) == .groundJump)
        #expect(state.remainingAirJumps == 1)
    }

    @Test("Running changes horizontal travel without changing jump velocity")
    func runningOnlyChangesHorizontalTravel() {
        let profile = DesktopPlatformerControllerProfile()
        let jumpVelocity = profile.jumpVelocity

        #expect(profile.maximumHorizontalSpeed(running: false) == profile.maximumWalkSpeed)
        #expect(profile.maximumHorizontalSpeed(running: true) == profile.maximumRunSpeed)
        #expect(profile.maximumHorizontalSpeed(running: true)
            > profile.maximumHorizontalSpeed(running: false))
        #expect(profile.jumpVelocity == jumpVelocity)
    }
}
