import AppKit
import GlobalOverlayKit
import MacDesktopWindowGeometry
import SpriteKit

public enum DesktopWindowPlatformError: LocalizedError {
    case unavailable(String)

    public var errorDescription: String? {
        switch self {
        case let .unavailable(message):
            message
        }
    }
}

@MainActor
public final class DesktopPhysicsWorld {
    private let overlay: GlobalOverlay
    private let sceneController: DesktopPhysicsSceneViewController
    private let keyController = GlobalGameKeyController()
    private let windowGeometryProvider = MacDesktopWindowGeometryProvider()
    private let screenFrame: CGRect
    private var windowPlatformPollingTask: Task<Void, Never>?
    private var windowPlatformsActive = false
    private var windowPlatformStatus = "Window platforms are off."

    public var onWindowPlatformStateChange: ((DesktopWindowPlatformState) -> Void)? {
        didSet { publishWindowPlatformState() }
    }

    public init(
        screen: NSScreen,
        configuration: DesktopPhysicsWorldConfiguration = .init()
    ) {
        let frame = screen.visibleFrame
        screenFrame = frame
        let controller = DesktopPhysicsSceneViewController(
            size: frame.size,
            screenFrame: frame,
            configuration: configuration,
            inputState: keyController.state
        )
        sceneController = controller
        overlay = GlobalOverlay(
            configuration: .screenFilling(
                screen,
                includeMenuBarAndDock: false,
                interaction: .passThrough
            ),
            contentViewController: controller
        )
        controller.scene.onDragInputCaptureChange = { [weak overlay] shouldCapture in
            overlay?.setInteraction(shouldCapture ? .interactive : .passThrough)
        }
    }

    public var isVisible: Bool { overlay.isVisible }
    public var objectCount: Int { sceneController.scene.objectCount }
    public var hasPlayer: Bool { sceneController.scene.hasPlayer }
    public var cursorCollisionEnabled: Bool { sceneController.scene.cursorCollisionEnabled }
    public var cursorColliderDiameter: CGFloat { sceneController.scene.cursorColliderDiameter }
    public var objectDraggingEnabled: Bool { sceneController.scene.objectDraggingEnabled }
    public var controlsEnabled: Bool { keyController.isEnabled }
    public var controlScheme: DesktopGameControlScheme { keyController.state.scheme }
    public var spacebarJumpEnabled: Bool { keyController.state.spacebarJumpEnabled }
    public var windowPlatformsEnabled: Bool { windowPlatformsActive }
    public var windowPlatformCount: Int {
        sceneController.scene.windowPlatformCount
    }
    public var windowPlatformStatusMessage: String { windowPlatformStatus }
    public var windowPlatformOutlinesVisible: Bool {
        sceneController.scene.windowPlatformOutlinesVisible
    }
    public var playerWindowCollisionEnabled: Bool {
        sceneController.scene.playerWindowCollisionEnabled
    }
    public var playerWindowSideCollisionEnabled: Bool {
        sceneController.scene.playerWindowSideCollisionEnabled
    }
    public var gameWorldModeEnabled: Bool {
        sceneController.scene.gameWorldModeEnabled
    }
    public var playerJumpHeight: CGFloat { sceneController.scene.playerJumpHeight }
    public var maximumPlayerJumpHeight: CGFloat { max(180, screenFrame.height * 0.95) }

    public func show() {
        overlay.show()
    }

    public func hide() {
        overlay.hide()
    }

    public func spawn(_ request: DesktopPhysicsSpawnRequest = .init()) {
        sceneController.scene.spawn(request)
    }

    public func clearObjects() {
        sceneController.scene.clearObjects()
    }

    public func setCursorCollisionEnabled(_ enabled: Bool) {
        sceneController.scene.setCursorCollisionEnabled(enabled)
    }

    public func setCursorColliderDiameter(_ diameter: CGFloat) {
        sceneController.scene.setCursorColliderDiameter(diameter)
    }

    public func setObjectDraggingEnabled(_ enabled: Bool) {
        sceneController.scene.setObjectDraggingEnabled(enabled)
    }

    public func setWindowPlatformsEnabled(_ enabled: Bool) throws {
        guard enabled else {
            disableWindowPlatforms(message: "Window platforms are off.")
            return
        }
        windowPlatformsActive = true
        do {
            try refreshWindowPlatforms()
        } catch {
            disableWindowPlatforms(message: error.localizedDescription)
            throw error
        }
        guard windowPlatformPollingTask == nil else { return }
        windowPlatformPollingTask = Task { @MainActor [weak self] in
            while Task.isCancelled == false {
                try? await Task.sleep(for: .milliseconds(500))
                guard Task.isCancelled == false, let self else { return }
                do {
                    try self.refreshWindowPlatforms()
                } catch {
                    self.disableWindowPlatforms(message: error.localizedDescription)
                    return
                }
            }
        }
    }

