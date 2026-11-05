import AppKit
import CoreGraphics
import SpriteKit
import XCTest
@testable import DesktopPhysicsKit

private final class PhoneTestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var time: TimeInterval = 100
    func now() -> TimeInterval { lock.withLock { time } }
    func advance(_ amount: TimeInterval) { lock.withLock { time += amount } }
}

final class PhoneWorldTests: XCTestCase {
    func testPlacementUsesLogicalCoordinatesAndClampsInvalidDimensions() {
        let mac = CGSize(width: 800, height: 600)
        XCTAssertEqual(DesktopPhoneLayout(edge: .right, alignment: 0, width: 300, height: 500).rect(adjacentTo: mac), CGRect(x: 800, y: 0, width: 300, height: 500))
        XCTAssertEqual(DesktopPhoneLayout(edge: .left, alignment: 1, width: 300, height: 500).rect(adjacentTo: mac), CGRect(x: -300, y: 100, width: 300, height: 500))
        XCTAssertEqual(DesktopPhoneLayout(edge: .bottom, alignment: 1, width: 300, height: 500).rect(adjacentTo: mac), CGRect(x: 500, y: -500, width: 300, height: 500))
        XCTAssertEqual(DesktopPhoneLayout(edge: .top, alignment: 0.5, width: 300, height: 500).rect(adjacentTo: mac), CGRect(x: 250, y: 600, width: 300, height: 500))
        let bounded = DesktopPhoneLayout(alignment: .infinity, width: -1, height: 50_000)
        XCTAssertEqual(bounded.alignment, 0)
        XCTAssertEqual(bounded.width, 100)
        XCTAssertEqual(bounded.height, 2_000)
    }

    func testEverySharedEdgeIsOpenWhileExteriorStaysClosed() throws {
        let mac = CGSize(width: 800, height: 600)
        for edge in DesktopPhoneEdge.allCases {
            let rect = DesktopPhoneLayout(edge: edge, alignment: 0.5, width: 300, height: 500).rect(adjacentTo: mac)
            let geometry = try XCTUnwrap(DesktopPhoneGeometry(macSize: mac, phone: rect))
            let middle = CGPoint(x: (geometry.seam.start.x + geometry.seam.end.x) / 2, y: (geometry.seam.start.y + geometry.seam.end.y) / 2)
            XCTAssertFalse(geometry.boundary.contains { contains($0, middle) }, "Blocked seam: \(edge)")
            let outside = edge == .right
                ? CGPoint(x: rect.maxX, y: rect.midY)
                : edge == .left
                    ? CGPoint(x: rect.minX, y: rect.midY)
                    : edge == .bottom
                        ? CGPoint(x: rect.midX, y: rect.minY)
                        : CGPoint(x: rect.midX, y: rect.maxY)
            XCTAssertTrue(geometry.boundary.contains { contains($0, outside) }, "Missing exterior: \(edge)")
            XCTAssertFalse(geometry.boundary.contains { contains($0, CGPoint(x: 20, y: 600)) }, "Mac top must stay open")
        }
        XCTAssertNil(DesktopPhoneGeometry(macSize: mac, phone: CGRect(x: 900, y: 0, width: 300, height: 500)))
        XCTAssertNil(DesktopPhoneGeometry(macSize: mac, phone: CGRect(x: 800, y: 590, width: 300, height: 500)))
    }

    func testStairsConnectDifferentFloorHeightsWithReachableRises() throws {
        let mac = CGSize(width: 800, height: 600)
        for edge in DesktopPhoneEdge.allCases {
            let phone = DesktopPhoneLayout(edge: edge, alignment: 1, width: 300, height: 500).rect(adjacentTo: mac)
            let geometry = try XCTUnwrap(DesktopPhoneGeometry(macSize: mac, phone: phone))
            let stairs = geometry.stairPlatforms()
            let difference = abs(phone.minY)
            if difference == 0 { XCTAssertTrue(stairs.isEmpty); continue }
            XCTAssertFalse(stairs.isEmpty)
            var previous = min(0, phone.minY)
            for platform in stairs {
                XCTAssertLessThanOrEqual(platform.y - previous, 100.001)
                XCTAssertGreaterThan(platform.width, 30)
                previous = platform.y
            }
            XCTAssertEqual(previous, max(0, phone.minY), accuracy: 0.001)
        }
    }

