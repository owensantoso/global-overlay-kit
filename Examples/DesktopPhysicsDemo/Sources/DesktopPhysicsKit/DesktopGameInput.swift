import ApplicationServices
import CoreGraphics

struct DesktopGameInputSnapshot {
    let horizontalDirection: CGFloat
    let jumpPressedAt: TimeInterval?
    let dropThroughPressedAt: TimeInterval?
    let jumpHeld: Bool
    let downwardIntent: Bool
    let runHeld: Bool
    let sitting: Bool
    let wallRunIntentDirection: CGFloat
}

final class DesktopGameInputState: @unchecked Sendable {
    private enum KeyCode {
        static let a: CGKeyCode = 0
        static let s: CGKeyCode = 1
        static let d: CGKeyCode = 2
        static let c: CGKeyCode = 8
        static let w: CGKeyCode = 13
        static let space: CGKeyCode = 49
        static let leftArrow: CGKeyCode = 123
        static let rightArrow: CGKeyCode = 124
        static let downArrow: CGKeyCode = 125
        static let upArrow: CGKeyCode = 126

        static let tracked: Set<CGKeyCode> = [
            a, s, d, c, w, space,
            leftArrow, rightArrow, downArrow, upArrow
        ]
        static let left: Set<CGKeyCode> = [a, leftArrow]
        static let right: Set<CGKeyCode> = [d, rightArrow]
        static let down: Set<CGKeyCode> = [s, downArrow]
        static let arrows: Set<CGKeyCode> = [
            leftArrow, rightArrow, downArrow, upArrow
        ]

        static func tracked(
            for scheme: DesktopGameControlScheme,
            spacebarJumps: Bool
        ) -> Set<CGKeyCode> {
            var keys: Set<CGKeyCode> = switch scheme {
            case .wasd: [a, s, d, c, w]
            case .arrows: [c, leftArrow, rightArrow, downArrow, upArrow]
            case .both: tracked.subtracting([space])
            }
            if spacebarJumps {
                keys.insert(space)
            }
            return keys
        }

        static func left(for scheme: DesktopGameControlScheme) -> Set<CGKeyCode> {
            switch scheme {
            case .wasd: [a]
            case .arrows: [leftArrow]
            case .both: left
            }
        }

        static func right(for scheme: DesktopGameControlScheme) -> Set<CGKeyCode> {
            switch scheme {
            case .wasd: [d]
            case .arrows: [rightArrow]
            case .both: right
            }
        }

        static func down(for scheme: DesktopGameControlScheme) -> Set<CGKeyCode> {
            switch scheme {
            case .wasd: [s]
            case .arrows: [downArrow]
            case .both: down
            }
        }

        static func jump(
            for scheme: DesktopGameControlScheme,
            spacebarJumps: Bool
        ) -> Set<CGKeyCode> {
            var keys: Set<CGKeyCode> = switch scheme {
            case .wasd: [w]
            case .arrows: [upArrow]
            case .both: [w, upArrow]
            }
            if spacebarJumps {
                keys.insert(space)
            }
            return keys
        }

        static func horizontalDirection(
            for keyCode: CGKeyCode,
            scheme: DesktopGameControlScheme
        ) -> CGFloat {
            if left(for: scheme).contains(keyCode) { return -1 }
            if right(for: scheme).contains(keyCode) { return 1 }
            return 0
        }
    }

    private static let shortcutModifiers: CGEventFlags = [
        .maskCommand,
        .maskControl,
        .maskAlternate,
        .maskSecondaryFn
    ]

    private let monotonicTime: @Sendable () -> TimeInterval
    private let lock = NSLock()
    private var active = false
    private var controlScheme: DesktopGameControlScheme = .both
    private var spacebarJumps = true
    private var heldKeys: Set<CGKeyCode> = []
    private var jumpPressedAt: TimeInterval?
    private var dropThroughPressedAt: TimeInterval?
    private var runHeld = false
    private var sitting = false
    private var lastLeftPressAt: TimeInterval?
    private var lastRightPressAt: TimeInterval?
    private var wallRunIntentKey: CGKeyCode?
    private var wallRunIntentDirection: CGFloat = 0

