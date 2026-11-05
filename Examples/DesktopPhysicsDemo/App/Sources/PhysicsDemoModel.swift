import AppKit
import ApplicationServices
import DesktopPhysicsKit

@MainActor
final class PhysicsDemoModel: ObservableObject {
    static let shared = PhysicsDemoModel()

    @Published private(set) var overlayIsVisible = false
    @Published private(set) var objectCount = 0
    @Published private(set) var cursorCollisionEnabled = false
    @Published private(set) var objectDraggingEnabled = false
    @Published private(set) var hasPlayer = false
    @Published private(set) var controlsEnabled = false
    @Published private(set) var windowPlatformsEnabled = false
    @Published private(set) var windowPlatformCount = 0
    @Published private(set) var windowPlatformOutlinesVisible = true
    @Published private(set) var playerWindowCollisionEnabled = true
    @Published private(set) var playerWindowSideCollisionEnabled = false
    @Published private(set) var gameWorldModeEnabled = false
    @Published private(set) var windowPlatformMessage = "Window platforms are off."
    @Published private(set) var controlScheme: DesktopGameControlScheme = .both
    @Published private(set) var spacebarJumpEnabled = true
    @Published private(set) var accessibilityTrusted = AXIsProcessTrusted()
    @Published private(set) var maximumObjectDiameter: CGFloat = 400
    @Published private(set) var maximumPlayerJumpHeight: CGFloat = 900
    @Published private(set) var errorMessage: String?
    @Published private(set) var controlMessage: String?
    @Published private(set) var phoneConnection: PhoneWorldConnection?
    @Published var selectedShape: DesktopPhysicsShape = .random
    @Published var selectedPlayerAppearance: DesktopPlayerAppearance = .stickFigure
    @Published var randomizeObjectSize = false
    @Published var objectDiameter: CGFloat = 48
    @Published var randomMinimumDiameter: CGFloat = 16
    @Published var randomMaximumDiameter: CGFloat = 96
    @Published var cursorColliderDiameter: CGFloat = 36
    @Published var playerJumpHeight: CGFloat = 180

    private var world: DesktopPhysicsWorld?

    var statusText: String {
        if let errorMessage { return errorMessage }
        let visibility = overlayIsVisible ? "Overlay visible" : "Overlay hidden"
        let noun = objectCount == 1 ? "object" : "objects"
        return "\(visibility) · \(objectCount) \(noun)"
    }

    func startIfNeeded() {
        guard world == nil else { return }
        guard let screen = NSScreen.main else {
            errorMessage = "No main display is available."
            return
        }
        maximumObjectDiameter = max(
            1,
            min(screen.visibleFrame.width, screen.visibleFrame.height) * 0.5
        )
        randomMaximumDiameter = min(randomMaximumDiameter, maximumObjectDiameter)
        let world = DesktopPhysicsWorld(screen: screen)
        world.onWindowPlatformStateChange = { [weak self] state in
            self?.applyWindowPlatformState(state)
        }
        self.world = world
        phoneConnection = PhoneWorldConnection(world: world)
        maximumPlayerJumpHeight = world.maximumPlayerJumpHeight
        playerJumpHeight = world.playerJumpHeight
        world.show()
        world.spawn()
        refreshWorldState()
    }

    func spawnObject() {
        let size: DesktopPhysicsSize
        if randomizeObjectSize {
            size = .random(
                in: min(randomMinimumDiameter, randomMaximumDiameter)...max(
                    randomMinimumDiameter,
                    randomMaximumDiameter
                )
            )
        } else {
            size = .diameter(objectDiameter)
        }
        world?.spawn(.init(shape: selectedShape, size: size))
        refreshWorldState()
    }