    func testRemoteInputWorksWithoutKeyboardPermissionAndExpires() {
        let clock = PhoneTestClock()
        let input = DesktopGameInputState(monotonicTime: clock.now)
        XCTAssertFalse(input.isActive)
        input.setPhoneInput(.init(right: true, jump: true, run: true))
        let first = input.consumeSnapshot()
        XCTAssertEqual(first.horizontalDirection, 1)
        XCTAssertEqual(first.jumpPressedAt, 100)
        XCTAssertTrue(first.jumpHeld)
        XCTAssertTrue(first.runHeld)
        input.consumeJumpRequest()
        clock.advance(0.1)
        input.setPhoneInput(.init(right: true, jump: true, run: true))
        XCTAssertNil(input.consumeSnapshot().jumpPressedAt, "Held jump heartbeat must not create another jump")
        clock.advance(0.41)
        let expired = input.consumeSnapshot()
        XCTAssertEqual(expired.horizontalDirection, 0)
        XCTAssertFalse(expired.jumpHeld)
        XCTAssertFalse(expired.runHeld)
        XCTAssertNil(expired.jumpPressedAt)
        input.setPhoneInput(.init(jump: true))
        XCTAssertEqual(input.consumeSnapshot().jumpPressedAt, clock.now())
        input.setPhoneInput(.released)
        XCTAssertNil(input.consumeSnapshot().jumpPressedAt)
    }

    func testLocalAndRemoteOpposingInputsCancelAndReleaseIndependently() {
        let input = DesktopGameInputState()
        input.activate()
        XCTAssertTrue(input.shouldDiscard(type: .keyDown, keyCode: 0, flags: []))
        input.setPhoneInput(.init(right: true))
        XCTAssertEqual(input.consumeSnapshot().horizontalDirection, 0)
        input.setPhoneInput(.released)
        XCTAssertEqual(input.consumeSnapshot().horizontalDirection, -1)
        input.setPhoneInput(.init(right: true))
        input.deactivate()
        XCTAssertEqual(input.consumeSnapshot().horizontalDirection, 1)
    }

    @MainActor
    func testSamePlayerAndMomentumSurviveCrossingAndReturnRescuesIt() throws {
        let scene = makeScene()
        scene.spawnPlayer(appearance: .stickFigure)
        let rect = DesktopPhoneLayout(width: 300, height: 500).rect(adjacentTo: scene.size)
        scene.setPhoneRegion(rect)
        let node = try XCTUnwrap(scene.children.first { $0.name == "desktop-physics-player" })
        let id = try XCTUnwrap(scene.phoneSnapshot.player?.id)
        node.position = CGPoint(x: 780, y: 100)
        node.physicsBody?.velocity = CGVector(dx: 300, dy: -15)
        node.position.x = 820
        scene.setPhoneRegion(rect)
        let crossed = try XCTUnwrap(scene.phoneSnapshot.player)
        XCTAssertEqual(crossed.id, id)
        XCTAssertEqual(crossed.x, 820)
        XCTAssertEqual(crossed.vx, 300)
        XCTAssertEqual(crossed.vy, -15)
        XCTAssertEqual(crossed.asset, "fighter_Idle_0001.png")
        XCTAssertEqual(crossed.spriteWidth, 270)
        XCTAssertEqual(scene.size, CGSize(width: 800, height: 600))
        node.position.x = 780
        XCTAssertEqual(scene.phoneSnapshot.player?.id, id)
        XCTAssertEqual(scene.phoneSnapshot.player?.vx, 300)
        node.position.x = 900
        scene.setPhoneRegion(nil)
        let rescued = try XCTUnwrap(scene.phoneSnapshot.player)
        XCTAssertEqual(rescued.id, id)
        XCTAssertLessThan(rescued.x + rescued.width / 2, 800)
        XCTAssertEqual(rescued.vx, 0)
        XCTAssertEqual(rescued.vy, 0)
        XCTAssertNil(scene.phoneRegion)
        XCTAssertTrue(scene.phoneSnapshot.platforms.isEmpty)
        scene.spawnPlayer()
        XCTAssertNotEqual(scene.phoneSnapshot.player?.id, id)
    }

    @MainActor
    func testRelayoutReturnsOffscreenPlayerAndSnapshotRoundTrips() throws {
        let scene = makeScene()
        scene.spawnPlayer()
        scene.setPhoneRegion(CGRect(x: 800, y: 0, width: 300, height: 500))
        scene.setPlayerPositionForTesting(CGPoint(x: 900, y: 200))
        let id = scene.phoneSnapshot.player?.id
        scene.setPhoneRegion(CGRect(x: -300, y: 0, width: 300, height: 500))
        XCTAssertEqual(scene.phoneSnapshot.player?.id, id)
        XCTAssertLessThan(try XCTUnwrap(scene.phoneSnapshot.player).x, 800)
        XCTAssertEqual(try JSONDecoder().decode(DesktopPhoneSnapshot.self, from: JSONEncoder().encode(scene.phoneSnapshot)), scene.phoneSnapshot)
    }

