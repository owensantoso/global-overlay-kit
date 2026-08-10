import CoreGraphics
import DesktopGameCore
import Foundation

struct DesktopWindowPlatformSurface: Equatable, Sendable {
    let id: String
    let frame: CGRect
    let hasVisibleTopEdge: Bool
    let hasVisibleBottomEdge: Bool
    let hasVisibleLeftEdge: Bool
    let hasVisibleRightEdge: Bool

    init(
        id: String,
        frame: CGRect,
        hasVisibleTopEdge: Bool = true,
        hasVisibleBottomEdge: Bool = true,
        hasVisibleLeftEdge: Bool = true,
        hasVisibleRightEdge: Bool = true
    ) {
        self.id = id
        self.frame = frame
        self.hasVisibleTopEdge = hasVisibleTopEdge
        self.hasVisibleBottomEdge = hasVisibleBottomEdge
        self.hasVisibleLeftEdge = hasVisibleLeftEdge
        self.hasVisibleRightEdge = hasVisibleRightEdge
    }
}

struct DesktopWindowPlatformLanding: Equatable, Sendable {
    let id: String
    let edge: DesktopWindowPlatformEdge
    let surfaceY: CGFloat
}

enum DesktopWindowPlatformEdge: Equatable, Sendable {
    case top
    case bottom

    func surfaceY(in frame: CGRect) -> CGFloat {
        switch self {
        case .top: frame.maxY
        case .bottom: frame.minY
        }
    }
}

struct DesktopWindowSideCollision: Equatable, Sendable {
    let featureID: String
    let edgeX: CGFloat
    let wallSide: CGFloat

    var wallContact: DesktopWallContact? {
        guard let id = DesktopSurfaceID(rawValue: featureID),
              let direction = DesktopHorizontalDirection(rawValue: Int(wallSide)) else {
            return nil
        }
        return try? DesktopWallContact(
            featureID: id,
            directionFromPlayer: direction,
            planeX: Double(edgeX)
        )
    }
}

private struct DesktopWindowSideFeature {
    let featureID: String
    let edgeX: CGFloat
}

enum DesktopWindowPlatformPolicy {
    static let landingTolerance: CGFloat = 6

    static func shouldClearIgnoredSurface(
        previousFootY: CGFloat,
        ignoredSurfaceY: CGFloat
    ) -> Bool {
        previousFootY < ignoredSurfaceY - landingTolerance
    }

    static func landing(
        previousFootY: CGFloat,
        currentFootY: CGFloat,
        verticalVelocity: CGFloat,
        playerHorizontalRange: ClosedRange<CGFloat>,
        surfaces: [DesktopWindowPlatformSurface],
        ignoredSurfaceY: CGFloat? = nil
    ) -> DesktopWindowPlatformLanding? {
        guard verticalVelocity <= 0 else { return nil }

        return surfaces.flatMap { surface -> [DesktopWindowPlatformLanding] in
            guard overlaps(
                playerHorizontalRange,
                surface.frame.minX...surface.frame.maxX
            ) else { return [] }

            var landings: [DesktopWindowPlatformLanding] = []
            var edges: [DesktopWindowPlatformEdge] = []
            if surface.hasVisibleTopEdge { edges.append(.top) }
            if surface.hasVisibleBottomEdge { edges.append(.bottom) }
            for edge in edges {
                let surfaceY = edge.surfaceY(in: surface.frame)
                if let ignoredSurfaceY,
                   abs(surfaceY - ignoredSurfaceY) <= landingTolerance {
                    continue
                }
                if previousFootY >= surfaceY - landingTolerance,
                   currentFootY <= surfaceY + landingTolerance {
                    landings.append(DesktopWindowPlatformLanding(
                        id: surface.id,
                        edge: edge,
                        surfaceY: surfaceY
                    ))
                }
            }
            return landings
        }
        .max { $0.surfaceY < $1.surfaceY }
    }

    static func supportedPlayerCenterY(
        previousPlatformY: CGFloat,
        edge: DesktopWindowPlatformEdge,
        currentPlatformFrame: CGRect,
        previousFootY: CGFloat,
        verticalVelocity: CGFloat,
        playerHorizontalRange: ClosedRange<CGFloat>,
        playerHalfHeight: CGFloat,
        sceneHeight: CGFloat,
        maximumPlatformStep: CGFloat
    ) -> CGFloat? {
        let currentSurfaceY = edge.surfaceY(in: currentPlatformFrame)
        guard verticalVelocity <= 0,
              abs(previousFootY - previousPlatformY) <= landingTolerance,
              abs(currentSurfaceY - previousPlatformY) <= maximumPlatformStep,
              overlaps(
                playerHorizontalRange,
                currentPlatformFrame.minX...currentPlatformFrame.maxX
              ) else {
            return nil
        }

        let centerY = currentSurfaceY + playerHalfHeight
        guard centerY >= playerHalfHeight,
              centerY <= sceneHeight - playerHalfHeight else {
            return nil
        }
        return centerY
    }

    static func sideCollision(
        previousCenterX: CGFloat,
        currentCenterX: CGFloat,
        playerHalfWidth: CGFloat,
        playerVerticalRange: ClosedRange<CGFloat>,
        surfaces: [DesktopWindowPlatformSurface],
        excluding traversal: DesktopWallTraversalState? = nil
    ) -> DesktopWindowSideCollision? {
        let horizontalDelta = currentCenterX - previousCenterX
        guard abs(horizontalDelta) > 0.001 else { return nil }

        var collisions: [DesktopWindowSideCollision] = []
        for surface in surfaces
        where overlaps(playerVerticalRange, surface.frame.minY...surface.frame.maxY) {
            var features: [DesktopWindowSideFeature] = []
            if surface.hasVisibleLeftEdge {
                features.append(DesktopWindowSideFeature(
                    featureID: "window:\(surface.id):left",
                    edgeX: surface.frame.minX
                ))
            }
            if surface.hasVisibleRightEdge {
                features.append(DesktopWindowSideFeature(
                    featureID: "window:\(surface.id):right",
                    edgeX: surface.frame.maxX
                ))
            }
            for feature in features {
                let edgeX = feature.edgeX
                let collision = DesktopWindowSideCollision(
                    featureID: feature.featureID,
                    edgeX: edgeX,
                    wallSide: horizontalDelta > 0 ? 1 : -1
                )
                if let traversal,
                   let contact = collision.wallContact,
                   traversal.excludes(contact) {
                    continue
                }
                if horizontalDelta > 0 {
                    let previousSide = previousCenterX + playerHalfWidth
                    let currentSide = currentCenterX + playerHalfWidth
                    if previousSide <= edgeX + 0.5, currentSide >= edgeX - 0.5 {
                        collisions.append(collision)
                    }
                } else {
                    let previousSide = previousCenterX - playerHalfWidth
                    let currentSide = currentCenterX - playerHalfWidth
                    if previousSide >= edgeX - 0.5, currentSide <= edgeX + 0.5 {
                        collisions.append(collision)
                    }
                }
            }
        }

        return collisions.sorted { lhs, rhs in
            if lhs.edgeX != rhs.edgeX {
                return horizontalDelta > 0
                    ? lhs.edgeX < rhs.edgeX
                    : lhs.edgeX > rhs.edgeX
            }
            return lhs.featureID < rhs.featureID
        }.first
    }

    private static func overlaps(
        _ first: ClosedRange<CGFloat>,
        _ second: ClosedRange<CGFloat>
    ) -> Bool {
        first.lowerBound < second.upperBound && first.upperBound > second.lowerBound
    }
}
