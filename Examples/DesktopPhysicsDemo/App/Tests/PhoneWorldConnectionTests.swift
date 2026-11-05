import AppKit
import DesktopPhysicsKit
import Foundation
import SwiftUI
import XCTest
@testable import DesktopPhysicsDemo

@MainActor
final class PhoneWorldConnectionTests: XCTestCase {
    func testSecondPhoneJoinsMacWhenFirstPhoneIsOnTheLeft() async throws {
        let fixture = try Fixture(phones: [.init("one", 1)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(1)
        let first = try fixture.item("one")
        fixture.connection.moveScreen(.init(id: first.id,
            rect: CGRect(x: -first.screen.width, y: 0,
                width: first.screen.width, height: first.screen.height)), maxDistance: 0)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one"])

        fixture.server.setPhones([.init("one", 1), .init("two", 2)])
        try await fixture.waitForPhones(2)
        let second = try fixture.item("two")
        XCTAssertEqual(second.screen.x, fixture.connection.macSize.width)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one", "two"])
        XCTAssertEqual(try fixture.item("one").screen.rect, first.screen.rect.offsetBy(dx: -first.screen.width - first.screen.x, dy: 0))
        XCTAssertEqual(second.label, "Phone 2")
        XCTAssertEqual(fixture.connection.selectedID, "two")
    }

    func testNewPhoneConnectsToRootAfterMiddlePhoneGoesOffline() async throws {
        let fixture = try Fixture(phones: [.init("one", 1), .init("two", 2), .init("three", 3)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(3)
        fixture.server.setPhones([.init("one", 1, connected: false), .init("two", 2), .init("three", 3)])
        try await eventually { fixture.connection.activeScreenIDs.isEmpty }
        XCTAssertEqual(fixture.connection.stateText(for: try fixture.item("one")), "Offline")
        XCTAssertEqual(fixture.connection.stateText(for: try fixture.item("two")), "Needs connection")

        fixture.server.setPhones([.init("one", 1, connected: false), .init("two", 2), .init("three", 3), .init("four", 4)])
        try await fixture.waitForPhones(4)
        XCTAssertTrue(fixture.connection.activeScreenIDs.contains("four"))
        XCTAssertTrue(fixture.world.phoneSnapshot.seams.contains {
            ($0.from == "mac" && $0.to == "four") || ($0.to == "mac" && $0.from == "four")
        })
        XCTAssertEqual(try fixture.item("two").label, "Phone 2")
    }

    func testUnrelatedResizePreservesEqualHeightStaggeredPhones() async throws {
        let fixture = try Fixture(phones: [.init("one", 1), .init("two", 2), .init("three", 3)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(3)
        let third = try fixture.item("three")
        fixture.connection.moveScreen(.init(id: third.id,
            rect: CGRect(x: -third.screen.width, y: 0,
                width: third.screen.width, height: third.screen.height)), maxDistance: 0)
        let first = try fixture.item("one")
        let second = try fixture.item("two")
        fixture.connection.moveScreen(.init(id: second.id,
            rect: CGRect(x: first.screen.rect.maxX, y: first.screen.y + 100,
                width: second.screen.width, height: second.screen.height)), maxDistance: 0)
        let oneBefore = try fixture.item("one").screen.rect
        let twoBefore = try fixture.item("two").screen.rect
        XCTAssertEqual(twoBefore.minY - oneBefore.minY, 100)
        XCTAssertEqual(twoBefore.height, oneBefore.height)

        fixture.connection.setScale(0.55, for: "three")
        XCTAssertEqual(try fixture.item("one").screen.rect, oneBefore)
        XCTAssertEqual(try fixture.item("two").screen.rect, twoBefore)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one", "two", "three"])
    }

    func testOverlappingReconnectionDoesNotCloseTheLiveWorld() async throws {
        let fixture = try Fixture(phones: [.init("one", 1), .init("two", 2), .init("three", 3)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(3)
        let originalFirst = try fixture.item("one")
        fixture.server.setPhones([.init("one", 1, connected: false), .init("two", 2), .init("three", 3)])
        try await eventually { fixture.connection.activeScreenIDs.isEmpty }
        let third = try fixture.item("three")
        fixture.connection.moveScreen(.init(id: third.id, rect: originalFirst.screen.rect), maxDistance: 0)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["two", "three"])
        let liveTwo = try fixture.item("two").screen.rect
        let liveThree = try fixture.item("three").screen.rect

        fixture.server.setPhones([.init("one", 1), .init("two", 2), .init("three", 3)])
        try await eventually { fixture.connection.phones.first(where: { $0.id == "one" })?.connected == true }
        XCTAssertTrue(try fixture.item("one").needsPlacement)
        XCTAssertEqual(fixture.connection.stateText(for: try fixture.item("one")), "Needs connection")
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["two", "three"])
        XCTAssertEqual(try fixture.item("two").screen.rect, liveTwo)
        XCTAssertEqual(try fixture.item("three").screen.rect, liveThree)
        XCTAssertEqual(try fixture.item("one").label, "Phone 1")
    }

    func testMiddleResizeAndRotationKeepDescendantAttached() async throws {
        let fixture = try Fixture(phones: [.init("one", 1), .init("two", 2), .init("three", 3)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(3)
        let firstBefore = try fixture.item("one").screen.rect
        fixture.connection.setScale(0.55, for: "two")
        var second = try fixture.item("two")
        var third = try fixture.item("three")
        XCTAssertEqual(third.screen.x, second.screen.rect.maxX)
        XCTAssertEqual(third.screen.y, second.screen.y)
        XCTAssertEqual(try fixture.item("one").screen.rect, firstBefore)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one", "two", "three"])
        let previousHeight = second.screen.height

        fixture.server.setPhones([.init("one", 1), .init("two", 2, viewport: CGSize(width: 650, height: 390)), .init("three", 3)])
        try await eventually { fixture.connection.phones.first(where: { $0.id == "two" })?.viewport.width == 650 }
        second = try fixture.item("two")
        third = try fixture.item("three")
        XCTAssertNotEqual(second.screen.height, previousHeight)
        XCTAssertEqual(third.screen.x, second.screen.rect.maxX)
        XCTAssertEqual(third.screen.y, second.screen.y)
        XCTAssertEqual(try fixture.item("one").screen.rect, firstBefore)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one", "two", "three"])
    }

    func testRemovalCannotBeUndoneByAnInflightReply() async throws {
        let fixture = try Fixture(phones: [.init("one", 1), .init("two", 2)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(2)
        fixture.server.holdNextStep()
        try await eventually { fixture.server.hasHeldReply }
        var observedIDs: [Set<String>] = []
        let observation = fixture.connection.$phones.sink { observedIDs.append(Set($0.map(\.id))) }
        defer { observation.cancel() }
        fixture.connection.removePhone("two")
        observedIDs.removeAll()
        fixture.server.releaseHeldReply()
        try await eventually { fixture.server.removedIDs.contains("two") }
        try await eventually { fixture.connection.phones.count == 1 && fixture.connection.activeScreenIDs == ["one"] }
        XCTAssertFalse(observedIDs.contains { $0.contains("two") })
        XCTAssertEqual(try fixture.item("one").label, "Phone 1")
        XCTAssertEqual(fixture.connection.selectedID, "one")
    }

    func testInvalidDropKeepsPreviousRectangleAndIdentity() async throws {
        let fixture = try Fixture(phones: [.init("one", 1)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(1)
        let before = try fixture.item("one")
        fixture.connection.moveScreen(.init(id: "one",
            rect: CGRect(x: 20, y: 20, width: before.screen.width, height: before.screen.height)), maxDistance: 0)
        XCTAssertEqual(try fixture.item("one"), before)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one"])
        XCTAssertNotNil(fixture.connection.layoutMessage)
    }

    func testQuarterTurnSwapsDimensionsAndRestoresWithoutChangingIdentityOrScale() async throws {
        let fixture = try Fixture(phones: [.init("one", 1)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(1)
        fixture.connection.setScale(0.55, for: "one")
        let original = try fixture.item("one")
        let playerID = fixture.world.phoneSnapshot.player?.id

        fixture.connection.rotateScreen("one")
        let turned = try fixture.item("one")
        XCTAssertEqual(turned.id, original.id)
        XCTAssertEqual(turned.label, original.label)
        XCTAssertEqual(turned.screen.rotation, 90)
        XCTAssertEqual(turned.screen.width, original.screen.height, accuracy: 0.001)
        XCTAssertEqual(turned.screen.height, original.screen.width, accuracy: 0.001)
        XCTAssertEqual(turned.scale, original.scale)
        XCTAssertEqual(fixture.connection.scale(for: "one"), 0.55)
        XCTAssertEqual(fixture.world.phoneSnapshot.player?.id, playerID)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one"])

        fixture.connection.rotateScreen("one")
        XCTAssertEqual(try fixture.item("one"), original)
        XCTAssertEqual(fixture.world.phoneSnapshot.player?.id, playerID)
    }

    func testMovingAndNudgingKeepTheSelectedScreenQuarterTurn() async throws {
        let fixture = try Fixture(phones: [.init("one", 1)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(1)
        fixture.connection.rotateScreen("one")
        let turned = try fixture.item("one")
        let destination = CGRect(x: -turned.screen.width, y: 0,
            width: turned.screen.width, height: turned.screen.height)
        // Drag proposals carry a rectangle; the model retains the screen's rotation.
        fixture.connection.moveScreen(.init(id: "one", rect: destination), maxDistance: 0)
        XCTAssertEqual(try fixture.item("one").screen.rect, destination)
        XCTAssertEqual(try fixture.item("one").screen.rotation, 90)
        fixture.connection.nudgeScreen("one", direction: .up)
        let nudged = try fixture.item("one")
        XCTAssertGreaterThan(nudged.screen.y, destination.minY)
        XCTAssertEqual(nudged.screen.x, destination.minX)
        XCTAssertEqual(nudged.screen.rotation, 90)
        XCTAssertEqual(nudged.scale, turned.scale)
        XCTAssertEqual(fixture.world.phoneScreens.first?.rotation, 90)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one"])
    }

    func testResizePreviewLeavesTheLiveChainUntouchedUntilCommit() async throws {
        let fixture = try Fixture(phones: [.init("one", 1), .init("two", 2), .init("three", 3)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(3)
        let before = fixture.connection.phones
        let worldBefore = fixture.world.phoneScreens
        let preview = try XCTUnwrap(fixture.connection.resizePreview(0.55, for: "two"))
        let childPreview = try XCTUnwrap(preview.screens.first { $0.id == "three" })
        XCTAssertGreaterThan(preview.screen.width, try fixture.item("two").screen.width)
        XCTAssertEqual(childPreview.x, preview.screen.rect.maxX)
        XCTAssertNotEqual(childPreview.x, try fixture.item("three").screen.x)
        XCTAssertEqual(fixture.connection.phones, before)
        XCTAssertEqual(fixture.world.phoneScreens, worldBefore)

        fixture.connection.setScale(preview.scale, for: "two")
        XCTAssertEqual(try fixture.item("two").screen, preview.screen)
        XCTAssertEqual(try fixture.item("three").screen, childPreview)
        XCTAssertEqual(fixture.world.phoneScreens.sorted { $0.id < $1.id }, preview.screens.sorted { $0.id < $1.id })
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one", "two", "three"])
    }

    func testOverlappingResizePreviewIsRejectedWithoutChangingTheWorld() async throws {
        let fixture = try Fixture(phones: [.init("one", 1), .init("two", 2)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(2)
        let first = try fixture.item("one")
        let second = try fixture.item("two")
        // Both screens touch the Mac directly, so the upper sibling must not move
        // merely to accommodate a larger lower screen.
        fixture.connection.moveScreen(.init(id: "two", rect: CGRect(
            x: fixture.connection.macSize.width, y: first.screen.rect.maxY,
            width: second.screen.width, height: second.screen.height)), maxDistance: 0)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one", "two"])
        let before = fixture.connection.phones
        let worldBefore = fixture.world.phoneScreens
        XCTAssertNil(fixture.connection.resizePreview(0.9, for: "one"))
        XCTAssertEqual(fixture.connection.phones, before)
        XCTAssertEqual(fixture.world.phoneScreens, worldBefore)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one", "two"])
    }

    func testScalingActiveScreenPreservesWorldWithAnUnrelatedInactiveChain() async throws {
        let fixture = try Fixture(phones: [.init("one", 1), .init("two", 2), .init("three", 3)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(3)
        let first = try fixture.item("one")
        fixture.connection.moveScreen(.init(id: "one", rect: CGRect(
            x: -first.screen.width, y: 0, width: first.screen.width, height: first.screen.height)), maxDistance: 0)
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one"])
        XCTAssertEqual(fixture.connection.stateText(for: try fixture.item("two")), "Needs connection")
        let inactiveBefore = try [fixture.item("two"), fixture.item("three")]
        XCTAssertNotNil(fixture.connection.resizePreview(0.55, for: "one"))

        fixture.connection.setScale(0.55, for: "one")
        XCTAssertEqual(fixture.connection.activeScreenIDs, ["one"])
        XCTAssertGreaterThan(try fixture.item("one").screen.width, first.screen.width)
        XCTAssertEqual(try [fixture.item("two"), fixture.item("three")], inactiveBefore)
        XCTAssertEqual(fixture.world.phoneScreens.map(\.id), ["one"])
        XCTAssertFalse(try fixture.item("one").needsPlacement)
    }

    func testCapturesNativeArrangementWithSyntheticPairing() async throws {
        let fixture = try Fixture(phones: [.init("one", 1), .init("two", 2), .init("three", 3)])
        addTeardownBlock { await fixture.close() }
        try await fixture.waitForPhones(3)
        let third = try fixture.item("three")
        fixture.connection.moveScreen(.init(id: third.id,
            rect: CGRect(x: fixture.connection.macSize.width - third.screen.width, y: -third.screen.height,
                width: third.screen.width, height: third.screen.height)), maxDistance: 0)
        let host = NSHostingView(rootView: PhoneWorldView(connection: fixture.connection))
        let window = NSWindow(contentRect: CGRect(x: -2_000, y: -2_000, width: 780, height: 720),
            styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.frame = CGRect(x: 0, y: 0, width: 780, height: 720)
        host.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        attachment.name = "Native phone arrangement with synthetic pairing"
        attachment.lifetime = .keepAlways
        add(attachment)
        if let evidence = ProcessInfo.processInfo.environment["PHONE_WORLD_TEST_EVIDENCE_DIR"] {
            let directory = URL(fileURLWithPath: evidence, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try png.write(to: directory.appendingPathComponent("native-arrangement.png"))
        }
        window.contentView = nil
    }

    private func eventually(timeout: TimeInterval = 5, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            guard Date() < deadline else {
                XCTFail("Timed out waiting for the mock native exchange")
                throw TestFailure.timeout
            }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private enum TestFailure: Error { case timeout }

    @MainActor
    private final class Fixture {
        let server: NativeMock
        let world: DesktopPhysicsWorld
        let connection: PhoneWorldConnection
        private let session: URLSession
        private let directory: URL

        init(phones: [MockPhone]) throws {
            guard let screen = NSScreen.main else { throw XCTSkip("A Mac display is required for the native world") }
            directory = FileManager.default.temporaryDirectory.appendingPathComponent("phone-world-app-tests-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            server = NativeMock(phones: phones)
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockNativeProtocol.self]
            session = URLSession(configuration: configuration)
            let config = directory.appendingPathComponent("config.json")
            try JSONSerialization.data(withJSONObject: ["nativeSecret": "synthetic-native-test-secret-000000000000", "port": server.port]).write(to: config)
            MockNativeProtocol.register(server)
            world = DesktopPhysicsWorld(screen: screen)
            connection = PhoneWorldConnection(world: world, configurationURL: config, session: session)
            connection.connect()
        }

        func item(_ id: String) throws -> PhoneScreenItem {
            try XCTUnwrap(connection.phones.first { $0.id == id })
        }

        func waitForPhones(_ count: Int) async throws {
            let deadline = Date().addingTimeInterval(5)
            while connection.phones.count != count {
                guard Date() < deadline else {
                    XCTFail("Mock phone descriptors did not arrive")
                    throw TestFailure.timeout
                }
                try await Task.sleep(nanoseconds: 10_000_000)
            }
        }

        func close() async {
            connection.disconnect()
            // disconnect queues its retirement exchange on the main actor. Observing the
            // mock's disabled request proves that task was created before invalidation.
            let retirement = await XCTWaiter.fulfillment(of: [server.retirement], timeout: 3)
            XCTAssertEqual(retirement, .completed, "The mock native session did not retire")
            session.invalidateAndCancel()
            MockNativeProtocol.unregister(server)
            world.stop()
            try? FileManager.default.removeItem(at: directory)
        }
    }
}

private struct MockPhone {
    let id: String
    let label: String
    var connected: Bool
    var viewport: CGSize

    init(_ id: String, _ number: Int, connected: Bool = true, viewport: CGSize = CGSize(width: 390, height: 650)) {
        self.id = id
        label = "Phone \(number)"
        self.connected = connected
        self.viewport = viewport
    }

    var json: [String: Any] {
        ["id": id, "label": label, "connected": connected,
            "viewport": ["width": viewport.width, "height": viewport.height]]
    }
}

private final class NativeMock {
    let port = Int.random(in: 20_000...60_000)
    let retirement = XCTestExpectation(description: "Mock native session observed retirement")
    private let lock = NSLock()
    private var phones: [MockPhone]
    private var hold = false
    private var held: (MockNativeProtocol, Data)?
    private var removals: Set<String> = []
    private var didRetire = false

    init(phones: [MockPhone]) { self.phones = phones }
    var hasHeldReply: Bool { lock.withLock { held != nil } }
    var removedIDs: Set<String> { lock.withLock { removals } }
    func setPhones(_ phones: [MockPhone]) { lock.withLock { self.phones = phones } }
    func holdNextStep() { lock.withLock { hold = true } }

    func respond(to transport: MockNativeProtocol, body: Data) throws {
        let request = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        var observedRetirement = false
        let reply: Data? = try lock.withLock {
            let removed = request["removeIDs"] as? [String] ?? []
            removals.formUnion(removed)
            phones.removeAll { removed.contains($0.id) }
            let enabled = request["enabled"] as? Bool ?? false
            if !enabled && !didRetire {
                didRetire = true
                observedRetirement = true
            }
            let data = try JSONSerialization.data(withJSONObject: [
                "connected": enabled && phones.contains(where: \.connected),
                "joinURL": enabled ? "https://phone-world-test.invalid/phone-world/#token=synthetic-fixture-only" as Any : NSNull(),
                "input": ["left": false, "right": false, "jump": false, "run": false],
                "recoverSequence": 0,
                "phones": enabled ? phones.map(\.json) : []
            ])
            if enabled && hold {
                hold = false
                held = (transport, data)
                return nil
            }
            return data
        }
        if let reply { transport.finish(reply) }
        if observedRetirement { retirement.fulfill() }
    }

    func releaseHeldReply() {
        let pending = lock.withLock { () -> (MockNativeProtocol, Data)? in
            defer { held = nil }
            return held
        }
        if let (transport, data) = pending { transport.finish(data) }
    }
}

private final class MockNativeProtocol: URLProtocol {
    private static let registryLock = NSLock()
    private static var servers: [Int: NativeMock] = [:]
    private let stateLock = NSLock()
    private var stopped = false

    static func register(_ server: NativeMock) { registryLock.withLock { servers[server.port] = server } }
    static func unregister(_ server: NativeMock) { _ = registryLock.withLock { servers.removeValue(forKey: server.port) } }
    override class func canInit(with request: URLRequest) -> Bool {
        // Intercept every request from the injected session, so a test can never reach a service.
        true
    }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            guard let port = request.url?.port,
                  let server = Self.registryLock.withLock({ Self.servers[port] }) else {
                throw URLError(.cannotConnectToHost)
            }
            var body = request.httpBody ?? Data()
            if let stream = request.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var buffer = [UInt8](repeating: 0, count: 16_384)
                while true {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    if count == 0 { break }
                    if count < 0 { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
                    body.append(contentsOf: buffer.prefix(count))
                }
            }
            try server.respond(to: self, body: body)
        } catch {
            let active = stateLock.withLock { !stopped }
            if active { client?.urlProtocol(self, didFailWithError: error) }
        }
    }

    override func stopLoading() { stateLock.withLock { stopped = true } }

    func finish(_ data: Data) {
        let active = stateLock.withLock { !stopped }
        guard active, let url = request.url else { return }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
}