    @MainActor
    func testRelayoutPreservesPlayerWhenNewUnionStillContainsItsWholeBody() throws {
        let scene = makeScene()
        scene.spawnPlayer()
        scene.setPhoneRegion(CGRect(x: 800, y: 0, width: 300, height: 500))
        let node = try XCTUnwrap(scene.children.first { $0.name == "desktop-physics-player" })
        node.position = CGPoint(x: 900, y: 200)
        node.physicsBody?.velocity = CGVector(dx: 100, dy: 50)
        let id = scene.phoneSnapshot.player?.id
        scene.setPhoneRegion(CGRect(x: 800, y: 0, width: 400, height: 550))
        XCTAssertEqual(scene.phoneSnapshot.player?.x, 900)
        XCTAssertEqual(scene.phoneSnapshot.player?.y, 200)
        XCTAssertEqual(scene.phoneSnapshot.player?.vx, 100)
        XCTAssertEqual(scene.phoneSnapshot.player?.vy, 50)
        XCTAssertEqual(scene.phoneSnapshot.player?.id, id)
        node.position.x = 800
        scene.setPhoneRegion(CGRect(x: 800, y: 0, width: 350, height: 500))
        XCTAssertEqual(scene.phoneSnapshot.player?.x, 800, "A body straddling a valid seam stays in place")
        XCTAssertEqual(scene.phoneSnapshot.player?.vx, 100)
    }

    @MainActor
    func testPhoneStepsLandOnlyWhenDescendingFromAbove() throws {
        let scene = makeScene()
        scene.spawnPlayer()
        scene.setPhoneRegion(CGRect(x: 500, y: -500, width: 300, height: 500))
        let platform = try XCTUnwrap(scene.phoneSnapshot.platforms.first)
        let node = try XCTUnwrap(scene.children.first { $0.name == "desktop-physics-player" })
        let halfHeight = try XCTUnwrap(scene.phoneSnapshot.player).height / 2
        node.position = CGPoint(x: platform.x + platform.width / 2, y: platform.y + halfHeight + 4)
        node.physicsBody?.velocity = CGVector(dx: 0, dy: -100)
        scene.update(1)
        node.position.y = platform.y + halfHeight - 4
        scene.didSimulatePhysics()
        XCTAssertEqual(node.position.y, platform.y + halfHeight, accuracy: 0.01)
        XCTAssertTrue(scene.playerIsGroundedForTesting)
        node.position.y = platform.y + halfHeight - 10
        node.physicsBody?.velocity = CGVector(dx: 0, dy: 100)
        scene.update(1.01)
        node.position.y = platform.y + halfHeight + 2
        scene.didSimulatePhysics()
        XCTAssertEqual(node.position.y, platform.y + halfHeight + 2, accuracy: 0.01)
    }

