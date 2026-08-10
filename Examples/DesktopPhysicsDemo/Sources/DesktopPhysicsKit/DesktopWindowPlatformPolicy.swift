import CoreGraphics
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
    let edgeX: CGFloat
    let wallSide: CGFloat
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
        surfaces: [DesktopWindowPlatformSurface]
    ) -> DesktopWindowSideCollision? {
        let horizontalDelta = currentCenterX - previousCenterX
        guard abs(horizontalDelta) > 0.001 else { return nil }

        var crossedEdges: [CGFloat] = []
        for surface in surfaces
        where overlaps(playerVerticalRange, surface.frame.minY...surface.frame.maxY) {
            var edgeXs: [CGFloat] = []
            if surface.hasVisibleLeftEdge { edgeXs.append(surface.frame.minX) }
            if surface.hasVisibleRightEdge { edgeXs.append(surface.frame.maxX) }
            for edgeX in edgeXs {
                if horizontalDelta > 0 {
                    let previousSide = previousCenterX + playerHalfWidth
                    let currentSide = currentCenterX + playerHalfWidth
                    if previousSide <= edgeX + 0.5, currentSide >= edgeX - 0.5 {
                        crossedEdges.append(edgeX)
                    }
                } else {
                    let previousSide = previousCenterX - playerHalfWidth
                    let currentSide = currentCenterX - playerHalfWidth
                    if previousSide >= edgeX - 0.5, currentSide <= edgeX + 0.5 {
                        crossedEdges.append(edgeX)
                    }
                }
            }
        }

        guard let edgeX = horizontalDelta > 0
            ? crossedEdges.min()
            : crossedEdges.max() else { return nil }
        return DesktopWindowSideCollision(
            edgeX: edgeX,
            wallSide: horizontalDelta > 0 ? 1 : -1
        )
    }

    private static func overlaps(
        _ first: ClosedRange<CGFloat>,
        _ second: ClosedRange<CGFloat>
    ) -> Bool {
        first.lowerBound < second.upperBound && first.upperBound > second.lowerBound
    }
}
