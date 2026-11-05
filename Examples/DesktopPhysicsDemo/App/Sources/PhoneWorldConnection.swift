import AppKit
import DesktopPhysicsKit
import Foundation
import SwiftUI

struct PhoneScreenItem: Identifiable, Equatable {
    let id: String
    var label: String
    var viewport: CGSize
    var connected: Bool
    var screen: DesktopPhoneScreen
    var needsPlacement = false
    var scale: Double = 0.4
}

struct PhoneResizePreview {
    let scale: Double
    let screen: DesktopPhoneScreen
    let screens: [DesktopPhoneScreen]
}

/// Pairing and screen arrangement belong to the app; SpriteKit owns the character.
@MainActor
final class PhoneWorldConnection: ObservableObject {
    @Published private(set) var enabled = false
    @Published private(set) var status = "Phone screens are off."
    @Published private(set) var pairingURL: URL?
    @Published private(set) var macSize = CGSize(width: 1200, height: 800)
    @Published private(set) var phones: [PhoneScreenItem] = []
    @Published private(set) var activeScreenIDs: Set<String> = []
    @Published var selectedID: String?
    @Published private(set) var layoutMessage: String?

    private let world: DesktopPhysicsWorld
    private let instanceID = UUID().uuidString
    private var loop: Task<Void, Never>?
    private var rotateRequested = false
    private var pendingRemovals: Set<String> = []
    private var lastRecoverSequence = 0
    private var config: Config?
    private var sequence = 0
    private var generation = 0
    private let session: URLSession
    private let configurationURL: URL

    private struct Config: Decodable { let nativeSecret: String; let port: Int }
    private struct Request: Encodable {
        let instanceID: String
        let sequence: Int
        let enabled: Bool
        let snapshot: DesktopPhoneSnapshot
        let rotate: Bool
        let removeIDs: [String]
    }
    private struct Viewport: Decodable { let width: CGFloat; let height: CGFloat }
    private struct Phone: Decodable {
        let id: String
        let label: String
        let connected: Bool
        let viewport: Viewport
    }
    private struct Reply: Decodable {
        let connected: Bool
        let joinURL: URL?
        let input: DesktopPhoneInput
        let recoverSequence: Int
        let phones: [Phone]
    }
    private struct Anchor {
        let parent: String
        let edge: DesktopPhoneEdge
        let parallelOffset: CGFloat
    }

    init(world: DesktopPhysicsWorld, configurationURL: URL? = nil, session suppliedSession: URLSession? = nil) {
        self.world = world
        self.configurationURL = configurationURL ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Desktop Phone World/config.json")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 0.8
        configuration.timeoutIntervalForResource = 1
        configuration.urlCache = nil
        session = suppliedSession ?? URLSession(configuration: configuration)
    }

