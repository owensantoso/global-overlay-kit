import AppKit
import CoreGraphics
import DesktopGameCore
import SpriteKit
import XCTest
@testable import DesktopPhysicsKit
@testable import MacDesktopWindowGeometry

private final class TestMonotonicClock: @unchecked Sendable {
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

final class DesktopPhysicsKitTests: XCTestCase {
    @MainActor
    func testStickFigurePaintedCoverageUsesCurrentShippedFrameAndMirroring() throws {
        let scene = SKScene(size: CGSize(width: 800, height: 600))
        let figure = DesktopStickFigureNode()
        figure.position = CGPoint(x: 300, y: 260)
        figure.setScale(1.35)
        figure.zRotation = 0.27
        scene.addChild(figure)
        let sprite = try XCTUnwrap(figure.children.first as? SKSpriteNode)
        let sourcePoint = CGPoint(
            x: 150.0 / 512.0,
            y: 1.0 - 300.0 / 512.0
        )
        let localPoint = CGPoint(
            x: (sourcePoint.x - sprite.anchorPoint.x) * sprite.size.width,
            y: (sourcePoint.y - sprite.anchorPoint.y) * sprite.size.height
        )

        figure.update(
            state: .init(motion: .idle, facing: .right),
            time: 1,
            delta: 0,
            verticalVelocity: 0,
            reduceMotion: true
        )
        let idleScenePoint = sprite.convert(localPoint, to: scene)
        XCTAssertFalse(figure.isPainted(at: idleScenePoint, in: scene))

        figure.update(
            state: .init(motion: .sit, facing: .right),
            time: 2,
            delta: 0,
            verticalVelocity: 0,
            reduceMotion: true
        )
        XCTAssertTrue(figure.isPainted(at: idleScenePoint, in: scene))

        figure.update(
            state: .init(motion: .sit, facing: .left),
            time: 3,
            delta: 0,
            verticalVelocity: 0,
            reduceMotion: true
        )
        let mirroredScenePoint = sprite.convert(localPoint, to: scene)
        XCTAssertTrue(figure.isPainted(at: mirroredScenePoint, in: scene))
        XCTAssertFalse(figure.isPainted(at: idleScenePoint, in: scene))
    }

    @MainActor
    func testStickFigureDragCaptureRejectsTransparentTextureAreaAndPersistsAfterMouseDown() throws {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )
        scene.spawnPlayer(appearance: .stickFigure)
        let player = try XCTUnwrap(
            scene.children.first { $0.name == "desktop-physics-player" }
        )
        player.position = CGPoint(x: 300, y: 260)
        let figure = try XCTUnwrap(player.children.first as? DesktopStickFigureNode)
        let sprite = try XCTUnwrap(figure.children.first as? SKSpriteNode)
        let painted = sprite.convert(.zero, to: scene)
        func scenePoint(sourceX: CGFloat, sourceY: CGFloat) -> CGPoint {
            sprite.convert(
                CGPoint(
                    x: (sourceX / 512 - sprite.anchorPoint.x) * sprite.size.width,
                    y: ((1 - sourceY / 512) - sprite.anchorPoint.y) * sprite.size.height
                ),
                to: scene
            )
        }
        let nearTransparentEdge = scenePoint(sourceX: 195, sourceY: 270)
        let nearPaintedEdge = scenePoint(sourceX: 200, sourceY: 270)
        let transparent = sprite.convert(
            CGPoint(x: -sprite.size.width * 0.46, y: -sprite.size.height * 0.46),
            to: scene
        )
        scene.setObjectDraggingEnabled(true)

        XCTAssertTrue(scene.shouldCaptureDragInput(at: painted))
        XCTAssertTrue(scene.shouldCaptureDragInput(at: nearPaintedEdge))
        XCTAssertFalse(scene.shouldCaptureDragInput(at: nearTransparentEdge))
        XCTAssertFalse(scene.shouldCaptureDragInput(at: transparent))
        XCTAssertTrue(scene.beginObjectDrag(at: painted, timestamp: 1))
        XCTAssertTrue(scene.shouldCaptureDragInput(at: transparent))
        scene.endObjectDrag(timestamp: 1.1, applyingThrow: false)
        XCTAssertFalse(scene.shouldCaptureDragInput(at: transparent))
    }

    @MainActor
    func testDragRoutingRefreshesWhenTheCurrentAnimationFrameChangesAtAStationaryPoint() throws {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 10_000, y: 10_000, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )
        scene.spawnPlayer(appearance: .stickFigure)
        let player = try XCTUnwrap(
            scene.children.first { $0.name == "desktop-physics-player" }
        )
        player.position = CGPoint(x: 300, y: 260)
        let figure = try XCTUnwrap(player.children.first as? DesktopStickFigureNode)
        let sprite = try XCTUnwrap(figure.children.first as? SKSpriteNode)
        let sourcePoint = CGPoint(x: 150.0 / 512.0, y: 1.0 - 300.0 / 512.0)
        let stationaryPoint = sprite.convert(
            CGPoint(
                x: (sourcePoint.x - sprite.anchorPoint.x) * sprite.size.width,
                y: (sourcePoint.y - sprite.anchorPoint.y) * sprite.size.height
            ),
            to: scene
        )
        scene.setObjectDraggingEnabled(true)
        var routingStates: [Bool] = []
        scene.onDragInputCaptureChange = { routingStates.append($0) }

        figure.update(
            state: .init(motion: .idle, facing: .right),
            time: 1,
            delta: 0,
            verticalVelocity: 0,
            reduceMotion: true
        )
        scene.refreshDragInputCapture(at: stationaryPoint)
        figure.update(
            state: .init(motion: .sit, facing: .right),
            time: 2,
            delta: 0,
            verticalVelocity: 0,
            reduceMotion: true
        )
        scene.refreshDragInputCapture(at: stationaryPoint)
        figure.update(
            state: .init(motion: .idle, facing: .right),
            time: 3,
            delta: 0,
            verticalVelocity: 0,
            reduceMotion: true
        )
        scene.refreshDragInputCapture(at: stationaryPoint)

