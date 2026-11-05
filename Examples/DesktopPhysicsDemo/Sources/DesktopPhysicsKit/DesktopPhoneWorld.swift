import CoreGraphics
import Foundation

public enum DesktopPhoneEdge: String, Codable, CaseIterable, Sendable {
    case right, left, bottom, top
}

/// Phone dimensions use the same logical points as the Mac world, independent of pixel density.
public struct DesktopPhoneLayout: Codable, Equatable, Sendable {
    public let edge: DesktopPhoneEdge
    public let alignment: Double
    public let width: CGFloat
    public let height: CGFloat

    public init(
        edge: DesktopPhoneEdge = .right,
        alignment: Double = 0,
        width: CGFloat = 390,
        height: CGFloat = 700
    ) {
        self.edge = edge
        self.alignment = alignment.isFinite ? min(max(alignment, 0), 1) : 0
        self.width = width.isFinite ? min(max(width, 100), 2_000) : 390
        self.height = height.isFinite ? min(max(height, 100), 2_000) : 700
    }

    public func rect(adjacentTo macSize: CGSize) -> CGRect {
        let offset = CGFloat(alignment)
        switch edge {
        case .right:
            return CGRect(x: macSize.width, y: (macSize.height - height) * offset, width: width, height: height)
        case .left:
            return CGRect(x: -width, y: (macSize.height - height) * offset, width: width, height: height)
        case .bottom:
            return CGRect(x: (macSize.width - width) * offset, y: -height, width: width, height: height)
        case .top:
            return CGRect(x: (macSize.width - width) * offset, y: macSize.height, width: width, height: height)
        }
    }

    private enum CodingKeys: String, CodingKey { case edge, alignment, width, height }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            edge: try values.decode(DesktopPhoneEdge.self, forKey: .edge),
            alignment: try values.decode(Double.self, forKey: .alignment),
            width: try values.decode(CGFloat.self, forKey: .width),
            height: try values.decode(CGFloat.self, forKey: .height)
        )
    }
}

public struct DesktopPhoneScreen: Codable, Equatable, Sendable {
    public let id: String
    public let x: CGFloat
    public let y: CGFloat
    public let width: CGFloat
    public let height: CGFloat

    public let rotation: Int

    public init(id: String, rect: CGRect, rotation: Int = 0) {
        self.id = id
        self.rotation = rotation
        x = rect.origin.x
        y = rect.origin.y
        width = rect.size.width
        height = rect.size.height
    }

    public var rect: CGRect { CGRect(x: x, y: y, width: width, height: height) }

    private enum CodingKeys: String, CodingKey { case id, x, y, width, height, rotation }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try values.decode(String.self, forKey: .id),
            rect: CGRect(
                x: try values.decode(CGFloat.self, forKey: .x),
                y: try values.decode(CGFloat.self, forKey: .y),
                width: try values.decode(CGFloat.self, forKey: .width),
                height: try values.decode(CGFloat.self, forKey: .height)
            ),
            rotation: try values.decodeIfPresent(Int.self, forKey: .rotation) ?? 0
        )
    }
}

public struct DesktopPhoneSeamSnapshot: Codable, Equatable, Sendable {
    public let from: String
    public let to: String
    public let x1: CGFloat
    public let y1: CGFloat
    public let x2: CGFloat
    public let y2: CGFloat
}

/// Drag previews use the same validation and snap geometry as the native authority.
public enum DesktopPhonePlacement {
    public static func connectedScreens(macSize: CGSize, screens: [DesktopPhoneScreen]) -> [DesktopPhoneScreen] {
        DesktopPhoneTopology(macSize: macSize, screens: screens).screens
    }

    public static func seams(macSize: CGSize, screens: [DesktopPhoneScreen]) -> [DesktopPhoneSeamSnapshot] {
        DesktopPhoneTopology(macSize: macSize, screens: screens).seams
    }

    public static func isValid(macSize: CGSize, screens: [DesktopPhoneScreen]) -> Bool {
        let topology = DesktopPhoneTopology(macSize: macSize, screens: screens)
        return topology.inputIsValid && topology.screens.count == screens.count
    }

