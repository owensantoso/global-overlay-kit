import AppKit
import DesktopPhysicsKit
import Foundation

/// App-owned transport; the physics world never depends on HTTP or pairing.
@MainActor
final class PhoneWorldConnection: ObservableObject {
    @Published private(set) var enabled = false
    @Published private(set) var connected = false
    @Published private(set) var status = "Phone screen is off."
    @Published private(set) var pairingURL: URL?
    @Published private(set) var macSize = CGSize(width: 1200, height: 800)
    @Published private(set) var region: CGRect?
    @Published var edge: DesktopPhoneEdge = .right
    @Published var alignment: Double = 0
    @Published var scale: Double = 0.4

    private let world: DesktopPhysicsWorld
    private let instanceID = UUID().uuidString
    private var loop: Task<Void, Never>?
    private var rotateRequested = false
    private var lastRecoverSequence = 0
    private var config: Config?
    private var sequence = 0
    private var generation = 0
    private let session: URLSession

    private struct Config: Decodable {
        let nativeSecret: String
        let port: Int
    }
    private struct Layout: Encodable {
        let edge: DesktopPhoneEdge
        let alignment: Double
        let scale: Double
    }
    private struct Request: Encodable {
        let instanceID: String
        let sequence: Int
        let enabled: Bool
        let snapshot: DesktopPhoneSnapshot
        let layout: Layout
        let rotate: Bool
    }
    private struct Region: Decodable {
        let x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat
        var rect: CGRect { CGRect(x: x, y: y, width: width, height: height) }
    }
    private struct Reply: Decodable {
        let connected: Bool
        let joinURL: URL?
        let region: Region?
        let input: DesktopPhoneInput
        let recoverSequence: Int
    }

    init(world: DesktopPhysicsWorld) {
        self.world = world
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 0.8
        configuration.timeoutIntervalForResource = 1
        configuration.urlCache = nil
        session = URLSession(configuration: configuration)
    }

    func connect() {
        guard !enabled else { return }
        do {
            let path = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/Desktop Phone World/config.json")
            let value = try JSONDecoder().decode(Config.self, from: Data(contentsOf: path))
            guard (1024...65535).contains(value.port), value.nativeSecret.count >= 32 else {
                throw URLError(.badServerResponse)
            }
            config = value
        } catch {
            status = "Phone companion is unavailable. Open the installed companion before connecting."
            return
        }
        if !world.hasPlayer { world.spawnPlayer(appearance: .stickFigure) }
        enabled = true
        rotateRequested = true
        status = "Connecting to phone companion…"
        loop = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, self.enabled else { return }
                do {
                    let rotate = self.rotateRequested
                    let generation = self.generation
                    let reply = try await self.exchange(self.makeRequest(enabled: true, rotate: rotate))
                    guard !Task.isCancelled, self.enabled else { return }
                    guard generation == self.generation else { continue }
                    if rotate { self.rotateRequested = false }
                    self.apply(reply)
                    try await Task.sleep(for: .milliseconds(33))
                } catch {
                    guard !Task.isCancelled, self.enabled else { return }
                    self.releasePhone()
                    self.status = "Companion disconnected. Retrying…"
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }
        }
    }

    func disconnect() {
        // Allocate the retirement sequence now, before a possible reconnect.
        let retirement = try? makeRequest(enabled: false, rotate: false)
        generation += 1
        enabled = false
        loop?.cancel()
        loop = nil
        releasePhone()
        pairingURL = nil
        status = "Phone screen is off. Character is on the Mac."
        // Best effort retirement; native/phone TTLs also retire an interrupted connection.
        if let retirement {
            Task { [weak self] in _ = try? await self?.exchange(retirement) }
        }
    }

    func newPairing() {
        generation += 1
        releasePhone()
        pairingURL = nil
        rotateRequested = true
        status = "Creating a new pairing…"
    }

    func returnToMac() { world.returnPhonePlayerToMac() }

    private func releasePhone() {
        world.setPhoneInput(.released)
        world.setPhoneRegion(nil)
        if region != nil { region = nil }
        if connected { connected = false }
    }

    private func makeRequest(enabled: Bool, rotate: Bool) throws -> URLRequest {
        guard let config else { throw URLError(.cannotConnectToHost) }
        let snapshot = world.phoneSnapshot
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(config.port)/phone-world/api/native")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.nativeSecret)", forHTTPHeaderField: "Authorization")
        sequence += 1
        request.httpBody = try JSONEncoder().encode(Request(
            instanceID: instanceID, sequence: sequence, enabled: enabled, snapshot: snapshot,
            layout: Layout(edge: edge, alignment: alignment, scale: scale), rotate: rotate
        ))
        return request
    }

    private func exchange(_ request: URLRequest) async throws -> Reply {
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Reply.self, from: data)
    }

    private func apply(_ reply: Reply) {
        let snapshot = world.phoneSnapshot
        let nextSize = CGSize(width: snapshot.width, height: snapshot.height)
        if macSize != nextSize { macSize = nextSize }
        let nextRegion = reply.region?.rect
        world.setPhoneRegion(nextRegion)
        world.setPhoneInput(reply.connected ? reply.input : .released)
        if reply.recoverSequence != lastRecoverSequence {
            world.returnPhonePlayerToMac()
            lastRecoverSequence = reply.recoverSequence
        }
        if region != nextRegion { region = nextRegion }
        if connected != reply.connected {
            connected = reply.connected
            status = reply.connected ? "Phone connected" : "Phone disconnected; character returned to Mac."
        } else if !reply.connected && status != "Phone disconnected; character returned to Mac." {
            status = "Waiting for phone"
        }
        if pairingURL != reply.joinURL { pairingURL = reply.joinURL }
    }
}
