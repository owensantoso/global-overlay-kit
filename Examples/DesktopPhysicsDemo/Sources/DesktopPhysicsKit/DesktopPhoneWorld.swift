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
}

struct DesktopPhoneBoundarySegment: Equatable, Sendable {
    let start: CGPoint
    let end: CGPoint
}

/// Only the shared span is open. The rest of both regions retains its boundary.
struct DesktopPhoneGeometry {
    let mac: CGRect
    let phone: CGRect
    let edge: DesktopPhoneEdge
    let seam: DesktopPhoneBoundarySegment

    init?(macSize: CGSize, phone: CGRect) {
        let mac = CGRect(origin: .zero, size: macSize)
        guard mac.width.isFinite, mac.height.isFinite, mac.width > 0, mac.height > 0,
              phone.origin.x.isFinite, phone.origin.y.isFinite,
              phone.width.isFinite, phone.height.isFinite,
              (100...2_000).contains(phone.width), (100...2_000).contains(phone.height) else { return nil }
        let edge: DesktopPhoneEdge
        let seam: DesktopPhoneBoundarySegment
        if phone.minX == mac.maxX || phone.maxX == mac.minX {
            edge = phone.minX == mac.maxX ? .right : .left
            let lower = max(mac.minY, phone.minY)
            let upper = min(mac.maxY, phone.maxY)
            guard upper - lower >= 100 else { return nil }
            let x = edge == .right ? mac.maxX : mac.minX
            seam = .init(start: CGPoint(x: x, y: lower), end: CGPoint(x: x, y: upper))
        } else if phone.maxY == mac.minY || phone.minY == mac.maxY {
            edge = phone.maxY == mac.minY ? .bottom : .top
            let lower = max(mac.minX, phone.minX)
            let upper = min(mac.maxX, phone.maxX)
            guard upper - lower >= 100 else { return nil }
            let y = edge == .bottom ? mac.minY : mac.maxY
            seam = .init(start: CGPoint(x: lower, y: y), end: CGPoint(x: upper, y: y))
        } else {
            return nil
        }
        self.mac = mac
        self.phone = phone
        self.edge = edge
        self.seam = seam
    }

    var boundary: [DesktopPhoneBoundarySegment] {
        var result: [DesktopPhoneBoundarySegment] = []
        for (rect, isMac) in [(mac, true), (phone, false)] {
            let sides: [DesktopPhoneBoundarySegment] = [
                .init(start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.minY)),
                .init(start: CGPoint(x: rect.maxX, y: rect.minY), end: CGPoint(x: rect.maxX, y: rect.maxY)),
                .init(start: CGPoint(x: rect.minX, y: rect.maxY), end: CGPoint(x: rect.maxX, y: rect.maxY)),
                .init(start: CGPoint(x: rect.minX, y: rect.minY), end: CGPoint(x: rect.minX, y: rect.maxY))
            ]
            for (index, side) in sides.enumerated() {
                // The Mac player has always been free to jump above the screen.
                if isMac, index == 2 { continue }
                result.append(contentsOf: subtractSeam(from: side))
            }
        }
        return result
    }

    func stairPlatforms(maximumRise: CGFloat = 100) -> [DesktopPhonePlatformSnapshot] {
        let lowerY = min(mac.minY, phone.minY)
        let upperY = max(mac.minY, phone.minY)
        guard upperY - lowerY > 1 else { return [] }
        let lowerRegion = phone.minY < mac.minY ? phone : mac
        let count = Int(ceil((upperY - lowerY) / max(16, maximumRise)))
        let rise = (upperY - lowerY) / CGFloat(count)
        let corridor: ClosedRange<CGFloat>
        switch edge {
        case .bottom, .top:
            corridor = seam.start.x...seam.end.x
        case .right:
            corridor = lowerRegion == mac
                ? max(mac.minX, mac.maxX - 240)...mac.maxX
                : phone.minX...min(phone.maxX, phone.minX + 240)
        case .left:
            corridor = lowerRegion == mac
                ? mac.minX...min(mac.maxX, mac.minX + 240)
                : max(phone.minX, phone.maxX - 240)...phone.maxX
        }
        let width = min(110, max(40, (corridor.upperBound - corridor.lowerBound) * 0.35))
        let x: CGFloat
        switch edge {
        case .right:
            x = lowerRegion == mac ? corridor.upperBound - width : corridor.lowerBound
        case .left:
            x = lowerRegion == mac ? corridor.lowerBound : corridor.upperBound - width
        case .bottom, .top:
            x = corridor.lowerBound
        }
        return (1...count).map { index in
            DesktopPhonePlatformSnapshot(x: x, y: lowerY + rise * CGFloat(index), width: width)
        }
    }

    private func subtractSeam(from side: DesktopPhoneBoundarySegment) -> [DesktopPhoneBoundarySegment] {
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