    public static func snap(
        proposed: DesktopPhoneScreen,
        macSize: CGSize,
        screens: [DesktopPhoneScreen],
        maxDistance: CGFloat = 120
    ) -> DesktopPhoneScreen? {
        guard maxDistance.isFinite, maxDistance >= 0, DesktopPhoneTopology.validPhone(proposed),
              screens.filter({ $0.id == proposed.id }).count <= 1 else { return nil }
        let others = screens.filter { $0.id != proposed.id }
        guard others.count < 8 else { return nil }
        let topology = DesktopPhoneTopology(macSize: macSize, screens: others)
        guard topology.inputIsValid else { return nil }
        let anchors = [topology.mac] + topology.screens
        var candidates: [(distance: CGFloat, key: String, screen: DesktopPhoneScreen)] = []
        for anchor in anchors {
            let rect = anchor.rect
            func clamp(_ value: CGFloat, _ lower: CGFloat, _ upper: CGFloat) -> CGFloat {
                min(max(value, lower), upper)
            }
            let parallelY = clamp(proposed.y, rect.minY + 100 - proposed.height, rect.maxY - 100)
            let parallelX = clamp(proposed.x, rect.minX + 100 - proposed.width, rect.maxX - 100)
            let origins = [
                CGPoint(x: rect.maxX, y: parallelY),
                CGPoint(x: rect.minX - proposed.width, y: parallelY),
                CGPoint(x: parallelX, y: rect.minY - proposed.height),
                CGPoint(x: parallelX, y: rect.maxY)
            ]
            for (index, origin) in origins.enumerated() {
                let candidate = DesktopPhoneScreen(id: proposed.id, rect: CGRect(origin: origin, size: proposed.rect.size), rotation: proposed.rotation)
                let distance = hypot(origin.x - proposed.x, origin.y - proposed.y)
                guard distance <= min(120, maxDistance),
                      !([topology.mac] + others).contains(where: { DesktopPhoneTopology.overlaps($0.rect, candidate.rect) }),
                      isValid(macSize: macSize, screens: topology.screens + [candidate]) else { continue }
                candidates.append((distance, anchor.id + ":" + String(index), candidate))
            }
        }
        return candidates.sorted {
            if $0.distance != $1.distance { return $0.distance < $1.distance }
            return $0.key < $1.key
        }.first?.screen
    }
}

public struct DesktopPhoneInput: Codable, Equatable, Sendable {
    public let left: Bool
    public let right: Bool
    public let jump: Bool
    public let run: Bool

    public init(left: Bool = false, right: Bool = false, jump: Bool = false, run: Bool = false) {
        self.left = left
        self.right = right
        self.jump = jump
        self.run = run
    }

    public static let released = DesktopPhoneInput()
}

public struct DesktopPhonePlayerSnapshot: Codable, Equatable, Sendable {
    public let id: String
    public let x: CGFloat
    public let y: CGFloat
    public let vx: CGFloat
    public let vy: CGFloat
    public let width: CGFloat
    public let height: CGFloat
    public let spriteWidth: CGFloat
    public let spriteHeight: CGFloat
    public let spriteOffsetY: CGFloat
    public let facing: String
    public let animation: String
    public let asset: String?
}

public struct DesktopPhonePlatformSnapshot: Codable, Equatable, Sendable {
    public let x: CGFloat
    public let y: CGFloat
    public let width: CGFloat
}

public struct DesktopPhoneSnapshot: Codable, Equatable, Sendable {
    public let width: CGFloat
    public let height: CGFloat
    public let player: DesktopPhonePlayerSnapshot?
    public let platforms: [DesktopPhonePlatformSnapshot]
    public let screens: [DesktopPhoneScreen]
    public let seams: [DesktopPhoneSeamSnapshot]
}

struct DesktopPhoneBoundarySegment: Equatable, Sendable {
    let start: CGPoint
    let end: CGPoint
}

struct DesktopPhoneConnection {
    let from: DesktopPhoneScreen
    let to: DesktopPhoneScreen
    let edge: DesktopPhoneEdge
    let segment: DesktopPhoneBoundarySegment

    init?(_ from: DesktopPhoneScreen, _ to: DesktopPhoneScreen) {
        let a = from.rect
        let b = to.rect
        if b.minX == a.maxX || b.maxX == a.minX {
            let lower = max(a.minY, b.minY)
            let upper = min(a.maxY, b.maxY)
            guard upper - lower >= 100 else { return nil }
            edge = b.minX == a.maxX ? .right : .left
            let x = edge == .right ? a.maxX : a.minX
            segment = .init(start: CGPoint(x: x, y: lower), end: CGPoint(x: x, y: upper))
        } else if b.maxY == a.minY || b.minY == a.maxY {
            let lower = max(a.minX, b.minX)
            let upper = min(a.maxX, b.maxX)
            guard upper - lower >= 100 else { return nil }
            edge = b.maxY == a.minY ? .bottom : .top
            let y = edge == .bottom ? a.minY : a.maxY
            segment = .init(start: CGPoint(x: lower, y: y), end: CGPoint(x: upper, y: y))
        } else {
            return nil
        }
        self.from = from
        self.to = to
    }