        XCTAssertEqual(routingStates, [false, true, false])
    }

    @MainActor
    func testTransparentSceneViewLeavesLayerBackingOwnedBySpriteKit() throws {
        let controller = DesktopPhysicsSceneViewController(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )

        controller.loadView()
        let view = try XCTUnwrap(controller.view as? SKView)

        XCTAssertTrue(view.allowsTransparency)
        XCTAssertFalse(view.wantsLayer)
        XCTAssertTrue(view.scene === controller.scene)
    }

    func testExplicitSizesResolveToDistinctDiameters() {
        XCTAssertEqual(DesktopPhysicsSize.small.resolvedDiameter, 32)
        XCTAssertEqual(DesktopPhysicsSize.medium.resolvedDiameter, 48)
        XCTAssertEqual(DesktopPhysicsSize.large.resolvedDiameter, 72)
        XCTAssertEqual(DesktopPhysicsSize.diameter(1).resolvedDiameter, 1)
        XCTAssertEqual(DesktopPhysicsSize.diameter(-20).resolvedDiameter, 1)
    }

    func testRandomDiameterResolvesInsideRequestedRange() {
        for _ in 0..<100 {
            XCTAssertTrue((10...500).contains(
                DesktopPhysicsSize.random(in: 10...500).resolvedDiameter
            ))
        }
    }

    @MainActor
    func testCursorCoordinatesAreMappedFromTheSelectedScreenFrame() {
        let frame = CGRect(x: 400, y: 200, width: 1_000, height: 700)

        XCTAssertEqual(
            DesktopPhysicsScene.localCursorPosition(
                global: CGPoint(x: 425, y: 260),
                screenFrame: frame
            ),
            CGPoint(x: 25, y: 60)
        )
        XCTAssertNil(
            DesktopPhysicsScene.localCursorPosition(
                global: CGPoint(x: 399, y: 260),
                screenFrame: frame
            )
        )
    }

    func testGameplayInputCapturesOnlyUnmodifiedTrackedKeys() {
        let state = DesktopGameInputState()
        state.activate()

        XCTAssertTrue(state.shouldDiscard(type: .keyDown, keyCode: 0, flags: []))
        XCTAssertEqual(state.consumeSnapshot().horizontalDirection, -1)
        XCTAssertTrue(state.shouldDiscard(type: .keyUp, keyCode: 0, flags: []))

        for modifier: CGEventFlags in [
            .maskCommand, .maskControl, .maskAlternate, .maskSecondaryFn
        ] {
            XCTAssertFalse(
                state.shouldDiscard(type: .keyDown, keyCode: 0, flags: modifier)
            )
        }
        XCTAssertFalse(
            state.shouldDiscard(type: .keyDown, keyCode: 48, flags: .maskCommand)
        )
    }

    func testShiftSelectsRunWithoutWeakeningShortcutBypass() {
        let state = DesktopGameInputState()
        state.activate()

        XCTAssertFalse(
            state.shouldDiscard(
                type: .flagsChanged,
                keyCode: 56,
                flags: .maskShift
            )
        )
        XCTAssertTrue(
            state.shouldDiscard(
                type: .keyDown,
                keyCode: 2,
                flags: .maskShift
            )
        )
        var snapshot = state.consumeSnapshot()
        XCTAssertTrue(snapshot.runHeld)
        XCTAssertEqual(snapshot.horizontalDirection, 1)

        XCTAssertFalse(
            state.shouldDiscard(
                type: .flagsChanged,
                keyCode: 55,
                flags: [.maskShift, .maskCommand]
            )
        )
        snapshot = state.consumeSnapshot()
        XCTAssertFalse(snapshot.runHeld)
        XCTAssertEqual(snapshot.horizontalDirection, 0)
    }

    func testCTogglesSitAndMovementStandsTheCharacterUp() {
        let state = DesktopGameInputState()
        state.activate()

        XCTAssertTrue(state.shouldDiscard(type: .keyDown, keyCode: 8, flags: []))
        XCTAssertTrue(state.consumeSnapshot().sitting)
        XCTAssertTrue(state.shouldDiscard(type: .keyUp, keyCode: 8, flags: []))

        XCTAssertTrue(state.shouldDiscard(type: .keyDown, keyCode: 0, flags: []))
        XCTAssertFalse(state.consumeSnapshot().sitting)
    }

    @MainActor
    func testSceneSpawnsEveryShapeAndClearsObjects() {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )

        scene.spawn(.init(shape: .circle, size: .small))
        scene.spawn(.init(shape: .square, size: .medium))
        scene.spawn(.init(shape: .triangle, size: .large))

        XCTAssertEqual(scene.objectCount, 3)
        XCTAssertTrue(scene.children.filter {
            $0.name == "desktop-physics-object"
        }.allSatisfy { $0.physicsBody != nil })
        scene.clearObjects()
        XCTAssertEqual(scene.objectCount, 0)
    }

    @MainActor
    func testCursorColliderCanResizeFromTinyToLarge() {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )

        scene.setCursorColliderDiameter(1)
        XCTAssertEqual(scene.cursorColliderDiameter, 1)
        scene.setCursorCollisionEnabled(true)
        scene.setCursorColliderDiameter(400)
        XCTAssertEqual(scene.cursorColliderDiameter, 400)
        XCTAssertTrue(scene.cursorCollisionEnabled)
    }

    func testHeldJumpKeepsOneBufferedRequestUntilConsumed() {
        let state = DesktopGameInputState()
        state.activate()

        XCTAssertTrue(state.shouldDiscard(type: .keyDown, keyCode: 49, flags: []))
        let firstRequest = state.consumeSnapshot().jumpPressedAt
        XCTAssertNotNil(firstRequest)
        XCTAssertTrue(
            state.shouldDiscard(
                type: .keyDown,
                keyCode: 49,
                flags: [],
                isRepeat: true
            )
        )
        XCTAssertEqual(state.consumeSnapshot().jumpPressedAt, firstRequest)
        state.consumeJumpRequest()
        XCTAssertNil(state.consumeSnapshot().jumpPressedAt)
        XCTAssertTrue(state.shouldDiscard(type: .keyUp, keyCode: 49, flags: []))
        XCTAssertTrue(state.shouldDiscard(type: .keyDown, keyCode: 49, flags: []))
        XCTAssertNotNil(state.consumeSnapshot().jumpPressedAt)
    }

    func testArrowFunctionFlagIsIntrinsicButCommandArrowStillPasses() {
        let state = DesktopGameInputState()
        state.activate()

        XCTAssertTrue(
            state.shouldDiscard(
                type: .keyDown,
                keyCode: 123,
                flags: .maskSecondaryFn
            )
        )
        XCTAssertEqual(state.consumeSnapshot().horizontalDirection, -1)
        XCTAssertTrue(
            state.shouldDiscard(
                type: .keyUp,
                keyCode: 123,
                flags: .maskSecondaryFn
            )
        )
        XCTAssertFalse(
            state.shouldDiscard(
                type: .keyDown,
                keyCode: 123,
                flags: [.maskSecondaryFn, .maskCommand]
            )
        )

        XCTAssertTrue(
            state.shouldDiscard(
                type: .keyDown,
                keyCode: 126,
                flags: .maskSecondaryFn
            )
        )
        XCTAssertNotNil(state.consumeSnapshot().jumpPressedAt)
    }

    func testControlSchemeCapturesOnlyItsKeyFamily() {
        let state = DesktopGameInputState()
        state.activate()

        state.setControlScheme(.wasd)
        XCTAssertTrue(state.shouldDiscard(type: .keyDown, keyCode: 0, flags: []))
        XCTAssertFalse(
            state.shouldDiscard(
                type: .keyDown,
                keyCode: 123,
                flags: .maskSecondaryFn
            )
        )

        state.setControlScheme(.arrows)
        XCTAssertFalse(state.shouldDiscard(type: .keyDown, keyCode: 0, flags: []))
        XCTAssertTrue(
            state.shouldDiscard(
                type: .keyDown,
                keyCode: 123,
                flags: .maskSecondaryFn
            )
        )
        XCTAssertTrue(state.shouldDiscard(type: .keyDown, keyCode: 49, flags: []))
    }

    func testControllerProfileDerivesJumpFromVisibleOutcomes() {
        let profile = DesktopPlatformerControllerProfile()

        XCTAssertLessThan(profile.maximumWalkSpeed, profile.maximumRunSpeed)
        XCTAssertEqual(profile.jumpVelocity, 1_000, accuracy: 0.001)
        XCTAssertEqual(profile.riseGravity, 2_777.777, accuracy: 0.01)
        XCTAssertEqual(profile.releaseVelocityCap, 623.61, accuracy: 0.1)
        XCTAssertLessThan(profile.maximumWallSlideFallSpeed, profile.terminalFallSpeed)
        XCTAssertLessThan(profile.wallJumpHorizontalSpeed, profile.maximumWalkSpeed)
        XCTAssertGreaterThanOrEqual(profile.wallJumpVerticalSpeed, profile.jumpVelocity)
    }

    func testCharacterAnimationStateResolutionCoversEveryRequestedMotion() {
        XCTAssertEqual(
            DesktopCharacterAnimationState.resolve(
                grounded: true,
                wallSliding: false,
                sitting: false,
                horizontalSpeed: 0,
                running: false,
                facing: .right
            ).motion,
            .idle
        )
        XCTAssertEqual(
            DesktopCharacterAnimationState.resolve(
                grounded: true,
                wallSliding: false,
                sitting: false,
                horizontalSpeed: 200,
                running: false,
                facing: .left
            ).motion,
            .walk
        )
        XCTAssertEqual(
            DesktopCharacterAnimationState.resolve(
                grounded: true,
                wallSliding: false,
                sitting: false,
                horizontalSpeed: 500,
                running: true,
                facing: .right
            ).motion,
            .run
        )
        XCTAssertEqual(
            DesktopCharacterAnimationState.resolve(
                grounded: false,
                wallSliding: false,
                sitting: false,
                horizontalSpeed: 0,
                running: false,
                facing: .right
            ).motion,
            .jump
        )
        XCTAssertEqual(
            DesktopCharacterAnimationState.resolve(
                grounded: false,
                wallSliding: true,
                sitting: false,
                horizontalSpeed: 0,
                running: false,
                facing: .left
            ).motion,
            .wallSlide
        )
        XCTAssertEqual(
            DesktopCharacterAnimationState.resolve(
                grounded: true,
                wallSliding: false,
                sitting: true,
                horizontalSpeed: 0,
                running: false,
                facing: .right
            ).motion,
            .sit
        )
    }

    @MainActor
    func testStickFigureRendererAcceptsEveryMotionAndFacing() {
        let figure = DesktopStickFigureNode()
        var time: TimeInterval = 1

        for motion in DesktopCharacterMotion.allCases {
            for facing in [DesktopCharacterFacing.left, .right] {
                let state = DesktopCharacterAnimationState(
                    motion: motion,
                    facing: facing
                )
                figure.update(
                    state: state,
                    time: time,
                    delta: 1.0 / 60,
                    verticalVelocity: motion == .jump ? 300 : 0,
                    reduceMotion: true
                )
                XCTAssertEqual(figure.animationState, state)
                time += 1
            }
        }
    }

    func testModifierTransitionClearsHeldMovement() {
        let state = DesktopGameInputState()
        state.activate()
        XCTAssertTrue(state.shouldDiscard(type: .keyDown, keyCode: 2, flags: []))

        XCTAssertFalse(
            state.shouldDiscard(
                type: .flagsChanged,
                keyCode: 55,
                flags: .maskCommand
            )
        )
        XCTAssertEqual(state.consumeSnapshot().horizontalDirection, 0)
    }

    @MainActor
    func testPresentedSceneGroundsPlayerAndAdmitsJump() {
        let clock = TestMonotonicClock()
        let input = DesktopGameInputState(monotonicTime: clock.now)
        input.activate()
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: input
        )
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        let window = NSWindow(
            contentRect: view.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.animationBehavior = .none
        window.isReleasedWhenClosed = false
        window.contentView = view
        window.orderBack(nil)
        defer {
            view.presentScene(nil)
            window.contentView = nil
            window.close()
        }
        view.presentScene(scene)
        scene.spawnPlayer(appearance: .stickFigure)
        XCTAssertEqual(
            scene.children.first { $0.name == "desktop-physics-player" }?
                .physicsBody?.restitution,
            0
        )

        var frameTime: TimeInterval = 0
        func advanceControllerFrame(by interval: TimeInterval = 1.0 / 60.0) {
            clock.advance(by: interval)
            frameTime += interval
            scene.update(frameTime)
            scene.didSimulatePhysics()
        }

        scene.setPlayerPositionForTesting(CGPoint(
            x: 400,
            y: DesktopStickFigureNode.collisionSize.height / 2
        ))
        advanceControllerFrame()
        XCTAssertTrue(
            scene.playerIsGroundedForTesting,
            "position=\(String(describing: scene.playerPositionForTesting)) velocity=\(String(describing: scene.playerVelocityForTesting))"
        )

        XCTAssertTrue(input.shouldDiscard(type: .keyDown, keyCode: 13, flags: []))
        advanceControllerFrame()
        XCTAssertGreaterThan(
            scene.playerVelocityForTesting?.dy ?? 0,
            0,
            "grounded=\(scene.playerIsGroundedForTesting) position=\(String(describing: scene.playerPositionForTesting))"
        )
        XCTAssertTrue(input.shouldDiscard(type: .keyUp, keyCode: 13, flags: []))

        scene.setPlayerPositionForTesting(CGPoint(x: 18, y: 220))
        advanceControllerFrame(
            by: DesktopPlatformerControllerProfile().coyoteTime + 1.0 / 60.0
        )
        XCTAssertEqual(scene.playerWallSideForTesting, -1)

        XCTAssertTrue(input.shouldDiscard(type: .keyDown, keyCode: 0, flags: []))
        scene.setPlayerVelocityForTesting(CGVector(dx: 0, dy: -1_000))
        advanceControllerFrame()
        XCTAssertEqual(scene.playerAnimationStateForTesting?.motion, .wallSlide)
        XCTAssertGreaterThanOrEqual(
            scene.playerVelocityForTesting?.dy ?? -.infinity,
            -DesktopPlatformerControllerProfile().maximumWallSlideFallSpeed - 0.01
        )

        XCTAssertTrue(input.shouldDiscard(type: .keyDown, keyCode: 49, flags: []))
        advanceControllerFrame()
        let wallJumpVelocity = scene.playerVelocityForTesting ?? .zero
        XCTAssertGreaterThan(wallJumpVelocity.dx, 0)
        XCTAssertLessThan(wallJumpVelocity.dx, 500)
        XCTAssertGreaterThan(wallJumpVelocity.dy, 0)
    }

    @MainActor
    func testObjectDragFollowsPointerAndRestoresPhysicsOnRelease() {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )
        scene.spawn(.init(shape: .circle, size: .diameter(48)))
        let object = try! XCTUnwrap(
            scene.children.first { $0.name == "desktop-physics-object" }
        )
        object.position = CGPoint(x: 100, y: 100)
        let grabPoint = object.position
        let destination = CGPoint(x: 200, y: 250)

        scene.setObjectDraggingEnabled(true)
        XCTAssertTrue(scene.beginObjectDrag(at: grabPoint, timestamp: 1))
        scene.moveObjectDrag(to: destination, timestamp: 1.1)
        XCTAssertEqual(object.position.x, destination.x, accuracy: 0.001)
        XCTAssertEqual(object.position.y, destination.y, accuracy: 0.001)
        XCTAssertEqual(object.physicsBody?.isDynamic, false)

        scene.endObjectDrag(timestamp: 1.1)
        XCTAssertEqual(object.physicsBody?.isDynamic, true)
        XCTAssertEqual(object.physicsBody?.velocity.dx ?? 0, 1_000, accuracy: 0.01)
        XCTAssertEqual(object.physicsBody?.velocity.dy ?? 0, 1_500, accuracy: 0.01)

        XCTAssertTrue(scene.beginObjectDrag(at: destination, timestamp: 2))
        scene.endObjectDrag(timestamp: 2.2)
        XCTAssertEqual(object.physicsBody?.velocity.dx ?? 0, 0, accuracy: 0.01)
        XCTAssertEqual(object.physicsBody?.velocity.dy ?? 0, 0, accuracy: 0.01)
    }

    func testQuartzWindowFrameMapsIntoSelectedScreenSceneCoordinates() {
        let mapped = MacDesktopWindowGeometryProvider.sceneFrame(
            quartzFrame: CGRect(x: 100, y: 200, width: 300, height: 400),
            selectedScreenFrame: CGRect(x: 50, y: 100, width: 800, height: 700),
            mainDisplayHeight: 1_000
        )

        XCTAssertEqual(mapped, CGRect(x: 50, y: 300, width: 300, height: 400))
    }

    func testQuartzWindowFrameSupportsDisplayAboveMainDisplay() {
        let mapped = MacDesktopWindowGeometryProvider.sceneFrame(
            quartzFrame: CGRect(x: 0, y: -800, width: 1_200, height: 800),
            selectedScreenFrame: CGRect(x: 0, y: 1_000, width: 1_200, height: 800),
            mainDisplayHeight: 1_000
        )

        XCTAssertEqual(mapped, CGRect(x: 0, y: 0, width: 1_200, height: 800))
    }

    @MainActor
    func testWindowGeometryObservationDoesNotRequireAccessibilityTrust() throws {
        let provider = MacDesktopWindowGeometryProvider(
            minimumWindowDimension: 50,
            observation: { _ in
                .available([
                    MacDesktopWindowGeometryObservationEntry(
                        id: 77,
                        processID: 42,
                        applicationName: "Example",
                        frame: CGRect(x: 100, y: 200, width: 300, height: 250),
                        zIndex: 0
                    )
                ])
            },
            mainDisplayHeight: { 1_000 }
        )

        let snapshot = provider.snapshot(
            selectedScreenFrame: CGRect(x: 0, y: 0, width: 800, height: 700)
        )

        XCTAssertEqual(snapshot.availability, .available)
        let window = try XCTUnwrap(snapshot.windows.first)
        XCTAssertEqual(window.sourceWindowID, 77)
        XCTAssertEqual(window.frame, CGRect(x: 100, y: 550, width: 300, height: 150))
    }

    func testOcclusionFragmentsRetainOnlyOriginalWindowSides() {
        let source = CGRect(x: 0, y: 0, width: 100, height: 100)
        let top = MacDesktopWindowGeometryProvider.visibleSourceEdges(
            quartzFragmentFrame: CGRect(x: 0, y: 0, width: 40, height: 30),
            sourceWindowFrame: source
        )
        let middle = MacDesktopWindowGeometryProvider.visibleSourceEdges(
            quartzFragmentFrame: CGRect(x: 0, y: 30, width: 40, height: 40),
            sourceWindowFrame: source
        )
        let bottom = MacDesktopWindowGeometryProvider.visibleSourceEdges(
            quartzFragmentFrame: CGRect(x: 0, y: 70, width: 40, height: 30),
            sourceWindowFrame: source
        )

        XCTAssertTrue(top.top)
        XCTAssertFalse(top.bottom)
        XCTAssertTrue(top.left)
        XCTAssertFalse(top.right)
        XCTAssertFalse(middle.top)
        XCTAssertFalse(middle.bottom)
        XCTAssertTrue(middle.left)
        XCTAssertFalse(middle.right)
        XCTAssertFalse(bottom.top)
        XCTAssertTrue(bottom.bottom)
        XCTAssertTrue(bottom.left)
        XCTAssertFalse(bottom.right)
    }

    func testOneWayWindowPlatformAdmitsOnlyDescendingCrossingFromAbove() {
        let surface = DesktopWindowPlatformSurface(
            id: "visible:7:0",
            frame: CGRect(x: 100, y: 100, width: 300, height: 200)
        )
        XCTAssertEqual(
            DesktopWindowPlatformPolicy.landing(
                previousFootY: 320,
                currentFootY: 295,
                verticalVelocity: -200,
                playerHorizontalRange: 180...220,
                surfaces: [surface]
            ),
            DesktopWindowPlatformLanding(
                id: "visible:7:0",
                edge: .top,
                surfaceY: 300
            )
        )
        XCTAssertNil(DesktopWindowPlatformPolicy.landing(
            previousFootY: 280,
            currentFootY: 305,
            verticalVelocity: 200,
            playerHorizontalRange: 180...220,
            surfaces: [surface]
        ))
        XCTAssertNil(DesktopWindowPlatformPolicy.landing(
            previousFootY: 320,
            currentFootY: 295,
            verticalVelocity: -200,
            playerHorizontalRange: 180...220,
            surfaces: [DesktopWindowPlatformSurface(
                id: "occlusion-cut",
                frame: surface.frame,
                hasVisibleTopEdge: false,
                hasVisibleBottomEdge: true
            )]
        ))
        XCTAssertNil(DesktopWindowPlatformPolicy.landing(
            previousFootY: 280,
            currentFootY: 270,
            verticalVelocity: -200,
            playerHorizontalRange: 180...220,
            surfaces: [surface]
        ))
        XCTAssertNil(DesktopWindowPlatformPolicy.landing(
            previousFootY: 320,
            currentFootY: 295,
            verticalVelocity: -200,
            playerHorizontalRange: 420...460,
            surfaces: [surface]
        ))
    }

    func testWindowBottomIsASecondOneWayLandingPlatform() {
        let surface = DesktopWindowPlatformSurface(
            id: "visible:7:0",
            frame: CGRect(x: 100, y: 100, width: 300, height: 200)
        )
        XCTAssertNil(DesktopWindowPlatformPolicy.landing(
            previousFootY: 80,
            currentFootY: 105,
            verticalVelocity: 200,
            playerHorizontalRange: 180...220,
            surfaces: [surface]
        ))
        XCTAssertEqual(
            DesktopWindowPlatformPolicy.landing(
                previousFootY: 120,
                currentFootY: 95,
                verticalVelocity: -200,
                playerHorizontalRange: 180...220,
                surfaces: [surface]
            ),
            DesktopWindowPlatformLanding(
                id: "visible:7:0",
                edge: .bottom,
                surfaceY: 100
            )
        )
        XCTAssertNil(DesktopWindowPlatformPolicy.landing(
            previousFootY: 120,
            currentFootY: 95,
            verticalVelocity: -200,
            playerHorizontalRange: 180...220,
            surfaces: [DesktopWindowPlatformSurface(
                id: "occlusion-cut",
                frame: surface.frame,
                hasVisibleTopEdge: true,
                hasVisibleBottomEdge: false
            )]
        ))
        XCTAssertNil(DesktopWindowPlatformPolicy.landing(
            previousFootY: 120,
            currentFootY: 95,
            verticalVelocity: -200,
            playerHorizontalRange: 420...460,
            surfaces: [surface]
        ))
    }

    func testDropThroughIgnoresEveryCoincidentSupportEdge() {
        let surfaces = [
            DesktopWindowPlatformSurface(
                id: "front-fragment",
                frame: CGRect(x: 100, y: 100, width: 300, height: 200)
            ),
            DesktopWindowPlatformSurface(
                id: "rear-fragment",
                frame: CGRect(x: 120, y: 150, width: 260, height: 150)
            )
        ]

        XCTAssertNil(DesktopWindowPlatformPolicy.landing(
            previousFootY: 303,
            currentFootY: 297,
            verticalVelocity: -80,
            playerHorizontalRange: 180...220,
            surfaces: surfaces,
            ignoredSurfaceY: 300
        ))
    }

    func testDropThroughKeepsExclusionUntilThePreviousFrameIsBelowTheEdge() {
        XCTAssertFalse(DesktopWindowPlatformPolicy.shouldClearIgnoredSurface(
            previousFootY: 297,
            ignoredSurfaceY: 300
        ))
        XCTAssertTrue(DesktopWindowPlatformPolicy.shouldClearIgnoredSurface(
            previousFootY: 293,
            ignoredSurfaceY: 300
        ))
    }

    func testSupportedPlayerFollowsSmallWindowMotionButDetachesFromIntrusion() {
        let moved = CGRect(x: 100, y: 108, width: 300, height: 200)
        XCTAssertEqual(
            DesktopWindowPlatformPolicy.supportedPlayerCenterY(
                previousPlatformY: 300,
                edge: .top,
                currentPlatformFrame: moved,
                previousFootY: 300,
                verticalVelocity: -20,
                playerHorizontalRange: 180...220,
                playerHalfHeight: 24,
                sceneHeight: 800,
                maximumPlatformStep: 24
            ),
            332
        )
        XCTAssertNil(DesktopWindowPlatformPolicy.supportedPlayerCenterY(
            previousPlatformY: 300,
            edge: .top,
            currentPlatformFrame: CGRect(x: 100, y: 180, width: 300, height: 200),
            previousFootY: 300,
            verticalVelocity: -20,
            playerHorizontalRange: 180...220,
            playerHalfHeight: 24,
            sceneHeight: 800,
            maximumPlatformStep: 24
        ))
        XCTAssertNil(DesktopWindowPlatformPolicy.supportedPlayerCenterY(
            previousPlatformY: 300,
            edge: .top,
            currentPlatformFrame: moved,
            previousFootY: 300,
            verticalVelocity: 200,
            playerHorizontalRange: 180...220,
            playerHalfHeight: 24,
            sceneHeight: 800,
            maximumPlatformStep: 24
        ))
        XCTAssertEqual(DesktopWindowPlatformPolicy.supportedPlayerCenterY(
            previousPlatformY: 100,
            edge: .bottom,
            currentPlatformFrame: moved,
            previousFootY: 100,
            verticalVelocity: -20,
            playerHorizontalRange: 180...220,
            playerHalfHeight: 24,
            sceneHeight: 800,
            maximumPlatformStep: 24
        ), 132)
    }

    @MainActor
    func testPlayerWindowCollisionAndJumpHeightAreRuntimeTunable() {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )

        XCTAssertTrue(scene.playerWindowCollisionEnabled)
        scene.setPlayerWindowCollisionEnabled(false)
        XCTAssertFalse(scene.playerWindowCollisionEnabled)

        XCTAssertEqual(scene.playerJumpHeight, 180)
        scene.setPlayerJumpHeight(500)
        XCTAssertEqual(scene.playerJumpHeight, 500)
        scene.setPlayerJumpHeight(10_000)
        XCTAssertEqual(scene.playerJumpHeight, 570)
    }

    @MainActor
    func testWindowPlatformLifecyclePreservesStableNodesAndCollisionPolicy() throws {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )
        let first = MacDesktopWindow(
            id: "visible:7:0",
            sourceWindowID: 7,
            fragmentIndex: 0,
            processID: 42,
            applicationName: "Example",
            frame: CGRect(x: 100, y: 100, width: 300, height: 200),
            zIndex: 0
        )
        scene.setWindowPlatforms([first])
        let firstNode = try XCTUnwrap(
            scene.childNode(withName: "desktop-window-platform-visible:7:0")
        )

        scene.spawn(.init(shape: .circle, size: .small))
        scene.spawnPlayer(appearance: .circle)
        let object = try XCTUnwrap(
            scene.children.first { $0.name == "desktop-physics-object" }
        )
        let player = try XCTUnwrap(
            scene.children.first { $0.name == "desktop-physics-player" }
        )
        let platformCategory = try XCTUnwrap(firstNode.physicsBody).categoryBitMask
        XCTAssertNotEqual(
            try XCTUnwrap(object.physicsBody).collisionBitMask & platformCategory,
            0
        )
        XCTAssertEqual(
            try XCTUnwrap(player.physicsBody).collisionBitMask & platformCategory,
            0
        )

        let moved = MacDesktopWindow(
            id: "visible:7:0",
            sourceWindowID: 7,
            fragmentIndex: 0,
            processID: 42,
            applicationName: "Example",
            frame: CGRect(x: 140, y: 120, width: 300, height: 200),
            zIndex: 0
        )
        scene.setWindowPlatforms([moved])
        XCTAssertTrue(scene.childNode(withName: "desktop-window-platform-visible:7:0") === firstNode)
        XCTAssertEqual(scene.windowPlatformFramesForTesting["visible:7:0"], moved.frame)

        scene.setWindowPlatforms([])
        XCTAssertTrue(scene.windowPlatformFramesForTesting.isEmpty)
        XCTAssertNil(firstNode.parent)
    }

    @MainActor
    func testWindowPlatformOutlinesTrackGeometryWithoutChangingCollisionBodies() throws {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )
        let first = MacDesktopWindow(
            id: "visible:17:0",
            sourceWindowID: 17,
            fragmentIndex: 0,
            processID: 42,
            applicationName: "Example",
            frame: CGRect(x: 100, y: 100, width: 300, height: 200),
            zIndex: 0
        )
        scene.setWindowPlatforms([first])

        let collider = try XCTUnwrap(
            scene.childNode(withName: "desktop-window-platform-visible:17:0")
        )
        let collisionBody = try XCTUnwrap(collider.physicsBody)
        let outline = try XCTUnwrap(
            scene.childNode(withName: "desktop-window-platform-outline-visible:17:0")
        )
        let rectangle = try XCTUnwrap(
            outline.childNode(withName: "solid-object-rectangle") as? SKShapeNode
        )
        let topEdge = try XCTUnwrap(
            outline.childNode(withName: "player-one-way-top-edge") as? SKShapeNode
        )
        let bottomEdge = try XCTUnwrap(
            outline.childNode(withName: "player-one-way-bottom-edge") as? SKShapeNode
        )

        XCTAssertNil(outline.physicsBody)
        XCTAssertGreaterThan(topEdge.lineWidth, rectangle.lineWidth)
        XCTAssertEqual(bottomEdge.lineWidth, topEdge.lineWidth)
        XCTAssertEqual(scene.windowPlatformOutlineCountForTesting, 1)

        scene.setWindowPlatformOutlinesVisible(false)
        XCTAssertNil(scene.childNode(withName: "desktop-window-platform-outline-visible:17:0"))
        XCTAssertTrue(collider.physicsBody === collisionBody)
        XCTAssertEqual(scene.windowPlatformOutlineCountForTesting, 0)

        scene.setWindowPlatformOutlinesVisible(true)
        let restoredOutline = try XCTUnwrap(
            scene.childNode(withName: "desktop-window-platform-outline-visible:17:0")
        )
        XCTAssertTrue(collider.physicsBody === collisionBody)

        let moved = MacDesktopWindow(
            id: "visible:17:0",
            sourceWindowID: 17,
            fragmentIndex: 0,
            processID: 42,
            applicationName: "Example",
            frame: CGRect(x: 140, y: 120, width: 300, height: 200),
            zIndex: 0
        )
        scene.setWindowPlatforms([moved])
        XCTAssertTrue(
            scene.childNode(withName: "desktop-window-platform-outline-visible:17:0")
                === restoredOutline
        )
        XCTAssertEqual(restoredOutline.position, CGPoint(x: 290, y: 220))

        let resized = MacDesktopWindow(
            id: "visible:17:0",
            sourceWindowID: 17,
            fragmentIndex: 0,
            processID: 42,
            applicationName: "Example",
            frame: CGRect(x: 140, y: 120, width: 360, height: 240),
            zIndex: 0
        )
        scene.setWindowPlatforms([resized])
        let resizedOutline = try XCTUnwrap(
            scene.childNode(withName: "desktop-window-platform-outline-visible:17:0")
        )
        let resizedRectangle = try XCTUnwrap(
            resizedOutline.childNode(withName: "solid-object-rectangle") as? SKShapeNode
        )
        XCTAssertFalse(resizedOutline === restoredOutline)
        XCTAssertNil(restoredOutline.parent)
        XCTAssertEqual(resizedOutline.position, CGPoint(x: 320, y: 240))
        XCTAssertEqual(resizedRectangle.path?.boundingBox.width, 360)
        XCTAssertEqual(resizedRectangle.path?.boundingBox.height, 240)

        scene.setWindowPlatforms([])
        XCTAssertNil(resizedOutline.parent)
        XCTAssertEqual(scene.windowPlatformOutlineCountForTesting, 0)
    }

    @MainActor
    func testOcclusionCutEdgesAreNotPresentedAsPlayerSurfaces() throws {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )
        scene.setWindowPlatforms([MacDesktopWindow(
            id: "visible:99:0",
            sourceWindowID: 99,
            fragmentIndex: 0,
            processID: 42,
            applicationName: "Example",
            frame: CGRect(x: 100, y: 100, width: 300, height: 200),
            zIndex: 0,
            hasVisibleTopEdge: false,
            hasVisibleBottomEdge: true
        )])

        let outline = try XCTUnwrap(
            scene.childNode(withName: "desktop-window-platform-outline-visible:99:0")
        )
        XCTAssertNil(outline.childNode(withName: "player-one-way-top-edge"))
        XCTAssertNotNil(outline.childNode(withName: "player-one-way-bottom-edge"))
    }

    func testVisibleWindowSideCollisionUsesOnlyOriginalSourceEdges() {
        let surface = DesktopWindowPlatformSurface(
            id: "visible:7:0",
            frame: CGRect(x: 100, y: 100, width: 200, height: 200),
            hasVisibleTopEdge: true,
            hasVisibleBottomEdge: true,
            hasVisibleLeftEdge: false,
            hasVisibleRightEdge: true
        )

        XCTAssertEqual(
            DesktopWindowPlatformPolicy.sideCollision(
                previousCenterX: 250,
                currentCenterX: 290,
                playerHalfWidth: 20,
                playerVerticalRange: 140...180,
                surfaces: [surface]
            ),
            DesktopWindowSideCollision(
                featureID: "window:visible:7:0:right",
                edgeX: 300,
                wallSide: 1
            )
        )
        XCTAssertNil(DesktopWindowPlatformPolicy.sideCollision(
            previousCenterX: 70,
            currentCenterX: 90,
            playerHalfWidth: 20,
            playerVerticalRange: 140...180,
            surfaces: [surface]
        ))
        XCTAssertNil(DesktopWindowPlatformPolicy.sideCollision(
            previousCenterX: 250,
            currentCenterX: 290,
            playerHalfWidth: 20,
            playerVerticalRange: 400...440,
            surfaces: [surface]
        ))
    }

    func testWindowSideTraversalExcludesEveryCoincidentFeatureButNotNextPlane() throws {
        let contacted = DesktopWindowPlatformSurface(
            id: "front",
            frame: CGRect(x: 100, y: 100, width: 200, height: 200),
            hasVisibleLeftEdge: false,
            hasVisibleRightEdge: true
        )
        let coincident = DesktopWindowPlatformSurface(
            id: "rear",
            frame: CGRect(x: 120, y: 100, width: 180, height: 200),
            hasVisibleLeftEdge: false,
            hasVisibleRightEdge: true
        )
        let distinct = DesktopWindowPlatformSurface(
            id: "next",
            frame: CGRect(x: 140, y: 100, width: 200, height: 200),
            hasVisibleLeftEdge: false,
            hasVisibleRightEdge: true
        )
        let traversal = try DesktopWallTraversalState(
            featureID: DesktopSurfaceID(rawValue: "window:front:right")!,
            direction: .positiveX,
            planeX: 300
        )

        XCTAssertNil(DesktopWindowPlatformPolicy.sideCollision(
            previousCenterX: 250,
            currentCenterX: 320,
            playerHalfWidth: 20,
            playerVerticalRange: 140...180,
            surfaces: [contacted, coincident],
            excluding: traversal
        ))
        XCTAssertFalse(try traversal.shouldClear(
            previousBounds: DesktopHorizontalBounds(minX: 290, maxX: 330)
        ))
        XCTAssertEqual(
            DesktopWindowPlatformPolicy.sideCollision(
                previousCenterX: 250,
                currentCenterX: 350,
                playerHalfWidth: 20,
                playerVerticalRange: 140...180,
                surfaces: [contacted, coincident, distinct],
                excluding: traversal
            ),
            DesktopWindowSideCollision(
                featureID: "window:next:right",
                edgeX: 340,
                wallSide: 1
            )
        )
    }

    @MainActor
    func testTowardWindowWallJumpBeginsTraversalWhileAwayJumpRemainsOutward() throws {
        func makeScene() -> (DesktopPhysicsScene, DesktopGameInputState, TestMonotonicClock) {
            let clock = TestMonotonicClock()
            let input = DesktopGameInputState(monotonicTime: clock.now)
            input.activate()
            let scene = DesktopPhysicsScene(
                size: CGSize(width: 800, height: 600),
                screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
                configuration: .init(),
                inputState: input
            )
            scene.setPlayerWindowSideCollisionEnabled(true)
            scene.setWindowPlatforms([MacDesktopWindow(
                id: "visible:7:0",
                sourceWindowID: 7,
                fragmentIndex: 0,
                processID: 42,
                applicationName: "Example",
                frame: CGRect(x: 300, y: 100, width: 200, height: 300),
                zIndex: 0
            )])
            scene.spawnPlayer(appearance: .stickFigure)
            scene.setPlayerPositionForTesting(CGPoint(x: 283, y: 220))
            return (scene, input, clock)
        }

        func advance(
            _ scene: DesktopPhysicsScene,
            clock: TestMonotonicClock,
            frameTime: inout TimeInterval
        ) {
            clock.advance(by: 1.0 / 60.0)
            frameTime += 1.0 / 60.0
            scene.update(frameTime)
            scene.didSimulatePhysics()
        }

        let (towardScene, towardInput, towardClock) = makeScene()
        var towardFrame: TimeInterval = 0
        advance(towardScene, clock: towardClock, frameTime: &towardFrame)
        XCTAssertEqual(towardScene.playerWallSideForTesting, 1)
        XCTAssertTrue(towardInput.shouldDiscard(type: .keyDown, keyCode: 2, flags: []))
        XCTAssertTrue(towardInput.shouldDiscard(type: .keyDown, keyCode: 49, flags: []))
        advance(towardScene, clock: towardClock, frameTime: &towardFrame)
        XCTAssertNotNil(towardScene.wallTraversalStateForTesting)
        XCTAssertGreaterThan(towardScene.playerVelocityForTesting?.dx ?? 0, 0)
        XCTAssertGreaterThan(towardScene.playerVelocityForTesting?.dy ?? 0, 0)

        let (awayScene, awayInput, awayClock) = makeScene()
        var awayFrame: TimeInterval = 0
        advance(awayScene, clock: awayClock, frameTime: &awayFrame)
        XCTAssertEqual(awayScene.playerWallSideForTesting, 1)
        XCTAssertTrue(awayInput.shouldDiscard(type: .keyDown, keyCode: 0, flags: []))
        XCTAssertTrue(awayInput.shouldDiscard(type: .keyDown, keyCode: 49, flags: []))
        advance(awayScene, clock: awayClock, frameTime: &awayFrame)
        XCTAssertNil(awayScene.wallTraversalStateForTesting)
        XCTAssertLessThan(awayScene.playerVelocityForTesting?.dx ?? 0, 0)
        XCTAssertGreaterThan(awayScene.playerVelocityForTesting?.dy ?? 0, 0)
    }

    @MainActor
    func testNearestVisibleWindowPlaneWinsWhenTwoEdgesShareTheProbe() throws {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )
        scene.setPlayerWindowSideCollisionEnabled(true)
        scene.setWindowPlatforms([
            MacDesktopWindow(
                id: "far",
                sourceWindowID: 8,
                fragmentIndex: 0,
                processID: 42,
                applicationName: "Far",
                frame: CGRect(x: 306, y: 100, width: 200, height: 300),
                zIndex: 1,
                hasVisibleRightEdge: false
            ),
            MacDesktopWindow(
                id: "near",
                sourceWindowID: 7,
                fragmentIndex: 0,
                processID: 42,
                applicationName: "Near",
                frame: CGRect(x: 300, y: 100, width: 200, height: 300),
                zIndex: 0,
                hasVisibleRightEdge: false
            )
        ])
        scene.spawnPlayer(appearance: .stickFigure)
        scene.setPlayerPositionForTesting(CGPoint(x: 283, y: 220))

        scene.update(1.0 / 60.0)
        scene.didSimulatePhysics()

        let contact = try XCTUnwrap(scene.playerWindowWallContactForTesting)
        XCTAssertEqual(contact.featureID.rawValue, "window:near:left")
        XCTAssertEqual(contact.planeX, 300)
    }

    @MainActor
    func testWindowRemovalClearsStaleContactAndOnlyClearsTraversalWhenItsPlaneDisappears() throws {
        func makeContactScene() -> (DesktopPhysicsScene, DesktopGameInputState, TestMonotonicClock) {
            let clock = TestMonotonicClock()
            let input = DesktopGameInputState(monotonicTime: clock.now)
            input.activate()
            let scene = DesktopPhysicsScene(
                size: CGSize(width: 800, height: 600),
                screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
                configuration: .init(),
                inputState: input
            )
            scene.setPlayerWindowSideCollisionEnabled(true)
            scene.setWindowPlatforms([MacDesktopWindow(
                id: "contacted",
                sourceWindowID: 7,
                fragmentIndex: 0,
                processID: 42,
                applicationName: "Contacted",
                frame: CGRect(x: 300, y: 100, width: 200, height: 300),
                zIndex: 0,
                hasVisibleRightEdge: false
            )])
            scene.spawnPlayer(appearance: .stickFigure)
            scene.setPlayerPositionForTesting(CGPoint(x: 283, y: 220))
            scene.update(1.0 / 60.0)
            scene.didSimulatePhysics()
            return (scene, input, clock)
        }

        let (contactScene, _, _) = makeContactScene()
        XCTAssertNotNil(contactScene.playerWindowWallContactForTesting)
        contactScene.setWindowPlatforms([])
        XCTAssertNil(contactScene.playerWindowWallContactForTesting)

        let (traversalScene, input, clock) = makeContactScene()
        XCTAssertTrue(input.shouldDiscard(type: .keyDown, keyCode: 2, flags: []))
        XCTAssertTrue(input.shouldDiscard(type: .keyDown, keyCode: 49, flags: []))
        clock.advance(by: 1.0 / 60.0)
        traversalScene.update(2.0 / 60.0)
        traversalScene.didSimulatePhysics()
        XCTAssertEqual(traversalScene.wallTraversalStateForTesting?.planeX, 300)

        traversalScene.setWindowPlatforms([MacDesktopWindow(
            id: "coincident-replacement",
            sourceWindowID: 9,
            fragmentIndex: 0,
            processID: 42,
            applicationName: "Replacement",
            frame: CGRect(x: 300, y: 100, width: 160, height: 300),
            zIndex: 0,
            hasVisibleRightEdge: false
        )])
        XCTAssertNil(traversalScene.playerWindowWallContactForTesting)
        XCTAssertEqual(traversalScene.wallTraversalStateForTesting?.planeX, 300)

        traversalScene.setWindowPlatforms([])
        XCTAssertNil(traversalScene.wallTraversalStateForTesting)
    }

    @MainActor
    func testGameWorldModeAtomicallySwitchesBackdropAndPlatformStyleForReduceMotion() throws {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )
        scene.setWindowPlatforms([MacDesktopWindow(
            id: "visible:7:0",
            sourceWindowID: 7,
            fragmentIndex: 0,
            processID: 42,
            applicationName: "Example",
            frame: CGRect(x: 100, y: 100, width: 300, height: 200),
            zIndex: 0
        )])
        scene.setWindowPlatformOutlinesVisible(false)

        scene.setGameWorldModeEnabled(true, reduceMotion: true)
        let backdrop = try XCTUnwrap(
            scene.childNode(withName: "desktop-game-world-backdrop")
        )
        let outline = try XCTUnwrap(
            scene.childNode(withName: "desktop-window-platform-outline-visible:7:0")
        )
        let gameLines = try XCTUnwrap(
            outline.childNode(withName: "game-world-platform-lines")
        )
        XCTAssertEqual(backdrop.alpha, 1)
        XCTAssertEqual(gameLines.alpha, 1)
        XCTAssertEqual(
            outline.childNode(withName: "solid-object-rectangle")?.alpha,
            0
        )

        scene.setGameWorldModeEnabled(false, reduceMotion: true)
        XCTAssertEqual(backdrop.alpha, 0)
        XCTAssertNil(
            scene.childNode(withName: "desktop-window-platform-outline-visible:7:0")
        )
    }

    @MainActor
    func testDirectManipulationCanDragAndReleaseThePlayer() throws {
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(),
            inputState: DesktopGameInputState()
        )
        scene.spawnPlayer(appearance: .circle)
        let player = try XCTUnwrap(
            scene.children.first { $0.name == "desktop-physics-player" }
        )
        player.position = CGPoint(x: 200, y: 200)
        scene.setObjectDraggingEnabled(true)

        XCTAssertTrue(scene.shouldCaptureDragInput(at: player.position))
        XCTAssertFalse(scene.shouldCaptureDragInput(at: CGPoint(x: 700, y: 500)))

        XCTAssertTrue(scene.beginObjectDrag(at: player.position, timestamp: 1))
        XCTAssertTrue(scene.shouldCaptureDragInput(at: CGPoint(x: 700, y: 500)))
        scene.moveObjectDrag(to: CGPoint(x: 300, y: 350), timestamp: 1.1)
        XCTAssertEqual(player.position, CGPoint(x: 300, y: 350))
        XCTAssertEqual(player.physicsBody?.isDynamic, false)

        scene.endObjectDrag(timestamp: 1.1)
        XCTAssertFalse(scene.shouldCaptureDragInput(at: CGPoint(x: 700, y: 500)))
        XCTAssertEqual(player.physicsBody?.isDynamic, true)
        XCTAssertGreaterThan(player.physicsBody?.velocity.dx ?? 0, 0)
        XCTAssertGreaterThan(player.physicsBody?.velocity.dy ?? 0, 0)
    }
}
