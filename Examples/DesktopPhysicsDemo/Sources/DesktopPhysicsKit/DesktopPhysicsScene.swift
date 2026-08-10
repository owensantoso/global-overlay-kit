import AppKit
import MacDesktopWindowGeometry
@preconcurrency import SpriteKit

private enum ResolvedDesktopPlayerAppearance {
    case stickFigure
    case shape(ResolvedDesktopPhysicsShape)
}

@MainActor
final class DesktopPhysicsScene: SKScene {
    private enum Category {
        static let object: UInt32 = 1 << 0
        static let cursor: UInt32 = 1 << 1
        static let boundary: UInt32 = 1 << 2
        static let player: UInt32 = 1 << 3
        static let windowPlatform: UInt32 = 1 << 4
    }

    private static let objectName = "desktop-physics-object"
    private static let playerName = "desktop-physics-player"
    private static let draggableUserDataKey = "desktop-physics-is-draggable"
    private static let traceInterval: TimeInterval = 0.25
    private static let traceDuration: TimeInterval = 8
    private static let geometricPlayerRadius: CGFloat = 24
    private static let throwSampleWindow: TimeInterval = 0.12
    private static let maximumThrowSpeed: CGFloat = 2_400
    private static let gameWorldTransitionDuration: TimeInterval = 0.4
    private static let gameWorldTransitionKey = "desktop-game-world-transition"
    private static let wallRunMaximumDuration: TimeInterval = 0.55
    private static let wallRunVerticalSpeedRatio: CGFloat = 0.55

    private struct ObjectDrag {
        let node: SKNode
        let pointerOffset: CGVector
        let originalZPosition: CGFloat
        let isPlayer: Bool
    }

    private struct DragSample {
        let position: CGPoint
        let timestamp: TimeInterval
    }

    private let palette: [NSColor] = [
        .systemPink, .systemOrange, .systemYellow, .systemGreen,
        .systemMint, .systemCyan, .systemBlue, .systemPurple
    ]
    private let configuration: DesktopPhysicsWorldConfiguration
    private let inputState: DesktopGameInputState
    private var playerControllerProfile: DesktopPlatformerControllerProfile
    private var screenFrame: CGRect
    private var cursorNode: SKShapeNode?
    private let gameWorldBackdrop = SKSpriteNode(color: .white, size: .zero)
    private var playerBoundaryNode: SKNode?
    private var playerNode: SKNode?
    private var stickFigureNode: DesktopStickFigureNode?
    private var playerHalfWidth: CGFloat = 24
    private var playerHalfHeight: CGFloat = 24
    private var playerIsGrounded = false
    private var lastGroundedAt: TimeInterval?
    private var playerWallSide: CGFloat = 0
    private var lastWallSide: CGFloat = 0
    private var lastWallContactAt: TimeInterval?
    private var wallJumpControlLockedUntil: TimeInterval?
    private var wallRunStartedAt: TimeInterval?
    private var jumpState = DesktopPlatformerJumpState()
    private var playerFacing: DesktopCharacterFacing = .right
    private var latestPlayerInput: DesktopGameInputSnapshot?
    private var latestPlayerDelta: TimeInterval = 0
    private var latestAnimationTime: TimeInterval = 0
    private var nextObjectID = 1
    private var traceStartedAt: TimeInterval?
    private var nextTraceAt: TimeInterval?
    private var previousUpdateTime: TimeInterval?
    private var objectDrag: ObjectDrag?
    private var dragSamples: [DragSample] = []
    private var windowPlatformNodes: [String: SKNode] = [:]
    private var windowPlatformSurfaces: [String: DesktopWindowPlatformSurface] = [:]
    private var windowPlatformOutlineNodes: [String: SKNode] = [:]
    private var windowPlatformOutlineSurfaces: [String: DesktopWindowPlatformSurface] = [:]
    private var supportedWindowID: String?
    private var supportedWindowEdge: DesktopWindowPlatformEdge?
    private var supportedWindowY: CGFloat?
    private var ignoredWindowPlatformID: String?
    private var ignoredWindowPlatformY: CGFloat?
    private var playerFootBeforePhysics: CGFloat?
    private var playerPositionBeforePhysics: CGPoint?
    private var gameWorldTransitionGeneration = 0
    private var dragInputCaptureActive = false

    private(set) var objectDraggingEnabled = false
    private(set) var windowPlatformOutlinesVisible = true
    private(set) var playerWindowCollisionEnabled = true
    private(set) var playerWindowSideCollisionEnabled = false
    private(set) var gameWorldModeEnabled = false

    var onDragInputCaptureChange: ((Bool) -> Void)? {
        didSet { onDragInputCaptureChange?(dragInputCaptureActive) }
    }

    var objectCount: Int {
        children.lazy.filter { $0.name == Self.objectName }.count
    }

    var hasPlayer: Bool {
        playerNode != nil
    }

    var cursorCollisionEnabled: Bool {
        cursorNode != nil
    }

    private(set) var cursorColliderDiameter: CGFloat

    var playerIsGroundedForTesting: Bool {
        playerIsGrounded
    }

    var playerVelocityForTesting: CGVector? {
        playerNode?.physicsBody?.velocity
    }

    var playerPositionForTesting: CGPoint? {
        playerNode?.position
    }

    var playerWallSideForTesting: CGFloat {
        playerWallSide
    }

    var playerAnimationStateForTesting: DesktopCharacterAnimationState? {
        stickFigureNode?.animationState
    }

    var windowPlatformFramesForTesting: [String: CGRect] {
        windowPlatformSurfaces.mapValues(\.frame)
    }

    var windowPlatformCount: Int {
        windowPlatformSurfaces.count
    }

    var windowPlatformOutlineCountForTesting: Int {
        windowPlatformOutlineNodes.count
    }

    var playerJumpHeight: CGFloat {
        playerControllerProfile.maximumJumpHeight
    }

    init(
        size: CGSize,
        screenFrame: CGRect,
        configuration: DesktopPhysicsWorldConfiguration,
        inputState: DesktopGameInputState
    ) {
        self.screenFrame = screenFrame
        self.configuration = configuration
        self.inputState = inputState
        playerControllerProfile = configuration.playerController
        cursorColliderDiameter = max(1, configuration.cursorRadius * 2)
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
        physicsWorld.gravity = configuration.gravity
        gameWorldBackdrop.name = "desktop-game-world-backdrop"
        gameWorldBackdrop.size = size
        gameWorldBackdrop.anchorPoint = CGPoint(x: 0, y: 0)
        gameWorldBackdrop.position = .zero
        gameWorldBackdrop.alpha = 0
        gameWorldBackdrop.zPosition = -1_000
        addChild(gameWorldBackdrop)
        installBoundary()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        gameWorldBackdrop.size = size
        installBoundary()
    }