    var snapshot: DesktopPhoneSeamSnapshot {
        .init(from: from.id, to: to.id, x1: segment.start.x, y1: segment.start.y, x2: segment.end.x, y2: segment.end.y)
    }

    func stairPlatforms(maximumRise: CGFloat) -> [DesktopPhonePlatformSnapshot] {
        let a = from.rect
        let b = to.rect
        let lowerY = min(a.minY, b.minY)
        let upperY = max(a.minY, b.minY)
        guard upperY - lowerY > 1 else { return [] }
        let lowerRegion = b.minY < a.minY ? b : a
        let count = Int(ceil((upperY - lowerY) / max(16, maximumRise)))
        let rise = (upperY - lowerY) / CGFloat(count)
        let corridor: ClosedRange<CGFloat>
        switch edge {
        case .bottom, .top:
            corridor = segment.start.x...segment.end.x
        case .right:
            corridor = lowerRegion == a
                ? max(a.minX, a.maxX - 240)...a.maxX
                : b.minX...min(b.maxX, b.minX + 240)
        case .left:
            corridor = lowerRegion == a
                ? a.minX...min(a.maxX, a.minX + 240)
                : max(b.minX, b.maxX - 240)...b.maxX
        }
        let width = min(110, max(40, (corridor.upperBound - corridor.lowerBound) * 0.35))
        let x: CGFloat
        switch edge {
        case .right:
            x = lowerRegion == a ? corridor.upperBound - width : corridor.lowerBound
        case .left:
            x = lowerRegion == a ? corridor.lowerBound : corridor.upperBound - width
        case .bottom, .top:
            x = corridor.lowerBound
        }
        return (1...count).map { index in
            DesktopPhonePlatformSnapshot(x: x, y: lowerY + rise * CGFloat(index), width: width)
        }
    }
}

/// Invalid input fails closed. Only the edge-connected component rooted at the Mac is simulated.
struct DesktopPhoneTopology {
    let mac: DesktopPhoneScreen
    let screens: [DesktopPhoneScreen]
    let connections: [DesktopPhoneConnection]
    let inputIsValid: Bool

    init(macSize: CGSize, screens requested: [DesktopPhoneScreen]) {
        let mac = DesktopPhoneScreen(id: "mac", rect: CGRect(origin: .zero, size: macSize))
        self.mac = mac
        guard macSize.width.isFinite, macSize.height.isFinite, macSize.width > 0, macSize.height > 0,
              requested.count <= 8,
              Set(requested.map(\.id)).count == requested.count,
              requested.allSatisfy(Self.validPhone),
              !requested.contains(where: { Self.overlaps($0.rect, mac.rect) }) else {
            screens = []; connections = []; inputIsValid = false; return
        }
        let phones = requested.sorted { $0.id < $1.id }
        for i in phones.indices {
            if phones.indices.contains(where: { $0 > i && Self.overlaps(phones[i].rect, phones[$0].rect) }) {
                screens = []; connections = []; inputIsValid = false; return
            }
        }
        let nodes = [mac] + phones
        var allConnections: [DesktopPhoneConnection] = []
        for i in nodes.indices {
            for j in nodes.indices where j > i {
                if let connection = DesktopPhoneConnection(nodes[i], nodes[j]) { allConnections.append(connection) }
            }
        }
        var connected: Set<String> = ["mac"]
        var changed = true
        while changed {
            changed = false
            for connection in allConnections {
                if connected.contains(connection.from.id) || connected.contains(connection.to.id) {
                    if connected.insert(connection.from.id).inserted { changed = true }
                    if connected.insert(connection.to.id).inserted { changed = true }
                }
            }
        }
        screens = phones.filter { connected.contains($0.id) }
        connections = allConnections.filter { connected.contains($0.from.id) && connected.contains($0.to.id) }
        inputIsValid = true
    }

    static func validPhone(_ screen: DesktopPhoneScreen) -> Bool {
        !screen.id.isEmpty && screen.id != "mac" && screen.id.count <= 128
            && (screen.rotation == 0 || screen.rotation == 90)
            && screen.x.isFinite && screen.y.isFinite
            && screen.width.isFinite && screen.height.isFinite
            && (100...2_000).contains(screen.width) && (100...2_000).contains(screen.height)
            && screen.rect.maxX.isFinite && screen.rect.maxY.isFinite
    }

    static func overlaps(_ a: CGRect, _ b: CGRect) -> Bool {
        let intersection = a.intersection(b)
        return !intersection.isNull && intersection.width > 0 && intersection.height > 0
    }