    @MainActor
    func testElapsedSpriteKitSimulationWalksIntoPhoneAndBack() async throws {
        let input = DesktopGameInputState()
        let scene = DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(), inputState: input
        )
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
        let window = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.animationBehavior = .none
        window.isReleasedWhenClosed = false
        window.contentView = view
        window.orderBack(nil)
        view.presentScene(scene)
        defer {
            input.setPhoneInput(.released)
            view.presentScene(nil)
            window.contentView = nil
            window.close()
        }
        scene.spawnPlayer()
        scene.setPhoneRegion(CGRect(x: 800, y: 0, width: 300, height: 500))
        scene.setPlayerPositionForTesting(CGPoint(x: 760, y: 100))
        scene.spawn(.init(shape: .circle, size: .diameter(48)))
        let ball = try XCTUnwrap(scene.children.first { $0.name == "desktop-physics-object" })
        ball.position = CGPoint(x: 760, y: 300)
        ball.physicsBody?.velocity = CGVector(dx: 300, dy: 0)
        var maximumBallX = ball.position.x
        let id = try XCTUnwrap(scene.phoneSnapshot.player?.id)
        for _ in 0..<60 {
            input.setPhoneInput(.init(right: true))
            try await Task.sleep(for: .milliseconds(50))
            maximumBallX = max(maximumBallX, ball.position.x)
            if (scene.phoneSnapshot.player?.x ?? 0) > 850 { break }
        }
        let phone = try XCTUnwrap(scene.phoneSnapshot.player)
        XCTAssertGreaterThan(phone.x, 850, "Elapsed SpriteKit physics must pass the opened Mac edge")
        XCTAssertEqual(phone.id, id)
        XCTAssertGreaterThan(phone.vx, 0)
        XCTAssertLessThanOrEqual(maximumBallX, 778, "Loose objects must stay inside the Mac while the player seam is open")
        for _ in 0..<60 {
            input.setPhoneInput(.init(left: true))
            try await Task.sleep(for: .milliseconds(50))
            if (scene.phoneSnapshot.player?.x ?? 1_000) < 750 { break }
        }
        let mac = try XCTUnwrap(scene.phoneSnapshot.player)
        XCTAssertLessThan(mac.x, 750, "The same node must walk back through the seam")
        XCTAssertEqual(mac.id, id)
        XCTAssertLessThan(mac.vx, 0)
    }

    @MainActor
    func testElapsedSpriteKitClimbsStepsBelowAndAboveTheMac() async throws {
        for edge in [DesktopPhoneEdge.bottom, .top] {
            let input = DesktopGameInputState()
            let scene = DesktopPhysicsScene(
                size: CGSize(width: 800, height: 600),
                screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
                configuration: .init(), inputState: input
            )
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 800, height: 600))
            let window = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
            window.animationBehavior = .none
            window.isReleasedWhenClosed = false
            window.contentView = view
            window.orderBack(nil)
            view.presentScene(scene)
            defer {
                input.setPhoneInput(.released)
                view.presentScene(nil)
                window.contentView = nil
                window.close()
            }
            scene.spawnPlayer()
            let phone = DesktopPhoneLayout(edge: edge, alignment: 0.5, width: 300, height: 500).rect(adjacentTo: scene.size)
            scene.setPhoneRegion(phone)
            let platforms = scene.phoneSnapshot.platforms
            let first = try XCTUnwrap(platforms.first)
            let halfHeight = try XCTUnwrap(scene.phoneSnapshot.player).height / 2
            let floor = min(0, phone.minY)
            // Start on the connected region's floor, then use only real input/physics.
            scene.setPlayerPositionForTesting(CGPoint(x: first.x + first.width / 2, y: floor + halfHeight + 1))
            let id = scene.phoneSnapshot.player?.id
            for _ in 0..<40 {
                input.setPhoneInput(.released)
                try await Task.sleep(for: .milliseconds(25))
                if scene.playerIsGroundedForTesting { break }
            }
            XCTAssertTrue(scene.playerIsGroundedForTesting)
            for platform in platforms {
                let targetX = platform.x + platform.width / 2
                var landed = false
                var maximumFoot: CGFloat = -.infinity
                var maximumUpwardSpeed: CGFloat = 0
                for frame in 0..<60 {
                    let player = try XCTUnwrap(scene.phoneSnapshot.player)
                    let delta = targetX - player.x
                    input.setPhoneInput(.init(
                        left: delta < -12, right: delta > 12,
                        jump: frame < 13
                    ))
                    try await Task.sleep(for: .milliseconds(25))
                    maximumFoot = max(maximumFoot, (scene.phoneSnapshot.player?.y ?? 0) - halfHeight)
                    maximumUpwardSpeed = max(maximumUpwardSpeed, scene.phoneSnapshot.player?.vy ?? 0)
                    if frame > 13, scene.playerIsGroundedForTesting,
                       abs((scene.phoneSnapshot.player?.y ?? 0) - halfHeight - platform.y) < 2 {
                        landed = true
                        break
                    }
                }
                XCTAssertTrue(landed, "Could not climb \(edge) platform at y=\(platform.y), peakFoot=\(maximumFoot), peakVy=\(maximumUpwardSpeed), player=\(String(describing: scene.phoneSnapshot.player))")
                XCTAssertEqual(scene.phoneSnapshot.player?.id, id)
                if !landed { break }
                input.setPhoneInput(.released)
                try await Task.sleep(for: .milliseconds(50))
            }
            XCTAssertGreaterThanOrEqual((scene.phoneSnapshot.player?.y ?? -.infinity) - halfHeight, max(0, phone.minY) - 2)
        }
    }

    @MainActor
    private func makeScene() -> DesktopPhysicsScene {
        DesktopPhysicsScene(
            size: CGSize(width: 800, height: 600),
            screenFrame: CGRect(x: 0, y: 0, width: 800, height: 600),
            configuration: .init(), inputState: DesktopGameInputState()
        )
    }

    private func contains(_ line: DesktopPhoneBoundarySegment, _ point: CGPoint) -> Bool {
        if line.start.x == line.end.x {
            return point.x == line.start.x && point.y >= min(line.start.y, line.end.y) && point.y <= max(line.start.y, line.end.y)
        }
        return point.y == line.start.y && point.x >= min(line.start.x, line.end.x) && point.x <= max(line.start.x, line.end.x)
    }
}