    func spawn(_ request: DesktopPhysicsSpawnRequest) {
        let radius = request.size.resolvedDiameter / 2
        let shape = request.shape.resolve()
        let node = makeShapeNode(shape: shape, radius: radius)
        node.name = Self.objectName
        node.userData = ["id": nextObjectID]
        node.userData?[Self.draggableUserDataKey] = true
        nextObjectID += 1
        node.fillColor = palette.randomElement() ?? .systemBlue
        node.strokeColor = .white
        node.lineWidth = 3
        node.glowWidth = 1.5
        node.position = spawnPosition(radius: radius)
        node.zPosition = 10

        let body = makePhysicsBody(shape: shape, radius: radius)
        body.restitution = configuration.restitution
        body.friction = 0.18
        body.linearDamping = 0.04
        body.angularDamping = 0.04
        body.mass = 0.2 * pow(radius / 24, 2)
        body.categoryBitMask = Category.object
        body.collisionBitMask = Category.object
            | Category.cursor
            | Category.boundary
            | Category.player
            | Category.windowPlatform
        node.physicsBody = body

        addChild(node)
        refreshDragInputCapture()
        traceStartedAt = nil
        nextTraceAt = nil
    }

    func clearObjects() {
        endObjectDrag(applyingThrow: false)
        enumerateChildNodes(withName: Self.objectName) { node, _ in
            node.removeFromParent()
        }
        refreshDragInputCapture()
    }

    func setObjectDraggingEnabled(_ enabled: Bool) {
        guard enabled != objectDraggingEnabled else { return }
        objectDraggingEnabled = enabled
        if !enabled {
            endObjectDrag(applyingThrow: false)
        }
        refreshDragInputCapture()
    }

    func shouldCaptureDragInput(at point: CGPoint?) -> Bool {
        guard objectDraggingEnabled else { return false }
        if objectDrag != nil { return true }
        guard let point else { return false }
        return draggableRoot(at: point) != nil
    }

    @discardableResult
    func beginObjectDrag(
        at point: CGPoint,
        timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) -> Bool {
        guard objectDraggingEnabled else { return false }
        endObjectDrag(applyingThrow: false)
        guard let node = draggableRoot(at: point) else { return false }

        node.physicsBody?.velocity = .zero
        node.physicsBody?.angularVelocity = 0
        node.physicsBody?.isDynamic = false
        let isPlayer = node === playerNode
        if isPlayer {
            playerIsGrounded = false
            lastGroundedAt = nil
            supportedWindowID = nil
            supportedWindowEdge = nil
            supportedWindowY = nil
        }
        let drag = ObjectDrag(
            node: node,
            pointerOffset: CGVector(
                dx: node.position.x - point.x,
                dy: node.position.y - point.y
            ),
            originalZPosition: node.zPosition,
            isPlayer: isPlayer
        )
        node.zPosition = 40
        objectDrag = drag
        dragSamples = [DragSample(position: node.position, timestamp: timestamp)]
        refreshDragInputCapture()
        return true
    }

    func moveObjectDrag(
        to point: CGPoint,
        timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) {
        guard let objectDrag,
              objectDrag.node.parent === self else { return }
        let halfWidth = objectDrag.node.frame.width / 2
        let halfHeight = objectDrag.node.frame.height / 2
        let desired = CGPoint(
            x: point.x + objectDrag.pointerOffset.dx,
            y: point.y + objectDrag.pointerOffset.dy
        )
        objectDrag.node.position = CGPoint(
            x: min(max(desired.x, halfWidth), max(halfWidth, size.width - halfWidth)),
            y: min(max(desired.y, halfHeight), max(halfHeight, size.height - halfHeight))
        )
        recordDragSample(position: objectDrag.node.position, timestamp: timestamp)
    }

    func endObjectDrag(
        timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime,
        applyingThrow: Bool = true
    ) {
        guard let objectDrag else { return }
        recordDragSample(position: objectDrag.node.position, timestamp: timestamp)
        let releaseVelocity = applyingThrow ? measuredThrowVelocity() : .zero
        objectDrag.node.zPosition = objectDrag.originalZPosition
        objectDrag.node.physicsBody?.angularVelocity = 0
        objectDrag.node.physicsBody?.isDynamic = true
        objectDrag.node.physicsBody?.velocity = releaseVelocity
        if objectDrag.isPlayer {
            playerIsGrounded = false
            lastGroundedAt = nil
            playerFootBeforePhysics = nil
            playerPositionBeforePhysics = nil
        }
        self.objectDrag = nil
        dragSamples.removeAll(keepingCapacity: true)
        refreshDragInputCapture()
    }

    private func draggableRoot(at point: CGPoint) -> SKNode? {
        for hit in nodes(at: point) {
            var candidate: SKNode? = hit
            while let node = candidate, node !== self {
                if node.parent === self,
                   node.userData?[Self.draggableUserDataKey] as? Bool == true {
                    return node
                }
                candidate = node.parent
            }
        }
        return nil
    }

    override func mouseDown(with event: NSEvent) {
        _ = beginObjectDrag(
            at: event.location(in: self),
            timestamp: event.timestamp
        )
    }

    override func mouseDragged(with event: NSEvent) {
        moveObjectDrag(
            to: event.location(in: self),
            timestamp: event.timestamp
        )
    }

    override func mouseUp(with event: NSEvent) {
        moveObjectDrag(
            to: event.location(in: self),
            timestamp: event.timestamp
        )
        endObjectDrag(timestamp: event.timestamp)
    }

    private func recordDragSample(position: CGPoint, timestamp: TimeInterval) {
        if dragSamples.last?.timestamp == timestamp {
            dragSamples[dragSamples.count - 1] = DragSample(
                position: position,
                timestamp: timestamp
            )
        } else {
            dragSamples.append(DragSample(position: position, timestamp: timestamp))
        }
        let cutoff = timestamp - Self.throwSampleWindow
        while dragSamples.count > 1, dragSamples[1].timestamp < cutoff {
            dragSamples.removeFirst()
        }
    }