    var seams: [DesktopPhoneSeamSnapshot] { connections.map(\.snapshot) }

    var boundary: [DesktopPhoneBoundarySegment] {
        var result: [DesktopPhoneBoundarySegment] = []
        for screen in [mac] + screens {
            let rect = screen.rect
            let sides: [DesktopPhoneBoundarySegment] = [
                .init(start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.minY)),
                .init(start: CGPoint(x: rect.maxX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.maxY)),
                .init(start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.maxX, y: rect.maxY)),
                .init(start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.minX, y: rect.maxY))
            ]
            for (index, side) in sides.enumerated() {
                if screen.id == "mac", index == 2 { continue }
                var pieces = [side]
                for connection in connections where connection.from.id == screen.id || connection.to.id == screen.id {
                    pieces = pieces.flatMap { Self.subtract(connection.segment, from: $0) }
                }
                result.append(contentsOf: pieces)
            }
        }
        return result
    }

    func stairPlatforms(maximumRise: CGFloat) -> [DesktopPhonePlatformSnapshot] {
        var platforms: [DesktopPhonePlatformSnapshot] = []
        for connection in connections {
            for platform in connection.stairPlatforms(maximumRise: maximumRise) where !platforms.contains(platform) {
                platforms.append(platform)
            }
        }
        return platforms
    }

    /// Rectangle subtraction detects holes that a four-corner containment test would miss.
    func contains(_ bounds: CGRect) -> Bool {
        guard !bounds.isNull, bounds.width > 0, bounds.height > 0 else { return false }
        var remainder = [bounds]
        for screen in [mac] + screens {
            remainder = remainder.flatMap { part -> [CGRect] in
                let intersection = part.intersection(screen.rect)
                guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else { return [part] }
                var pieces: [CGRect] = []
                if part.minX < intersection.minX {
                    pieces.append(CGRect(x: part.minX, y: part.minY, width: intersection.minX - part.minX, height: part.height))
                }
                if intersection.maxX < part.maxX {
                    pieces.append(CGRect(x: intersection.maxX, y: part.minY, width: part.maxX - intersection.maxX, height: part.height))
                }
                if part.minY < intersection.minY {
                    pieces.append(CGRect(x: intersection.minX, y: part.minY, width: intersection.width, height: intersection.minY - part.minY))
                }
                if intersection.maxY < part.maxY {
                    pieces.append(CGRect(x: intersection.minX, y: intersection.maxY, width: intersection.width, height: part.maxY - intersection.maxY))
                }
                return pieces
            }
            if remainder.isEmpty { return true }
        }
        return false
    }

    private static func subtract(_ seam: DesktopPhoneBoundarySegment, from side: DesktopPhoneBoundarySegment) -> [DesktopPhoneBoundarySegment] {
        let vertical = side.start.x == side.end.x
        guard vertical == (seam.start.x == seam.end.x),
              (vertical ? side.start.x == seam.start.x : side.start.y == seam.start.y) else { return [side] }
        let lower = vertical ? side.start.y : side.start.x
        let upper = vertical ? side.end.y : side.end.x
        let cutLower = max(lower, vertical ? seam.start.y : seam.start.x)
        let cutUpper = min(upper, vertical ? seam.end.y : seam.end.x)
        guard cutLower < cutUpper else { return [side] }
        func point(_ value: CGFloat) -> CGPoint {
            vertical ? CGPoint(x: side.start.x, y: value) : CGPoint(x: value, y: side.start.y)
        }
        var pieces: [DesktopPhoneBoundarySegment] = []
        if lower < cutLower { pieces.append(.init(start: point(lower), end: point(cutLower))) }
        if cutUpper < upper { pieces.append(.init(start: point(cutUpper), end: point(upper))) }
        return pieces
    }
}

/// Compatibility geometry for the original single-phone API.
struct DesktopPhoneGeometry {
    let mac: CGRect
    let phone: CGRect
    let edge: DesktopPhoneEdge
    let seam: DesktopPhoneBoundarySegment
    private let topology: DesktopPhoneTopology

    init?(macSize: CGSize, phone: CGRect) {
        let topology = DesktopPhoneTopology(macSize: macSize, screens: [.init(id: "phone", rect: phone)])
        guard let connection = topology.connections.first else { return nil }
        self.topology = topology
        mac = topology.mac.rect
        self.phone = phone
        edge = connection.edge
        seam = connection.segment
    }

    var boundary: [DesktopPhoneBoundarySegment] { topology.boundary }
    func stairPlatforms(maximumRise: CGFloat = 100) -> [DesktopPhonePlatformSnapshot] {
        topology.stairPlatforms(maximumRise: maximumRise)
    }
}