    func spawnRandomObject(diagnosticRunID runID: String) throws -> Int {
        startIfNeeded()
        guard let world else {
            throw PhysicsDemoActionError.worldUnavailable
        }

        let startedAt = ActionLatencyDiagnostics.monotonicNanoseconds()
        let signpostID = ActionLatencyDiagnostics.signposter.makeSignpostID()
        let interval = ActionLatencyDiagnostics.signposter.beginInterval(
            "DesktopPhysicsWorldSpawn",
            id: signpostID,
            "run_id=\(runID, privacy: .public)"
        )
        ActionLatencyDiagnostics.logger.info(
            "event=world.spawn.started run_id=\(runID, privacy: .public) monotonic_ns=\(startedAt, privacy: .public)"
        )

        world.spawn()
        refreshWorldState()

        let completedAt = ActionLatencyDiagnostics.monotonicNanoseconds()
        let currentObjectCount = objectCount
        let duration = ActionLatencyDiagnostics.milliseconds(
            from: startedAt,
            to: completedAt
        )
        ActionLatencyDiagnostics.logger.info(
            "event=world.spawn.completed run_id=\(runID, privacy: .public) monotonic_ns=\(completedAt, privacy: .public) duration_ms=\(duration, privacy: .public) object_count=\(currentObjectCount, privacy: .public)"
        )
        ActionLatencyDiagnostics.signposter.endInterval(
            "DesktopPhysicsWorldSpawn",
            interval,
            "run_id=\(runID, privacy: .public) object_count=\(currentObjectCount, privacy: .public)"
        )
        return currentObjectCount
    }

    func performSemanticAction(_ url: URL) {
        let receivedAt = ActionLatencyDiagnostics.monotonicNanoseconds()
        guard case let .spawnRandomObject(diagnosticRunID) =
            DesktopPhysicsSemanticAction.resolve(url) else {
            let rejectedRunID = UUID().uuidString.lowercased()
            ActionLatencyDiagnostics.logger.error(
                "event=semantic_action.rejected run_id=\(rejectedRunID, privacy: .public) monotonic_ns=\(receivedAt, privacy: .public)"
            )
            return
        }
        let runID = diagnosticRunID ?? UUID().uuidString.lowercased()
        ActionLatencyDiagnostics.logger.info(
            "event=semantic_action.received run_id=\(runID, privacy: .public) monotonic_ns=\(receivedAt, privacy: .public)"
        )

        let interval = ActionLatencyDiagnostics.signposter.beginInterval(
            "SemanticURLSpawnRandomObject",
            id: ActionLatencyDiagnostics.signposter.makeSignpostID(),
            "run_id=\(runID, privacy: .public)"
        )
        do {
            let objectCount = try spawnRandomObject(diagnosticRunID: runID)
            let completedAt = ActionLatencyDiagnostics.monotonicNanoseconds()
            let duration = ActionLatencyDiagnostics.milliseconds(
                from: receivedAt,
                to: completedAt
            )
            ActionLatencyDiagnostics.logger.info(
                "event=semantic_action.completed run_id=\(runID, privacy: .public) monotonic_ns=\(completedAt, privacy: .public) duration_ms=\(duration, privacy: .public) object_count=\(objectCount, privacy: .public)"
            )
            ActionLatencyDiagnostics.signposter.endInterval(
                "SemanticURLSpawnRandomObject",
                interval,
                "run_id=\(runID, privacy: .public) outcome=ok"
            )
        } catch {
            let failedAt = ActionLatencyDiagnostics.monotonicNanoseconds()
            let duration = ActionLatencyDiagnostics.milliseconds(
                from: receivedAt,
                to: failedAt
            )
            ActionLatencyDiagnostics.logger.error(
                "event=semantic_action.failed run_id=\(runID, privacy: .public) monotonic_ns=\(failedAt, privacy: .public) duration_ms=\(duration, privacy: .public) error=\(error.localizedDescription, privacy: .public)"
            )
            ActionLatencyDiagnostics.signposter.endInterval(
                "SemanticURLSpawnRandomObject",
                interval,
                "run_id=\(runID, privacy: .public) outcome=failed"
            )
        }
    }

    func clearObjects() {
        world?.clearObjects()
        refreshWorldState()
    }

    func toggleOverlay() {
        guard let world else { return }
        world.isVisible ? world.hide() : world.show()
        refreshWorldState()
    }

    func setCursorCollisionEnabled(_ enabled: Bool) {
        world?.setCursorCollisionEnabled(enabled)
        refreshWorldState()
    }

    func setCursorColliderDiameter(_ diameter: CGFloat) {
        cursorColliderDiameter = diameter
        world?.setCursorColliderDiameter(diameter)
        refreshWorldState()
    }

    func setObjectDraggingEnabled(_ enabled: Bool) {
        world?.setObjectDraggingEnabled(enabled)
        refreshWorldState()
    }