    private func measuredThrowVelocity() -> CGVector {
        guard let first = dragSamples.first,
              let last = dragSamples.last else { return .zero }
        let elapsed = last.timestamp - first.timestamp
        guard elapsed > 1.0 / 240.0 else { return .zero }
        var velocity = CGVector(
            dx: (last.position.x - first.position.x) / elapsed,
            dy: (last.position.y - first.position.y) / elapsed
        )
        let speed = hypot(velocity.dx, velocity.dy)
        if speed > Self.maximumThrowSpeed {
            let scale = Self.maximumThrowSpeed / speed
            velocity.dx *= scale
            velocity.dy *= scale
        }
        return velocity
    }

    func setCursorCollisionEnabled(_ enabled: Bool) {
        guard enabled != cursorCollisionEnabled else { return }
        if enabled {
            installCursorCollider()
        } else {
            cursorNode?.removeFromParent()
            cursorNode = nil
        }
    }

    func setCursorColliderDiameter(_ diameter: CGFloat) {
        cursorColliderDiameter = max(1, diameter)
        guard cursorCollisionEnabled else { return }
        cursorNode?.removeFromParent()
        cursorNode = nil
        installCursorCollider()
    }

    func setWindowPlatforms(_ windows: [MacDesktopWindow]) {
        let pairs: [(String, DesktopWindowPlatformSurface)] = windows.compactMap { window in
            guard window.frame.width >= 2, window.frame.height >= 2 else { return nil }
            return (
                window.id,
                DesktopWindowPlatformSurface(
                    id: window.id,
                    frame: window.frame,
                    hasVisibleTopEdge: window.hasVisibleTopEdge,
                    hasVisibleBottomEdge: window.hasVisibleBottomEdge,
                    hasVisibleLeftEdge: window.hasVisibleLeftEdge,
                    hasVisibleRightEdge: window.hasVisibleRightEdge
                )
            )
        }
        let newSurfaces = Dictionary(uniqueKeysWithValues: pairs)

        for (id, node) in windowPlatformNodes where newSurfaces[id] == nil {
            node.removeFromParent()
            windowPlatformNodes[id] = nil
        }

        for (id, surface) in newSurfaces {
            if let node = windowPlatformNodes[id],
               windowPlatformSurfaces[id]?.frame.size == surface.frame.size {
                node.position = CGPoint(x: surface.frame.midX, y: surface.frame.midY)
                continue
            }

            windowPlatformNodes[id]?.removeFromParent()
            let node = SKNode()
            node.name = "desktop-window-platform-\(id)"
            node.position = CGPoint(x: surface.frame.midX, y: surface.frame.midY)
            let body = SKPhysicsBody(rectangleOf: surface.frame.size)
            body.isDynamic = false
            body.restitution = configuration.restitution
            body.friction = 0.22
            body.categoryBitMask = Category.windowPlatform
            body.collisionBitMask = Category.object
            node.physicsBody = body
            addChild(node)
            windowPlatformNodes[id] = node
        }

        windowPlatformSurfaces = newSurfaces
        if let supportedWindowID, newSurfaces[supportedWindowID] == nil {
            self.supportedWindowID = nil
            supportedWindowEdge = nil
            supportedWindowY = nil
        }
        if let ignoredWindowPlatformID, newSurfaces[ignoredWindowPlatformID] == nil {
            self.ignoredWindowPlatformID = nil
            ignoredWindowPlatformY = nil
        }
        syncWindowPlatformOutlines()
    }

    func setWindowPlatformOutlinesVisible(_ visible: Bool) {
        guard visible != windowPlatformOutlinesVisible else { return }
        windowPlatformOutlinesVisible = visible
        syncWindowPlatformOutlines()
    }

    func setPlayerWindowCollisionEnabled(_ enabled: Bool) {
        guard enabled != playerWindowCollisionEnabled else { return }
        playerWindowCollisionEnabled = enabled
        if !enabled {
            supportedWindowID = nil
            supportedWindowEdge = nil
            supportedWindowY = nil
        }
        rebuildWindowPlatformOutlines()
    }

    func setPlayerWindowSideCollisionEnabled(_ enabled: Bool) {
        guard enabled != playerWindowSideCollisionEnabled else { return }
        playerWindowSideCollisionEnabled = enabled
        rebuildWindowPlatformOutlines()
    }

    func setGameWorldModeEnabled(
        _ enabled: Bool,
        reduceMotion: Bool = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    ) {
        guard enabled != gameWorldModeEnabled else { return }
        gameWorldModeEnabled = enabled
        gameWorldTransitionGeneration += 1
        let generation = gameWorldTransitionGeneration
        gameWorldBackdrop.removeAction(forKey: Self.gameWorldTransitionKey)
        syncWindowPlatformOutlines()

        let targetAlpha: CGFloat = enabled ? 1 : 0
        if reduceMotion || abs(gameWorldBackdrop.alpha - targetAlpha) < 0.001 {
            gameWorldBackdrop.alpha = targetAlpha
            updateGameWorldPresentationProgress()
            syncWindowPlatformOutlines()
            return
        }

        let duration = Self.gameWorldTransitionDuration
            * TimeInterval(abs(gameWorldBackdrop.alpha - targetAlpha))
        let fade = SKAction.fadeAlpha(to: targetAlpha, duration: duration)
        fade.timingMode = .easeInEaseOut
        let finish = SKAction.run { [weak self] in
            guard let self,
                  self.gameWorldTransitionGeneration == generation else { return }
            self.gameWorldBackdrop.alpha = targetAlpha
            self.updateGameWorldPresentationProgress()
            self.syncWindowPlatformOutlines()
        }
        gameWorldBackdrop.run(
            .sequence([fade, finish]),
            withKey: Self.gameWorldTransitionKey
        )
    }

    func setPlayerJumpHeight(_ height: CGFloat) {
        let clamped = min(max(height, 40), max(40, size.height * 0.95))
        let tapRatio = playerControllerProfile.minimumJumpHeight
            / max(1, playerControllerProfile.maximumJumpHeight)
        playerControllerProfile.maximumJumpHeight = clamped
        playerControllerProfile.minimumJumpHeight = clamped * tapRatio
        playerControllerProfile.wallJumpVerticalSpeed = playerControllerProfile.jumpVelocity
    }