    public func setWindowPlatformOutlinesVisible(_ visible: Bool) {
        sceneController.scene.setWindowPlatformOutlinesVisible(visible)
        publishWindowPlatformState()
    }

    public func setPlayerWindowCollisionEnabled(_ enabled: Bool) {
        sceneController.scene.setPlayerWindowCollisionEnabled(enabled)
        publishWindowPlatformState()
    }

    public func setPlayerWindowSideCollisionEnabled(_ enabled: Bool) {
        sceneController.scene.setPlayerWindowSideCollisionEnabled(enabled)
        publishWindowPlatformState()
    }

    public func setGameWorldModeEnabled(_ enabled: Bool) {
        sceneController.scene.setGameWorldModeEnabled(enabled)
    }

    public func setPlayerJumpHeight(_ height: CGFloat) {
        sceneController.scene.setPlayerJumpHeight(height)
    }

    public func spawnPlayer(appearance: DesktopPlayerAppearance = .stickFigure) {
        sceneController.scene.spawnPlayer(appearance: appearance)
    }

    public func spawnPlayer(shape: DesktopPhysicsShape) {
        let appearance: DesktopPlayerAppearance
        switch shape {
        case .circle: appearance = .circle
        case .square: appearance = .square
        case .triangle: appearance = .triangle
        case .random: appearance = .random
        }
        spawnPlayer(appearance: appearance)
    }

    public func setControlScheme(_ scheme: DesktopGameControlScheme) {
        keyController.state.setControlScheme(scheme)
    }

    public func setSpacebarJumpEnabled(_ enabled: Bool) {
        keyController.state.setSpacebarJumpEnabled(enabled)
    }

    public func setControlsEnabled(_ enabled: Bool) throws {
        if enabled {
            try keyController.start()
        } else {
            keyController.stop()
        }
    }

    public func stop() {
        keyController.stop()
        disableWindowPlatforms(message: "Window platforms are off.")
        sceneController.scene.setObjectDraggingEnabled(false)
        sceneController.scene.setGameWorldModeEnabled(
            false,
            reduceMotion: true
        )
        overlay.setInteraction(.passThrough)
        overlay.hide()
    }

    private func refreshWindowPlatforms() throws {
        let snapshot = windowGeometryProvider.snapshot(
            selectedScreenFrame: screenFrame
        )
        switch snapshot.availability {
        case .available:
            sceneController.scene.setWindowPlatforms(snapshot.windows)
            windowPlatformStatus = snapshot.message
            publishWindowPlatformState()
        case .unavailable:
            throw DesktopWindowPlatformError.unavailable(snapshot.message)
        }
    }

    private func disableWindowPlatforms(message: String) {
        windowPlatformPollingTask?.cancel()
        windowPlatformPollingTask = nil
        windowPlatformsActive = false
        sceneController.scene.setWindowPlatforms([])
        windowPlatformStatus = message
        publishWindowPlatformState()
    }

    private func publishWindowPlatformState() {
        onWindowPlatformStateChange?(DesktopWindowPlatformState(
            enabled: windowPlatformsEnabled,
            windowCount: windowPlatformCount,
            outlinesVisible: windowPlatformOutlinesVisible,
            playerCollisionEnabled: playerWindowCollisionEnabled,
            playerSideCollisionEnabled: playerWindowSideCollisionEnabled,
            message: windowPlatformStatus
        ))
    }
}

@MainActor
final class DesktopPhysicsSceneViewController: NSViewController {
    let scene: DesktopPhysicsScene

    init(
        size: CGSize,
        screenFrame: CGRect,
        configuration: DesktopPhysicsWorldConfiguration,
        inputState: DesktopGameInputState
    ) {
        scene = DesktopPhysicsScene(
            size: size,
            screenFrame: screenFrame,
            configuration: configuration,
            inputState: inputState
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        let spriteView = SKView(frame: .zero)
        spriteView.allowsTransparency = true
        spriteView.ignoresSiblingOrder = true
        spriteView.preferredFramesPerSecond = 60
        spriteView.presentScene(scene)
        spriteView.wantsLayer = false
        view = spriteView
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        let newSize = view.bounds.size
        if newSize.width > 0, newSize.height > 0, scene.size != newSize {
            scene.size = newSize
        }
    }
}