    func setWindowPlatformsEnabled(_ enabled: Bool) {
        guard let world else { return }
        if enabled {
            accessibilityTrusted = AXIsProcessTrusted()
            if !accessibilityTrusted {
                requestAccessibilityPermission()
            }
        }

        do {
            try world.setWindowPlatformsEnabled(enabled)
        } catch {
            windowPlatformMessage = error.localizedDescription
        }
        refreshWorldState()
    }

    func setWindowPlatformOutlinesVisible(_ visible: Bool) {
        world?.setWindowPlatformOutlinesVisible(visible)
        refreshWorldState()
    }

    func setPlayerWindowCollisionEnabled(_ enabled: Bool) {
        world?.setPlayerWindowCollisionEnabled(enabled)
        refreshWorldState()
    }

    func setPlayerWindowSideCollisionEnabled(_ enabled: Bool) {
        world?.setPlayerWindowSideCollisionEnabled(enabled)
        refreshWorldState()
    }

    func setGameWorldModeEnabled(_ enabled: Bool) {
        world?.setGameWorldModeEnabled(enabled)
        refreshWorldState()
    }

    func setPlayerJumpHeight(_ height: CGFloat) {
        playerJumpHeight = height
        world?.setPlayerJumpHeight(height)
        refreshWorldState()
    }

    func spawnPlayer() {
        world?.spawnPlayer(appearance: selectedPlayerAppearance)
        refreshWorldState()
    }

    func setControlScheme(_ scheme: DesktopGameControlScheme) {
        world?.setControlScheme(scheme)
        refreshWorldState()
    }

    func setSpacebarJumpEnabled(_ enabled: Bool) {
        world?.setSpacebarJumpEnabled(enabled)
        refreshWorldState()
    }

    func toggleControls() {
        guard let world else { return }
        controlMessage = nil
        if world.controlsEnabled {
            try? world.setControlsEnabled(false)
            refreshSystemState()
            return
        }

        accessibilityTrusted = AXIsProcessTrusted()
        guard accessibilityTrusted else {
            requestAccessibilityPermission()
            controlMessage = "Grant access in System Settings, return here, then press Turn Controls On again."
            refreshWorldState()
            return
        }

        do {
            try world.setControlsEnabled(true)
            controlMessage = "Only unmodified gameplay keys are captured."
        } catch {
            controlMessage = error.localizedDescription
        }
        refreshWorldState()
    }

    func refreshSystemState() {
        accessibilityTrusted = AXIsProcessTrusted()
        refreshWorldState()
    }

    func stop() {
        phoneConnection?.disconnect()
        world?.stop()
        refreshWorldState()
    }

    private func refreshWorldState() {
        guard let world else { return }
        overlayIsVisible = world.isVisible
        objectCount = world.objectCount
        cursorCollisionEnabled = world.cursorCollisionEnabled
        cursorColliderDiameter = world.cursorColliderDiameter
        objectDraggingEnabled = world.objectDraggingEnabled
        hasPlayer = world.hasPlayer
        controlsEnabled = world.controlsEnabled
        controlScheme = world.controlScheme
        spacebarJumpEnabled = world.spacebarJumpEnabled
        windowPlatformsEnabled = world.windowPlatformsEnabled
        windowPlatformCount = world.windowPlatformCount
        windowPlatformOutlinesVisible = world.windowPlatformOutlinesVisible
        playerWindowCollisionEnabled = world.playerWindowCollisionEnabled
        playerWindowSideCollisionEnabled = world.playerWindowSideCollisionEnabled
        gameWorldModeEnabled = world.gameWorldModeEnabled
        playerJumpHeight = world.playerJumpHeight
        windowPlatformMessage = world.windowPlatformStatusMessage
    }

    private func applyWindowPlatformState(_ state: DesktopWindowPlatformState) {
        windowPlatformsEnabled = state.enabled
        windowPlatformCount = state.windowCount
        windowPlatformOutlinesVisible = state.outlinesVisible
        playerWindowCollisionEnabled = state.playerCollisionEnabled
        playerWindowSideCollisionEnabled = state.playerSideCollisionEnabled
        windowPlatformMessage = state.message
    }

    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}

private enum PhysicsDemoActionError: LocalizedError {
    case worldUnavailable

    var errorDescription: String? {
        "The desktop physics world is unavailable."
    }
}