    func connect() {
        guard !enabled else { return }
        do {
            let value = try JSONDecoder().decode(Config.self, from: Data(contentsOf: configurationURL))
            guard (1024...65535).contains(value.port), value.nativeSecret.count >= 32 else { throw URLError(.badServerResponse) }
            config = value
        } catch {
            status = "Phone companion is unavailable."
            return
        }
        if !world.hasPlayer { world.spawnPlayer(appearance: .stickFigure) }
        phones = []
        enabled = true
        rotateRequested = true
        status = "Connecting to phone companion…"
        loop = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, self.enabled else { return }
                do {
                    let rotate = self.rotateRequested
                    let generation = self.generation
                    let removals = self.pendingRemovals
                    let reply = try await self.exchange(self.makeRequest(enabled: true, rotate: rotate))
                    guard !Task.isCancelled, self.enabled else { return }
                    guard generation == self.generation else { continue }
                    if rotate { self.rotateRequested = false }
                    self.pendingRemovals.subtract(removals)
                    self.apply(reply)
                    try await Task.sleep(for: .milliseconds(33))
                } catch {
                    guard !Task.isCancelled, self.enabled else { return }
                    self.releaseWorld()
                    self.status = "Companion disconnected. Retrying…"
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }
        }
    }

    func disconnect() {
        let retirement = try? makeRequest(enabled: false, rotate: false)
        generation += 1
        enabled = false
        loop?.cancel(); loop = nil
        releaseWorld()
        pairingURL = nil
        status = "Phone screens are off. Character is on the Mac."
        if let retirement { Task { [weak self] in _ = try? await self?.exchange(retirement) } }
    }

    func newPairing() {
        generation += 1
        releaseWorld()
        phones = []
        selectedID = nil
        pendingRemovals = []
        pairingURL = nil
        rotateRequested = true
        status = "Resetting all phone pairings…"
    }

    func removePhone(_ id: String) {
        generation += 1
        pendingRemovals.insert(id)
        phones.removeAll { $0.id == id }
        if selectedID == id { selectedID = phones.first?.id }
        reconcileWorld()
    }

    func returnToMac() { world.returnPhonePlayerToMac() }

    func stateText(for item: PhoneScreenItem) -> String {
        if !item.connected { return "Offline" }
        return activeScreenIDs.contains(item.id) ? "Connected" : "Needs connection"
    }

    func snappedScreen(_ proposed: DesktopPhoneScreen, maxDistance: CGFloat = 120) -> DesktopPhoneScreen? {
        let rotation = phones.first(where: { $0.id == proposed.id })?.screen.rotation ?? proposed.rotation
        let candidate = DesktopPhoneScreen(id: proposed.id, rect: proposed.rect, rotation: rotation)
        return DesktopPhonePlacement.snap(proposed: candidate, macSize: macSize,
            screens: phones.filter { $0.connected && !$0.needsPlacement && $0.id != proposed.id }.map(\.screen),
            maxDistance: maxDistance)
    }

    func moveScreen(_ proposed: DesktopPhoneScreen, maxDistance: CGFloat = 120) {
        guard let index = phones.firstIndex(where: { $0.id == proposed.id }) else { return }
        guard let snapped = snappedScreen(proposed, maxDistance: maxDistance) else {
            layoutMessage = "Place the screen against a connected edge."
            return
        }
        phones[index].screen = snapped
        phones[index].needsPlacement = false
        selectedID = proposed.id
        layoutMessage = nil
        reconcileWorld()
    }

    func nudgeScreen(_ id: String, direction: MoveCommandDirection) {
        guard let item = phones.first(where: { $0.id == id }) else { return }
        selectedID = id
        let amount: CGFloat = NSEvent.modifierFlags.contains(.shift) ? 60 : 20
        var rect = item.screen.rect
        switch direction {
        case .left: rect.origin.x -= amount
        case .right: rect.origin.x += amount
        case .up: rect.origin.y += amount
        case .down: rect.origin.y -= amount
        @unknown default: return
        }
        moveScreen(DesktopPhoneScreen(id: id, rect: rect))
    }

    func scale(for id: String) -> Double {
        phones.first(where: { $0.id == id })?.scale ?? 0.4
    }

    func setScale(_ scale: Double, for id: String) {
        guard let index = phones.firstIndex(where: { $0.id == id }) else { return }
        let anchors = attachmentAnchors()
        var updated = phones
        updated[index].scale = min(0.9, max(0.2, scale))
        let rotation = updated[index].screen.rotation
        let size = worldSize(viewport: updated[index].viewport, scale: updated[index].scale, rotation: rotation)
        updated[index].screen = DesktopPhoneScreen(id: id, rect: CGRect(origin: updated[index].screen.rect.origin, size: size), rotation: rotation)
        applyResizing(updated, anchors: anchors, changed: [id])
    }

    func rotateScreen(_ id: String) {
        guard let index = phones.firstIndex(where: { $0.id == id }) else { return }
        var updated = phones
        let rotation = updated[index].screen.rotation == 0 ? 90 : 0
        let size = worldSize(viewport: updated[index].viewport, scale: updated[index].scale, rotation: rotation)
        updated[index].screen = DesktopPhoneScreen(id: id, rect: CGRect(origin: updated[index].screen.rect.origin, size: size), rotation: rotation)
        applyResizing(updated, anchors: attachmentAnchors(), changed: [id])
    }

    func resizeDirections(for id: String) -> CGPoint {
        let edge = attachmentAnchors()[id]?.edge ?? .right
        return CGPoint(x: edge == .left ? -1 : 1, y: edge == .bottom ? -1 : 1)
    }

    func resizePreview(_ scale: Double, for id: String) -> PhoneResizePreview? {
        guard let index = phones.firstIndex(where: { $0.id == id }) else { return nil }
        var updated = phones
        let bounded = min(0.9, max(0.2, scale))
        let item = updated[index]
        let size = worldSize(viewport: item.viewport, scale: bounded, rotation: item.screen.rotation)
        updated[index].screen = DesktopPhoneScreen(id: id, rect: CGRect(origin: item.screen.rect.origin, size: size), rotation: item.screen.rotation)
        let (candidate, _) = reflow(updated, anchors: attachmentAnchors(), changed: [id])
        guard resizeIsValid(candidate), let selected = candidate.first(where: { $0.id == id }) else { return nil }
        return PhoneResizePreview(scale: bounded, screen: selected.screen,
            screens: candidate.filter { $0.connected && !$0.needsPlacement }.map(\.screen))
    }

    private func releaseWorld() {
        world.setPhoneInput(.released)
        world.setPhoneScreens([])
        if !activeScreenIDs.isEmpty { activeScreenIDs = [] }
    }

    private func makeRequest(enabled: Bool, rotate: Bool) throws -> URLRequest {
        guard let config else { throw URLError(.cannotConnectToHost) }
        var request = URLRequest(url: URL(string: "http://127.0.0.1:\(config.port)/phone-world/api/native")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.nativeSecret)", forHTTPHeaderField: "Authorization")
        sequence += 1
        request.httpBody = try JSONEncoder().encode(Request(instanceID: instanceID, sequence: sequence,
            enabled: enabled, snapshot: world.phoneSnapshot, rotate: rotate, removeIDs: pendingRemovals.sorted()))
        return request
    }

    private func exchange(_ request: URLRequest) async throws -> Reply {
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try JSONDecoder().decode(Reply.self, from: data)
    }

    private func apply(_ reply: Reply) {
        let snapshot = world.phoneSnapshot
        let nextSize = CGSize(width: snapshot.width, height: snapshot.height)
        let anchors = attachmentAnchors()
        let macSizeChanged = macSize != nextSize
        if macSizeChanged { macSize = nextSize }
        let liveIDs = Set(reply.phones.filter(\.connected).map(\.id)).subtracting(pendingRemovals)
        let priorIDs = Set(phones.map(\.id))
        var updated: [PhoneScreenItem] = []
        var changed: Set<String> = []
        for descriptor in reply.phones where !pendingRemovals.contains(descriptor.id) {
            let viewport = CGSize(width: descriptor.viewport.width, height: descriptor.viewport.height)
            guard viewport.width.isFinite, viewport.height.isFinite, viewport.width >= 100, viewport.height >= 100 else { continue }
            if var item = phones.first(where: { $0.id == descriptor.id }) {
                let reconnecting = !item.connected && descriptor.connected
                item.label = descriptor.label
                item.connected = descriptor.connected
                if reconnecting {
                    let occupied = [CGRect(origin: .zero, size: nextSize)]
                        + world.phoneScreens.filter { $0.id != item.id }.map(\.rect)
                    if occupied.contains(where: { overlaps($0, item.screen.rect) }) { item.needsPlacement = true }
                }
                if item.viewport != viewport {
                    let size = worldSize(viewport: viewport, scale: item.scale, rotation: item.screen.rotation)
                    item.screen = DesktopPhoneScreen(id: item.id, rect: CGRect(origin: item.screen.rect.origin, size: size), rotation: item.screen.rotation)
                    item.viewport = viewport
                    changed.insert(item.id)
                }
                updated.append(item)
            } else {
                let size = worldSize(viewport: viewport, scale: 0.4, rotation: 0)
                let existing = world.phoneScreens.filter { liveIDs.contains($0.id) }
                    + updated.filter { $0.connected && !priorIDs.contains($0.id) }.map(\.screen)
                let connected = DesktopPhonePlacement.connectedScreens(macSize: nextSize, screens: existing)
                let reserved = phones.map(\.screen) + updated.map(\.screen)
                let placement = defaultPlacement(id: descriptor.id, size: size, mac: nextSize,
                    active: connected, reserved: reserved)
                updated.append(PhoneScreenItem(id: descriptor.id, label: descriptor.label, viewport: viewport,
                    connected: descriptor.connected, screen: placement.screen, needsPlacement: !placement.connected))
                selectedID = descriptor.id
            }
        }
        if macSizeChanged { changed.formUnion(updated.map(\.id)) }
        if changed.isEmpty {
            if phones != updated { phones = updated }
            reconcileWorld()
        } else {
            applyResizing(updated, anchors: anchors, changed: changed)
        }
        world.setPhoneInput(reply.input)
        if reply.recoverSequence != lastRecoverSequence {
            world.returnPhonePlayerToMac(); lastRecoverSequence = reply.recoverSequence
        }
        let live = phones.filter(\.connected).count
        let nextStatus = live == 0 ? "Waiting for phones" : "\(live) phone\(live == 1 ? "" : "s") · \(activeScreenIDs.count) in world"
        if status != nextStatus { status = nextStatus }
        if pairingURL != reply.joinURL { pairingURL = reply.joinURL }
    }

    private func reconcileWorld() {
        let requested = phones.filter { $0.connected && !$0.needsPlacement }.map(\.screen)
        let active = DesktopPhonePlacement.connectedScreens(macSize: macSize, screens: requested)
        world.setPhoneScreens(active)
        let ids = Set(world.phoneScreens.map(\.id))
        if activeScreenIDs != ids { activeScreenIDs = ids }
    }

    private func worldSize(viewport: CGSize, scale: Double, rotation: Int) -> CGSize {
        let width = min(1600, max(140, macSize.height * scale))
        let height = min(1800, max(140, width * viewport.height / max(1, viewport.width)))
        return rotation == 90 ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
    }

    private func overlaps(_ a: CGRect, _ b: CGRect) -> Bool {
        let intersection = a.intersection(b)
        return !intersection.isNull && intersection.width > 0.1 && intersection.height > 0.1
    }

    private func defaultPlacement(id: String, size: CGSize, mac: CGSize,
                                  active: [DesktopPhoneScreen], reserved: [DesktopPhoneScreen]) -> (screen: DesktopPhoneScreen, connected: Bool) {
        let anchors = ([CGRect(origin: .zero, size: mac)] + active.map(\.rect)).sorted { $0.maxX > $1.maxX }
        for anchor in anchors {
            let ys = [anchor.minY, anchor.maxY - size.height, anchor.midY - size.height / 2]
            let xs = [anchor.minX, anchor.maxX - size.width, anchor.midX - size.width / 2]
            let origins = ys.map { CGPoint(x: anchor.maxX, y: $0) }
                + ys.map { CGPoint(x: anchor.minX - size.width, y: $0) }
                + xs.map { CGPoint(x: $0, y: anchor.minY - size.height) }
                + xs.map { CGPoint(x: $0, y: anchor.maxY) }
            for origin in origins {
                let candidate = DesktopPhoneScreen(id: id, rect: CGRect(origin: origin, size: size))
                guard !reserved.contains(where: { overlaps($0.rect, candidate.rect) }),
                      let snapped = DesktopPhonePlacement.snap(proposed: candidate, macSize: mac, screens: active, maxDistance: 1) else { continue }
                return (snapped, true)
            }
        }
        let x = max(mac.width, reserved.map { $0.rect.maxX }.max() ?? 0) + 100
        return (DesktopPhoneScreen(id: id, rect: CGRect(x: x, y: 0, width: size.width, height: size.height)), false)
    }

    private func attachmentAnchors() -> [String: Anchor] {
        let screens = world.phoneScreens
        var rects = Dictionary(uniqueKeysWithValues: screens.map { ($0.id, $0.rect) })
        rects["mac"] = CGRect(origin: .zero, size: macSize)
        var visited: Set<String> = ["mac"]
        var queue = ["mac"]
        var anchors: [String: Anchor] = [:]
        let seams = world.phoneSnapshot.seams
        while !queue.isEmpty {
            let parent = queue.removeFirst()
            for seam in seams {
                let child: String
                if seam.from == parent { child = seam.to }
                else if seam.to == parent { child = seam.from }
                else { continue }
                guard !visited.contains(child), let a = rects[parent], let b = rects[child] else { continue }
                let edge: DesktopPhoneEdge
                if abs(b.minX - a.maxX) < 0.1 { edge = .right }
                else if abs(b.maxX - a.minX) < 0.1 { edge = .left }
                else if abs(b.minY - a.maxY) < 0.1 { edge = .top }
                else { edge = .bottom }
                let vertical = edge == .left || edge == .right
                let offset = vertical ? b.minY - a.minY : b.minX - a.minX
                anchors[child] = Anchor(parent: parent, edge: edge, parallelOffset: offset)
                visited.insert(child); queue.append(child)
            }
        }
        return anchors
    }

    private func reflow(_ updated: [PhoneScreenItem], anchors: [String: Anchor], changed: Set<String>) -> ([PhoneScreenItem], Set<String>) {
        var candidate = updated
        var affected = changed
        for _ in 0..<8 {
            for (child, anchor) in anchors where affected.contains(anchor.parent) { affected.insert(child) }
        }
        var resolved: [String: CGRect] = ["mac": CGRect(origin: .zero, size: macSize)]
        for item in candidate where !affected.contains(item.id) { resolved[item.id] = item.screen.rect }
        for _ in 0..<8 {
            for index in candidate.indices where resolved[candidate[index].id] == nil {
                let item = candidate[index]
                guard let anchor = anchors[item.id], let parent = resolved[anchor.parent] else { continue }
                var rect = item.screen.rect
                switch anchor.edge {
                case .right: rect.origin = CGPoint(x: parent.maxX, y: parent.minY + anchor.parallelOffset)
                case .left: rect.origin = CGPoint(x: parent.minX - rect.width, y: parent.minY + anchor.parallelOffset)
                case .top: rect.origin = CGPoint(x: parent.minX + anchor.parallelOffset, y: parent.maxY)
                case .bottom: rect.origin = CGPoint(x: parent.minX + anchor.parallelOffset, y: parent.minY - rect.height)
                }
                candidate[index].screen = DesktopPhoneScreen(id: item.id, rect: rect, rotation: item.screen.rotation)
                resolved[item.id] = rect
            }
        }
        return (candidate, affected)
    }

    private func resizeIsValid(_ candidate: [PhoneScreenItem]) -> Bool {
        let requested = candidate.filter { $0.connected && !$0.needsPlacement }.map(\.screen)
        let connected = DesktopPhonePlacement.connectedScreens(macSize: macSize, screens: requested)
        let expected = activeScreenIDs.intersection(Set(requested.map(\.id)))
        if expected.isEmpty { return connected.count == requested.count }
        return expected.isSubset(of: Set(connected.map(\.id)))
    }

    private func applyResizing(_ updated: [PhoneScreenItem], anchors: [String: Anchor], changed: Set<String>) {
        let (candidate, affected) = reflow(updated, anchors: anchors, changed: changed)
        if resizeIsValid(candidate) {
            phones = candidate
            layoutMessage = nil
        } else {
            phones = updated.map { item in
                var item = item
                if affected.contains(item.id) { item.needsPlacement = true }
                return item
            }
            layoutMessage = "A resized screen needs connecting. Drag it to a free edge."
        }
        reconcileWorld()
    }
}