    /// The maximum interval between directional presses for a wall-run intent.
    /// The second press must remain held; wall contact is validated by the scene.
    static let wallRunDoubleTapInterval: TimeInterval = 0.30

    init(
        monotonicTime: @escaping @Sendable () -> TimeInterval = {
            ProcessInfo.processInfo.systemUptime
        }
    ) {
        self.monotonicTime = monotonicTime
    }

    var isActive: Bool {
        lock.withLock { active }
    }

    var scheme: DesktopGameControlScheme {
        lock.withLock { controlScheme }
    }

    var spacebarJumpEnabled: Bool {
        lock.withLock { spacebarJumps }
    }

    func setControlScheme(_ scheme: DesktopGameControlScheme) {
        lock.withLock {
            controlScheme = scheme
            resetGameplayState()
        }
    }

    func setSpacebarJumpEnabled(_ enabled: Bool) {
        lock.withLock {
            spacebarJumps = enabled
            resetGameplayState()
        }
    }

    func activate() {
        lock.withLock {
            active = true
            resetGameplayState()
        }
    }

    func deactivate() {
        lock.withLock {
            active = false
            resetGameplayState()
        }
    }

    func failClosed() {
        deactivate()
    }

    /// Returns true only when the event belongs exclusively to active gameplay.
    func shouldDiscard(
        type: CGEventType,
        keyCode: CGKeyCode,
        flags: CGEventFlags,
        isRepeat: Bool = false
    ) -> Bool {
        lock.withLock {
            guard active else { return false }

            if type == .flagsChanged {
                if !flags.intersection(Self.shortcutModifiers).isEmpty {
                    resetGameplayState()
                } else {
                    runHeld = flags.contains(.maskShift)
                }
                return false
            }

            let trackedKeys = KeyCode.tracked(
                for: controlScheme,
                spacebarJumps: spacebarJumps
            )
            guard trackedKeys.contains(keyCode) else { return false }

            let effectiveModifiers = shortcutModifiers(
                in: flags,
                for: keyCode
            )
            guard effectiveModifiers.isEmpty else {
                resetGameplayState()
                return false
            }

            if type == .keyUp {
                let wasOwned = heldKeys.remove(keyCode) != nil
                if wallRunIntentKey == keyCode {
                    clearWallRunIntent()
                }
                return wasOwned
            }

            guard type == .keyDown else {
                return false
            }

            runHeld = flags.contains(.maskShift)
            let inserted = heldKeys.insert(keyCode).inserted
            if inserted, !isRepeat {
                if keyCode == KeyCode.c {
                    sitting.toggle()
                } else {
                    sitting = false
                    let now = monotonicTime()
                    registerDirectionalPress(keyCode, at: now)
                    if KeyCode.jump(
                        for: controlScheme,
                        spacebarJumps: spacebarJumps
                    ).contains(keyCode) {
                        if !heldKeys.isDisjoint(
                            with: KeyCode.down(for: controlScheme)
                        ) {
                            jumpPressedAt = nil
                            dropThroughPressedAt = now
                        } else {
                            jumpPressedAt = now
                        }
                    }
                }
            }
            return true
        }
    }

    func currentMonotonicTime() -> TimeInterval {
        monotonicTime()
    }

    func consumeSnapshot() -> DesktopGameInputSnapshot {
        lock.withLock {
            let left = !heldKeys.isDisjoint(with: KeyCode.left(for: controlScheme))
            let right = !heldKeys.isDisjoint(with: KeyCode.right(for: controlScheme))
            let direction: CGFloat = left == right ? 0 : (left ? -1 : 1)
            let downwardIntent = !heldKeys.isDisjoint(
                with: KeyCode.down(for: controlScheme)
            )
            let snapshot = DesktopGameInputSnapshot(
                horizontalDirection: direction,
                jumpPressedAt: jumpPressedAt,
                dropThroughPressedAt: dropThroughPressedAt,
                jumpHeld: !heldKeys.isDisjoint(with: KeyCode.jump(
                    for: controlScheme,
                    spacebarJumps: spacebarJumps
                )),
                downwardIntent: downwardIntent,
                runHeld: runHeld,
                sitting: sitting,
                wallRunIntentDirection: wallRunIntentDirection
            )
            return snapshot
        }
    }