    private func syncWindowPlatformOutlines() {
        let gamePresentationVisible = gameWorldModeEnabled || gameWorldBackdrop.alpha > 0.001
        guard windowPlatformOutlinesVisible || gamePresentationVisible else {
            for node in windowPlatformOutlineNodes.values {
                node.removeFromParent()
            }
            windowPlatformOutlineNodes.removeAll(keepingCapacity: true)
            windowPlatformOutlineSurfaces.removeAll(keepingCapacity: true)
            return
        }

        for (id, node) in windowPlatformOutlineNodes where windowPlatformSurfaces[id] == nil {
            node.removeFromParent()
            windowPlatformOutlineNodes[id] = nil
            windowPlatformOutlineSurfaces[id] = nil
        }

        for (id, surface) in windowPlatformSurfaces {
            if let node = windowPlatformOutlineNodes[id],
               let previous = windowPlatformOutlineSurfaces[id],
               previous.frame.size == surface.frame.size,
               previous.hasVisibleTopEdge == surface.hasVisibleTopEdge,
               previous.hasVisibleBottomEdge == surface.hasVisibleBottomEdge,
               previous.hasVisibleLeftEdge == surface.hasVisibleLeftEdge,
               previous.hasVisibleRightEdge == surface.hasVisibleRightEdge {
                node.position = CGPoint(x: surface.frame.midX, y: surface.frame.midY)
                windowPlatformOutlineSurfaces[id] = surface
                continue
            }

            windowPlatformOutlineNodes[id]?.removeFromParent()
            let node = makeWindowPlatformOutline(
                id: id,
                surface: surface
            )
            node.position = CGPoint(x: surface.frame.midX, y: surface.frame.midY)
            addChild(node)
            windowPlatformOutlineNodes[id] = node
            windowPlatformOutlineSurfaces[id] = surface
        }
        updateGameWorldPresentationProgress()
    }

    private func rebuildWindowPlatformOutlines() {
        for node in windowPlatformOutlineNodes.values {
            node.removeFromParent()
        }
        windowPlatformOutlineNodes.removeAll(keepingCapacity: true)
        windowPlatformOutlineSurfaces.removeAll(keepingCapacity: true)
        syncWindowPlatformOutlines()
    }

    private func updateGameWorldPresentationProgress() {
        let progress = min(max(gameWorldBackdrop.alpha, 0), 1)
        for node in windowPlatformOutlineNodes.values {
            for child in node.children where child.name != "game-world-platform-lines" {
                child.alpha = windowPlatformOutlinesVisible ? 1 - progress : 0
            }
            node.childNode(withName: "game-world-platform-lines")?.alpha = progress
        }
    }

    private func makeWindowPlatformOutline(
        id: String,
        surface: DesktopWindowPlatformSurface
    ) -> SKNode {
        let size = surface.frame.size
        let container = SKNode()
        container.name = "desktop-window-platform-outline-\(id)"
        container.zPosition = 5

        let rectangle = SKShapeNode(rectOf: size)
        rectangle.name = "solid-object-rectangle"
        rectangle.fillColor = .clear
        rectangle.strokeColor = NSColor.systemCyan.withAlphaComponent(0.82)
        rectangle.lineWidth = 2
        rectangle.glowWidth = 0.75
        rectangle.isAntialiased = true
        container.addChild(rectangle)

        let left = -size.width / 2
        let right = size.width / 2
        if surface.hasVisibleTopEdge {
            let topPath = CGMutablePath()
            let top = size.height / 2
            topPath.move(to: CGPoint(x: left, y: top - 7))
            topPath.addLine(to: CGPoint(x: left, y: top))
            topPath.addLine(to: CGPoint(x: right, y: top))
            topPath.addLine(to: CGPoint(x: right, y: top - 7))
            let oneWayTop = SKShapeNode(path: topPath)
            oneWayTop.name = "player-one-way-top-edge"
            oneWayTop.strokeColor = .systemYellow
            oneWayTop.lineWidth = 5
            oneWayTop.glowWidth = 1.5
            oneWayTop.isAntialiased = true
            container.addChild(oneWayTop)
        }

        if surface.hasVisibleBottomEdge {
            let bottomPath = CGMutablePath()
            let bottom = -size.height / 2
            bottomPath.move(to: CGPoint(x: left, y: bottom + 7))
            bottomPath.addLine(to: CGPoint(x: left, y: bottom))
            bottomPath.addLine(to: CGPoint(x: right, y: bottom))
            bottomPath.addLine(to: CGPoint(x: right, y: bottom + 7))
            let oneWayBottom = SKShapeNode(path: bottomPath)
            oneWayBottom.name = "player-one-way-bottom-edge"
            oneWayBottom.strokeColor = .systemYellow
            oneWayBottom.lineWidth = 5
            oneWayBottom.glowWidth = 1.5
            oneWayBottom.isAntialiased = true
            container.addChild(oneWayBottom)
        }

        let gameLines = SKNode()
        gameLines.name = "game-world-platform-lines"
        gameLines.alpha = gameWorldBackdrop.alpha
        if playerWindowCollisionEnabled {
            if surface.hasVisibleTopEdge {
                gameLines.addChild(makeGameWorldLine(
                    from: CGPoint(x: left, y: size.height / 2),
                    to: CGPoint(x: right, y: size.height / 2),
                    name: "game-world-top-edge"
                ))
            }
            if surface.hasVisibleBottomEdge {
                gameLines.addChild(makeGameWorldLine(
                    from: CGPoint(x: left, y: -size.height / 2),
                    to: CGPoint(x: right, y: -size.height / 2),
                    name: "game-world-bottom-edge"
                ))
            }
        }
        if playerWindowSideCollisionEnabled {
            if surface.hasVisibleLeftEdge {
                gameLines.addChild(makeGameWorldLine(
                    from: CGPoint(x: left, y: -size.height / 2),
                    to: CGPoint(x: left, y: size.height / 2),
                    name: "game-world-left-edge"
                ))
            }
            if surface.hasVisibleRightEdge {
                gameLines.addChild(makeGameWorldLine(
                    from: CGPoint(x: right, y: -size.height / 2),
                    to: CGPoint(x: right, y: size.height / 2),
                    name: "game-world-right-edge"
                ))
            }
        }
        container.addChild(gameLines)

        return container
    }