    func consumeJumpRequest() {
        lock.withLock {
            jumpPressedAt = nil
        }
    }

    func consumeDropThroughRequest() {
        lock.withLock {
            dropThroughPressedAt = nil
        }
    }

    func discardJumpRequest(olderThan cutoff: TimeInterval) {
        lock.withLock {
            if let jumpPressedAt, jumpPressedAt < cutoff {
                self.jumpPressedAt = nil
            }
        }
    }

    func discardDropThroughRequest(olderThan cutoff: TimeInterval) {
        lock.withLock {
            if let dropThroughPressedAt, dropThroughPressedAt < cutoff {
                self.dropThroughPressedAt = nil
            }
        }
    }

    private func registerDirectionalPress(
        _ keyCode: CGKeyCode,
        at time: TimeInterval
    ) {
        let direction = KeyCode.horizontalDirection(
            for: keyCode,
            scheme: controlScheme
        )
        guard direction != 0 else { return }

        let previousPress = direction < 0 ? lastLeftPressAt : lastRightPressAt
        if let previousPress,
           time >= previousPress,
           time - previousPress <= Self.wallRunDoubleTapInterval {
            wallRunIntentKey = keyCode
            wallRunIntentDirection = direction
        }
        if direction < 0 {
            lastLeftPressAt = time
        } else {
            lastRightPressAt = time
        }
    }

    private func resetGameplayState() {
        heldKeys.removeAll()
        jumpPressedAt = nil
        dropThroughPressedAt = nil
        runHeld = false
        sitting = false
        lastLeftPressAt = nil
        lastRightPressAt = nil
        clearWallRunIntent()
    }

    private func clearWallRunIntent() {
        wallRunIntentKey = nil
        wallRunIntentDirection = 0
    }

    private func shortcutModifiers(
        in flags: CGEventFlags,
        for keyCode: CGKeyCode
    ) -> CGEventFlags {
        var modifiers = flags.intersection(Self.shortcutModifiers)
        // macOS marks navigation/arrow events as Function events and carries
        // that intrinsic flag onto a simultaneously pressed jump key. It is
        // not evidence of a shortcut while a tracked arrow remains held.
        if KeyCode.arrows.contains(keyCode)
            || !heldKeys.isDisjoint(with: KeyCode.arrows) {
            modifiers.remove(.maskSecondaryFn)
        }
        return modifiers
    }
}

@MainActor
final class GlobalGameKeyController {
    enum StartError: LocalizedError {
        case accessibilityPermissionRequired
        case eventTapUnavailable

        var errorDescription: String? {
            switch self {
            case .accessibilityPermissionRequired:
                "Accessibility access is required before controls can be enabled."
            case .eventTapUnavailable:
                "macOS did not create the keyboard control tap. Controls remain off."
            }
        }
    }

    let state = DesktopGameInputState()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var isEnabled: Bool {
        state.isActive && eventTap != nil
    }

    func start() throws {
        guard !isEnabled else { return }
        stop()
        guard AXIsProcessTrusted() else {
            throw StartError.accessibilityPermissionRequired
        }

        let mask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
        let statePointer = Unmanaged.passUnretained(state).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: Self.eventCallback,
            userInfo: statePointer
        ) else {
            throw StartError.eventTapUnavailable
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            throw StartError.eventTapUnavailable
        }

        eventTap = tap
        runLoopSource = source
        state.activate()
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        state.deactivate()
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        runLoopSource = nil
        eventTap = nil
    }

    private static let eventCallback: CGEventTapCallBack = { _, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }
        let state = Unmanaged<DesktopGameInputState>
            .fromOpaque(userInfo)
            .takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            state.failClosed()
            return Unmanaged.passUnretained(event)
        }

        let keyCode = CGKeyCode(
            event.getIntegerValueField(.keyboardEventKeycode)
        )
        let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        let discard = state.shouldDiscard(
            type: type,
            keyCode: keyCode,
            flags: event.flags,
            isRepeat: isRepeat
        )
        return discard ? nil : Unmanaged.passUnretained(event)
    }
}