    private func makeGameWorldLine(
        from start: CGPoint,
        to end: CGPoint,
        name: String
    ) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)
        let line = SKShapeNode(path: path)
        line.name = name
        line.strokeColor = .black
        line.lineWidth = 4
        line.isAntialiased = true
        return line
    }

    private func installCursorCollider() {
            let radius = cursorColliderDiameter / 2
            let cursor = SKShapeNode(circleOfRadius: radius)
            cursor.name = "desktop-cursor-collider"
            cursor.fillColor = NSColor.white.withAlphaComponent(0.08)
            cursor.strokeColor = NSColor.white.withAlphaComponent(0.5)
            cursor.lineWidth = 1.5
            cursor.zPosition = 30
            let body = SKPhysicsBody(circleOfRadius: radius)
            body.isDynamic = false
            body.categoryBitMask = Category.cursor
            body.collisionBitMask = Category.object | Category.player
            cursor.physicsBody = body
            addChild(cursor)
            cursorNode = cursor
    }

    func spawnPlayer(appearance requestedAppearance: DesktopPlayerAppearance = .stickFigure) {
        playerNode?.removeFromParent()
        playerNode = nil
        stickFigureNode = nil
        playerIsGrounded = false
        lastGroundedAt = nil
        playerWallSide = 0
        lastWallSide = 0
        lastWallContactAt = nil
        wallJumpControlLockedUntil = nil
        wallRunStartedAt = nil
        jumpState = DesktopPlatformerJumpState()
        supportedWindowID = nil
        supportedWindowEdge = nil
        supportedWindowY = nil
        ignoredWindowPlatformID = nil
        ignoredWindowPlatformY = nil
        playerFootBeforePhysics = nil
        playerFacing = .right
        inputState.consumeJumpRequest()
        let appearance = resolvedPlayerAppearance(requestedAppearance)

        let player: SKNode
        let body: SKPhysicsBody
        switch appearance {
        case .stickFigure:
            let root = SKNode()
            let figure = DesktopStickFigureNode()
            root.addChild(figure)
            player = root
            stickFigureNode = figure
            playerHalfWidth = DesktopStickFigureNode.collisionSize.width / 2
            playerHalfHeight = DesktopStickFigureNode.collisionSize.height / 2
            body = SKPhysicsBody(rectangleOf: DesktopStickFigureNode.collisionSize)
        case let .shape(shape):
            let radius = Self.geometricPlayerRadius
            let visual = makeShapeNode(shape: shape, radius: radius)
            visual.fillColor = .white
            visual.strokeColor = .systemCyan
            visual.lineWidth = 5
            visual.glowWidth = 3
            player = visual
            playerHalfWidth = radius
            playerHalfHeight = radius
            body = makePhysicsBody(shape: shape, radius: radius)
        }

        player.name = Self.playerName
        player.userData = [Self.draggableUserDataKey: true]
        player.zPosition = 20
        player.position = CGPoint(x: size.width / 2, y: playerHalfHeight + 8)
        body.allowsRotation = false
        body.restitution = 0
        body.friction = 0
        body.linearDamping = 0
        body.categoryBitMask = Category.player
        body.collisionBitMask = Category.object | Category.cursor | Category.boundary
        body.contactTestBitMask = Category.object | Category.boundary
        body.usesPreciseCollisionDetection = true
        player.physicsBody = body

        addChild(player)
        playerNode = player
        refreshDragInputCapture()
    }

    func setPlayerPositionForTesting(_ position: CGPoint) {
        playerNode?.position = position
        playerNode?.physicsBody?.velocity = .zero
    }

    func setPlayerVelocityForTesting(_ velocity: CGVector) {
        playerNode?.physicsBody?.velocity = velocity
    }

    override func update(_ currentTime: TimeInterval) {
        updateCursor()
        refreshDragInputCapture()
        playerFootBeforePhysics = playerNode.map { $0.position.y - playerHalfHeight }
        playerPositionBeforePhysics = playerNode?.position
        updatePlayer(currentTime: currentTime)
        updateGameWorldPresentationProgress()
        traceIfNeeded(currentTime)
    }

    override func didSimulatePhysics() {
        super.didSimulatePhysics()
        updatePlayerContacts()
        resolveWindowPlatformContact()
        resolveWindowSideContact()
        clampPlayerFallSpeedAfterPhysics()
        updatePlayerAnimation()
    }

    static func localCursorPosition(global: CGPoint, screenFrame: CGRect) -> CGPoint? {
        guard screenFrame.contains(global) else { return nil }
        return CGPoint(x: global.x - screenFrame.minX, y: global.y - screenFrame.minY)
    }

    private func refreshDragInputCapture() {
        let local = Self.localCursorPosition(
            global: NSEvent.mouseLocation,
            screenFrame: screenFrame
        )
        let next = shouldCaptureDragInput(at: local)
        guard next != dragInputCaptureActive else { return }
        dragInputCaptureActive = next
        onDragInputCaptureChange?(next)
    }

    private func makeShapeNode(
        shape: ResolvedDesktopPhysicsShape,
        radius: CGFloat
    ) -> SKShapeNode {
        switch shape {
        case .circle:
            SKShapeNode(circleOfRadius: radius)
        case .square:
            SKShapeNode(rectOf: CGSize(width: radius * 2, height: radius * 2), cornerRadius: 2)
        case .triangle:
            SKShapeNode(path: trianglePath(radius: radius))
        }
    }

    private func resolvedPlayerAppearance(
        _ appearance: DesktopPlayerAppearance
    ) -> ResolvedDesktopPlayerAppearance {
        let resolved: DesktopPlayerAppearance
        if appearance == .random {
            resolved = [
                DesktopPlayerAppearance.stickFigure,
                .circle,
                .square,
                .triangle
            ].randomElement() ?? .stickFigure
        } else {
            resolved = appearance
        }

        switch resolved {
        case .stickFigure, .random:
            return .stickFigure
        case .circle:
            return .shape(.circle)
        case .square:
            return .shape(.square)
        case .triangle:
            return .shape(.triangle)
        }
    }

    private func makePhysicsBody(
        shape: ResolvedDesktopPhysicsShape,
        radius: CGFloat
    ) -> SKPhysicsBody {
        switch shape {
        case .circle:
            SKPhysicsBody(circleOfRadius: radius)
        case .square:
            SKPhysicsBody(rectangleOf: CGSize(width: radius * 2, height: radius * 2))
        case .triangle:
            SKPhysicsBody(polygonFrom: trianglePath(radius: radius))
        }
    }

    private func trianglePath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: radius))
        path.addLine(to: CGPoint(x: -radius, y: -radius))
        path.addLine(to: CGPoint(x: radius, y: -radius))
        path.closeSubpath()
        return path
    }

    private func spawnPosition(radius: CGFloat) -> CGPoint {
        let inset = radius + 12
        let maximumX = max(inset, size.width - inset)
        return CGPoint(
            x: CGFloat.random(in: inset...maximumX),
            y: max(radius, size.height - radius - 12)
        )
    }

    private func installBoundary() {
        playerBoundaryNode?.removeFromParent()
        playerBoundaryNode = nil
        guard size.width > 0, size.height > 0 else {
            physicsBody = nil
            return
        }
        let objectBoundary = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: size))
        objectBoundary.restitution = configuration.restitution
        objectBoundary.friction = 0.22
        objectBoundary.categoryBitMask = Category.boundary
        objectBoundary.collisionBitMask = Category.object
        physicsBody = objectBoundary

        let playerPath = CGMutablePath()
        playerPath.move(to: CGPoint(x: 0, y: size.height))
        playerPath.addLine(to: .zero)
        playerPath.addLine(to: CGPoint(x: size.width, y: 0))
        playerPath.addLine(to: CGPoint(x: size.width, y: size.height))
        let playerBoundary = SKPhysicsBody(edgeChainFrom: playerPath)
        playerBoundary.restitution = 0
        playerBoundary.friction = 0.22
        playerBoundary.categoryBitMask = Category.boundary
        playerBoundary.collisionBitMask = Category.player
        let node = SKNode()
        node.name = "desktop-player-open-top-boundary"
        node.physicsBody = playerBoundary
        addChild(node)
        playerBoundaryNode = node
    }

    private func updateCursor() {
        guard let cursorNode else { return }
        guard let local = Self.localCursorPosition(
            global: NSEvent.mouseLocation,
            screenFrame: screenFrame
        ) else {
            cursorNode.isHidden = true
            cursorNode.physicsBody?.collisionBitMask = 0
            return
        }
        cursorNode.isHidden = false
        cursorNode.physicsBody?.collisionBitMask = Category.object | Category.player
        cursorNode.position = local
    }

    private func updatePlayer(currentTime: TimeInterval) {
        defer { previousUpdateTime = currentTime }
        guard let playerNode,
              objectDrag?.node !== playerNode,
              let body = playerNode.physicsBody else { return }
        let profile = playerControllerProfile
        let now = inputState.currentMonotonicTime()
        inputState.discardJumpRequest(olderThan: now - profile.jumpBufferTime)
        inputState.discardDropThroughRequest(olderThan: now - profile.jumpBufferTime)
        let snapshot = inputState.consumeSnapshot()
        let delta = min(max(currentTime - (previousUpdateTime ?? currentTime), 0), 1.0 / 20.0)
        latestPlayerInput = snapshot
        latestPlayerDelta = delta
        latestAnimationTime = currentTime

        if snapshot.horizontalDirection != 0 {
            playerFacing = snapshot.horizontalDirection < 0 ? .left : .right
        }

        if let lockedUntil = wallJumpControlLockedUntil, now >= lockedUntil {
            wallJumpControlLockedUntil = nil
        }
        let steeringLocked = wallJumpControlLockedUntil.map { now < $0 } ?? false
        let sitting = snapshot.sitting && playerIsGrounded
        let requestedDirection: CGFloat = sitting ? 0 : snapshot.horizontalDirection
        let maximumSpeed = profile.maximumHorizontalSpeed(running: snapshot.runHeld)
        let targetVelocity = requestedDirection * maximumSpeed
        let hasInput = requestedDirection != 0
        let reversing = hasInput && body.velocity.dx != 0
            && body.velocity.dx.sign != targetVelocity.sign
        let baseAcceleration: CGFloat
        if reversing {
            baseAcceleration = profile.reversalAcceleration
        } else if hasInput {
            baseAcceleration = maximumSpeed / max(0.01, profile.timeToMaximumSpeed)
        } else {
            baseAcceleration = maximumSpeed / max(0.01, profile.timeToStop)
        }
        let acceleration = playerIsGrounded
            ? baseAcceleration
            : baseAcceleration * profile.airControlRatio
        if !steeringLocked {
            let maximumChange = acceleration * delta
            let difference = targetVelocity - body.velocity.dx
            body.velocity.dx += min(max(difference, -maximumChange), maximumChange)
        }

        let recentlyGrounded = lastGroundedAt.map {
            now - $0 <= profile.coyoteTime
        } ?? false
        let bufferedJump = snapshot.jumpPressedAt.map {
            now - $0 <= profile.jumpBufferTime
        } ?? false
        let bufferedDropThrough = snapshot.dropThroughPressedAt.map {
            now - $0 <= profile.jumpBufferTime
        } ?? false
        let recentWallSide: CGFloat
        if let lastWallContactAt,
           now - lastWallContactAt <= profile.wallContactGraceTime {
            recentWallSide = lastWallSide
        } else {
            recentWallSide = 0
        }
        if bufferedDropThrough {
            if let supportedWindowID, let supportedWindowY {
                ignoredWindowPlatformID = supportedWindowID
                ignoredWindowPlatformY = supportedWindowY
                self.supportedWindowID = nil
                supportedWindowEdge = nil
                self.supportedWindowY = nil
                playerIsGrounded = false
                lastGroundedAt = nil
                playerNode.position.y -= 3
                body.velocity.dy = min(body.velocity.dy, -80)
            }
            inputState.consumeDropThroughRequest()
        } else if bufferedJump, recentWallSide != 0 {
            body.velocity.dx = -recentWallSide * profile.wallJumpHorizontalSpeed
            body.velocity.dy = profile.wallJumpVerticalSpeed
            playerFacing = recentWallSide < 0 ? .right : .left
            playerWallSide = 0
            lastWallContactAt = nil
            wallRunStartedAt = nil
            wallJumpControlLockedUntil = now + profile.wallJumpSteeringLockTime
            inputState.consumeJumpRequest()
        } else {
            let jumpAction = jumpState.decide(
                jumpRequested: bufferedJump,
                dropThroughRequested: false,
                canUseGroundJump: playerIsGrounded || recentlyGrounded
            )
            switch jumpAction {
            case .groundJump, .airJump:
                body.velocity.dy = profile.jumpVelocity
                playerIsGrounded = false
                lastGroundedAt = nil
                wallRunStartedAt = nil
                inputState.consumeJumpRequest()
            case .dropThrough, .none:
                break
            }
        }
        if !snapshot.jumpHeld,
                  body.velocity.dy > profile.releaseVelocityCap {
            body.velocity.dy = profile.releaseVelocityCap
        }

        let wallRunning = isPlayerWallRunning(snapshot: snapshot, now: now)
        if wallRunning {
            body.velocity.dy = max(
                body.velocity.dy,
                profile.jumpVelocity * Self.wallRunVerticalSpeedRatio
            )
        }
        let wallSliding = isPlayerWallSliding(snapshot: snapshot, body: body)
        let desiredGravity: CGFloat
        if wallRunning {
            desiredGravity = 0
        } else if wallSliding {
            desiredGravity = profile.riseGravity * 0.08
        } else if body.velocity.dy < 0 {
            desiredGravity = profile.riseGravity * profile.fallGravityMultiplier
        } else {
            desiredGravity = profile.riseGravity
        }
        let worldGravity = configuration.gravity.dy
        body.applyForce(CGVector(
            dx: 0,
            dy: (-desiredGravity - worldGravity) * body.mass
        ))
        let maximumFallSpeed = wallSliding || wallRunning
            ? profile.maximumWallSlideFallSpeed
            : profile.terminalFallSpeed
        body.velocity.dy = max(body.velocity.dy, -maximumFallSpeed)
    }

    private func updatePlayerContacts() {
        guard let playerNode else {
            playerIsGrounded = false
            playerWallSide = 0
            return
        }
        let profile = playerControllerProfile
        let footY = playerNode.position.y - playerHalfHeight
        let probeInset = playerHalfWidth * 0.55
        let minimumNormalY = cos(profile.maximumFloorAngleDegrees * .pi / 180)
        var foundGround = false

        for xOffset in [-probeInset, probeInset] where !foundGround {
            let start = CGPoint(x: playerNode.position.x + xOffset, y: footY + 3)
            let end = CGPoint(
                x: start.x,
                y: footY - profile.groundProbeDistance
            )
            physicsWorld.enumerateBodies(
                alongRayStart: start,
                end: end
            ) { body, _, normal, stop in
                let category = body.categoryBitMask
                guard category != Category.player,
                      category != Category.cursor,
                      category != Category.windowPlatform,
                      normal.dy >= minimumNormalY else { return }
                foundGround = true
                stop.pointee = true
            }
        }

        playerIsGrounded = foundGround
        if foundGround {
            lastGroundedAt = inputState.currentMonotonicTime()
            jumpState.land()
            wallRunStartedAt = nil
        }

        guard profile.wallProbeDistance > 0 else {
            playerWallSide = 0
            return
        }
        let minimumWallNormalX = cos(profile.maximumFloorAngleDegrees * .pi / 180)
        var foundWallSide: CGFloat = 0
        for side: CGFloat in [-1, 1] where foundWallSide == 0 {
            let sideX = playerNode.position.x + side * playerHalfWidth
            let yOffsets = [
                -playerHalfHeight * 0.55,
                CGFloat.zero,
                playerHalfHeight * 0.55
            ]
            for yOffset in yOffsets where foundWallSide == 0 {
                let start = CGPoint(
                    x: sideX - side * 2,
                    y: playerNode.position.y + yOffset
                )
                let end = CGPoint(
                    x: sideX + side * profile.wallProbeDistance,
                    y: start.y
                )
                physicsWorld.enumerateBodies(
                    alongRayStart: start,
                    end: end
                ) { body, _, normal, stop in
                    let category = body.categoryBitMask
                    guard category == Category.boundary || category == Category.object,
                          abs(normal.dx) >= minimumWallNormalX else { return }
                    foundWallSide = side
                    stop.pointee = true
                }
            }
        }

        if foundWallSide == 0,
           playerWindowSideCollisionEnabled,
           let visibleSide = visibleWindowWallSide(
            for: playerNode.position,
            probeDistance: profile.wallProbeDistance
           ) {
            foundWallSide = visibleSide
        }

        playerWallSide = foundWallSide
        if foundWallSide != 0 {
            lastWallSide = foundWallSide
            lastWallContactAt = inputState.currentMonotonicTime()
        }
    }

    private func visibleWindowWallSide(
        for playerPosition: CGPoint,
        probeDistance: CGFloat
    ) -> CGFloat? {
        let playerVerticalRange = (playerPosition.y - playerHalfHeight)...(playerPosition.y + playerHalfHeight)
        for side: CGFloat in [-1, 1] {
            let playerSideX = playerPosition.x + side * playerHalfWidth
            for surface in windowPlatformSurfaces.values
            where playerVerticalRange.overlaps(surface.frame.minY...surface.frame.maxY) {
                let edgeXs = visibleSideEdgeXs(for: surface)
                if edgeXs.contains(where: { abs($0 - playerSideX) <= probeDistance + 2 }) {
                    return side
                }
            }
        }
        return nil
    }

    private func resolveWindowSideContact() {
        guard playerWindowSideCollisionEnabled,
              let playerNode,
              let body = playerNode.physicsBody,
              let previousPosition = playerPositionBeforePhysics,
              objectDrag?.node !== playerNode else { return }
        let verticalRange = (playerNode.position.y - playerHalfHeight)...(playerNode.position.y + playerHalfHeight)
        guard let collision = DesktopWindowPlatformPolicy.sideCollision(
            previousCenterX: previousPosition.x,
            currentCenterX: playerNode.position.x,
            playerHalfWidth: playerHalfWidth,
            playerVerticalRange: verticalRange,
            surfaces: Array(windowPlatformSurfaces.values)
        ) else { return }

        playerNode.position.x = collision.edgeX - collision.wallSide * playerHalfWidth
        body.velocity.dx = 0
        playerWallSide = collision.wallSide
        lastWallSide = collision.wallSide
        lastWallContactAt = inputState.currentMonotonicTime()
    }

    private func visibleSideEdgeXs(
        for surface: DesktopWindowPlatformSurface
    ) -> [CGFloat] {
        var result: [CGFloat] = []
        if surface.hasVisibleLeftEdge { result.append(surface.frame.minX) }
        if surface.hasVisibleRightEdge { result.append(surface.frame.maxX) }
        return result
    }

    private func resolveWindowPlatformContact() {
        guard playerWindowCollisionEnabled,
              let playerNode,
              let body = playerNode.physicsBody,
              let previousFootY = playerFootBeforePhysics else {
            supportedWindowID = nil
            supportedWindowEdge = nil
            supportedWindowY = nil
            return
        }

        let horizontalRange = ClosedRange(
            uncheckedBounds: (
                lower: playerNode.position.x - playerHalfWidth,
                upper: playerNode.position.x + playerHalfWidth
            )
        )
        if let supportedWindowID,
           let supportedWindowEdge,
           let previousSurfaceY = supportedWindowY,
           let surface = windowPlatformSurfaces[supportedWindowID],
           let centerY = DesktopWindowPlatformPolicy.supportedPlayerCenterY(
            previousPlatformY: previousSurfaceY,
            edge: supportedWindowEdge,
            currentPlatformFrame: surface.frame,
            previousFootY: previousFootY,
            verticalVelocity: body.velocity.dy,
            playerHorizontalRange: horizontalRange,
            playerHalfHeight: playerHalfHeight,
            sceneHeight: size.height,
            maximumPlatformStep: max(12, playerHalfHeight)
           ) {
            playerNode.position.y = centerY
            body.velocity.dy = 0
            playerIsGrounded = true
            lastGroundedAt = inputState.currentMonotonicTime()
            jumpState.land()
            wallRunStartedAt = nil
            supportedWindowY = supportedWindowEdge.surfaceY(in: surface.frame)
            return
        }

        supportedWindowID = nil
        supportedWindowEdge = nil
        supportedWindowY = nil
        guard playerIsGrounded == false else { return }

        let currentFootY = playerNode.position.y - playerHalfHeight
        if let ignoredWindowPlatformY,
           DesktopWindowPlatformPolicy.shouldClearIgnoredSurface(
            previousFootY: previousFootY,
            ignoredSurfaceY: ignoredWindowPlatformY
           ) {
            ignoredWindowPlatformID = nil
            self.ignoredWindowPlatformY = nil
        }
        let landingSurfaces = windowPlatformSurfaces.values.filter {
            $0.id != ignoredWindowPlatformID
        }
        guard let landing = DesktopWindowPlatformPolicy.landing(
            previousFootY: previousFootY,
            currentFootY: currentFootY,
            verticalVelocity: body.velocity.dy,
            playerHorizontalRange: horizontalRange,
            surfaces: landingSurfaces,
            ignoredSurfaceY: ignoredWindowPlatformY
        ) else { return }

        playerNode.position.y = landing.surfaceY + playerHalfHeight
        body.velocity.dy = 0
        playerIsGrounded = true
        lastGroundedAt = inputState.currentMonotonicTime()
        jumpState.land()
        wallRunStartedAt = nil
        supportedWindowID = landing.id
        supportedWindowEdge = landing.edge
        supportedWindowY = landing.surfaceY
    }

    private func isPlayerWallSliding(
        snapshot: DesktopGameInputSnapshot,
        body: SKPhysicsBody
    ) -> Bool {
        !playerIsGrounded
            && playerWallSide != 0
            && snapshot.horizontalDirection == playerWallSide
            && body.velocity.dy <= 0
    }

    private func isPlayerWallRunning(
        snapshot: DesktopGameInputSnapshot,
        now: TimeInterval
    ) -> Bool {
        let requested = playerWindowSideCollisionEnabled
            && !playerIsGrounded
            && playerWallSide != 0
            && snapshot.wallRunIntentDirection == playerWallSide
        guard requested else {
            wallRunStartedAt = nil
            return false
        }
        if wallRunStartedAt == nil {
            wallRunStartedAt = now
        }
        return now - (wallRunStartedAt ?? now) <= Self.wallRunMaximumDuration
    }

    private func clampPlayerFallSpeedAfterPhysics() {
        guard let body = playerNode?.physicsBody,
              let snapshot = latestPlayerInput else { return }
        let profile = playerControllerProfile
        let wallRunning = isPlayerWallRunning(
            snapshot: snapshot,
            now: inputState.currentMonotonicTime()
        )
        let maximumFallSpeed = wallRunning || isPlayerWallSliding(snapshot: snapshot, body: body)
            ? profile.maximumWallSlideFallSpeed
            : profile.terminalFallSpeed
        body.velocity.dy = max(body.velocity.dy, -maximumFallSpeed)
    }

    private func updatePlayerAnimation() {
        guard let figure = stickFigureNode,
              let body = playerNode?.physicsBody,
              let snapshot = latestPlayerInput else { return }
        let wallMovement = isPlayerWallRunning(
            snapshot: snapshot,
            now: inputState.currentMonotonicTime()
        ) || isPlayerWallSliding(snapshot: snapshot, body: body)
        if wallMovement {
            playerFacing = playerWallSide < 0 ? .left : .right
        }
        let state = DesktopCharacterAnimationState.resolve(
            grounded: playerIsGrounded,
            wallSliding: wallMovement,
            sitting: snapshot.sitting,
            horizontalSpeed: body.velocity.dx,
            running: snapshot.runHeld,
            facing: playerFacing
        )
        figure.update(
            state: state,
            time: latestAnimationTime,
            delta: latestPlayerDelta,
            verticalVelocity: body.velocity.dy,
            reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        )
    }

    private func traceIfNeeded(_ currentTime: TimeInterval) {
        let environmentEnabled = ProcessInfo.processInfo.environment["DESKTOP_PHYSICS_TRACE"] == "1"
        guard configuration.trajectoryTracingEnabled || environmentEnabled else { return }
        let traced = children.filter {
            $0.name == Self.objectName || $0.name == Self.playerName
        }
        guard !traced.isEmpty else { return }
        if traceStartedAt == nil {
            traceStartedAt = currentTime
            nextTraceAt = currentTime
        }
        guard let traceStartedAt,
              currentTime - traceStartedAt <= Self.traceDuration,
              currentTime >= (nextTraceAt ?? currentTime) else { return }

        let samples = traced.prefix(6).map { node in
            let id = node.userData?["id"] as? Int ?? 0
            let velocity = node.physicsBody?.velocity ?? .zero
            let label = node.name == Self.playerName ? "player" : "#\(id)"
            return String(
                format: "%@ p=(%.1f,%.1f) v=(%.1f,%.1f) resting=%@",
                label, node.position.x, node.position.y,
                velocity.dx, velocity.dy,
                (node.physicsBody?.isResting ?? false).description
            )
        }
        print(String(
            format: "[PhysicsTrace] t=%.2f %@",
            currentTime - traceStartedAt,
            samples.joined(separator: " | ")
        ))
        nextTraceAt = currentTime + Self.traceInterval
    }
}
