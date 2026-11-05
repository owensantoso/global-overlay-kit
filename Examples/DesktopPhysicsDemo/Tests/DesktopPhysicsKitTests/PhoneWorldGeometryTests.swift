import CoreGraphics
import Foundation
import XCTest
@testable import DesktopPhysicsKit

final class PhoneWorldGeometryTests: XCTestCase {
    private let mac = CGSize(width: 800, height: 600)

    func testPhoneChainOpensEverySharedEdgeAndKeepsExternalWalls() throws {
        let first = screen("one", 800, 0, 300, 500)
        let second = screen("two", 1_100, 0, 300, 500)
        let topology = DesktopPhoneTopology(macSize: mac, screens: [second, first])
        XCTAssertTrue(topology.inputIsValid)
        XCTAssertEqual(topology.screens.map(\.id), ["one", "two"])
        XCTAssertEqual(topology.seams.count, 2)
        for seam in topology.seams {
            let middle = CGPoint(x: (seam.x1 + seam.x2) / 2, y: (seam.y1 + seam.y2) / 2)
            XCTAssertFalse(topology.boundary.contains { contains($0, middle) })
        }
        XCTAssertTrue(topology.boundary.contains { contains($0, CGPoint(x: 1_400, y: 250)) })
        XCTAssertTrue(topology.contains(CGRect(x: 1_080, y: 100, width: 40, height: 80)))
        XCTAssertFalse(topology.contains(CGRect(x: 1_390, y: 100, width: 40, height: 80)))
    }

    func testArbitraryLeftTopBottomChainAndMiddleRemoval() {
        let phones = [
            screen("one", -300, 100, 300, 500),
            screen("two", -300, 600, 300, 400),
            screen("three", -600, 600, 300, 400),
            screen("four", -600, 100, 200, 500)
        ]
        XCTAssertTrue(DesktopPhonePlacement.isValid(macSize: mac, screens: phones))
        let topology = DesktopPhoneTopology(macSize: mac, screens: phones)
        XCTAssertEqual(topology.screens.count, 4)
        XCTAssertEqual(topology.seams.count, 4)
        XCTAssertTrue(topology.contains(CGRect(x: -500, y: 700, width: 40, height: 80)))
        XCTAssertEqual(DesktopPhonePlacement.connectedScreens(macSize: mac, screens: Array(phones.dropFirst())).count, 0)
        let partial = DesktopPhonePlacement.connectedScreens(macSize: mac, screens: [phones[0], phones[2], phones[3]])
        XCTAssertEqual(partial.map(\.id), ["one"])
    }

    func testDisconnectedInvalidDuplicateOverlappingAndOverCapacityLayoutsFailClosed() {
        let first = screen("one", 800, 0, 300, 500)
        let island = screen("island", 2_000, 0, 300, 500)
        XCTAssertEqual(DesktopPhonePlacement.connectedScreens(macSize: mac, screens: [first, island]), [first])
        XCTAssertFalse(DesktopPhonePlacement.isValid(macSize: mac, screens: [first, island]))
        for invalid in [
            [first, first],
            [first, screen("overlap", 1_000, 0, 300, 500)],
            [screen("mac-overlap", 790, 0, 300, 500)],
            [screen("mac", 800, 0, 300, 500)],
            [screen("small", 800, 0, 99, 500)],
            [screen("nonfinite", 800, .infinity, 300, 500)],
            (0..<9).map { screen("p\($0)", 800 + CGFloat($0) * 100, 0, 100, 500) }
        ] {
            XCTAssertFalse(DesktopPhonePlacement.isValid(macSize: mac, screens: invalid))
            XCTAssertTrue(DesktopPhonePlacement.connectedScreens(macSize: mac, screens: invalid).isEmpty)
        }
        XCTAssertTrue(DesktopPhonePlacement.isValid(macSize: mac, screens: []))
    }

    func testSeveralNeighboursSubtractEveryOpeningOnOneSide() {
        let phones = [screen("low", 800, 0, 300, 200), screen("high", 800, 300, 300, 300)]
        let topology = DesktopPhoneTopology(macSize: mac, screens: phones)
        XCTAssertFalse(topology.boundary.contains { contains($0, CGPoint(x: 800, y: 100)) })
        XCTAssertFalse(topology.boundary.contains { contains($0, CGPoint(x: 800, y: 450)) })
        XCTAssertTrue(topology.boundary.contains { contains($0, CGPoint(x: 800, y: 250)) })
        XCTAssertEqual(topology.seams.count, 2)
    }

    func testUnionContainmentRejectsHoleDespiteFourCoveredCorners() {
        let topology = DesktopPhoneTopology(macSize: mac, screens: [
            screen("bottom", 800, 0, 300, 100),
            screen("top", 800, 400, 300, 100),
            screen("right", 1_000, 100, 100, 300),
            screen("left", 800, 100, 100, 300)
        ])
        XCTAssertEqual(topology.screens.count, 4)
        XCTAssertFalse(topology.contains(CGRect(x: 850, y: 50, width: 200, height: 400)))
        XCTAssertTrue(topology.contains(CGRect(x: 700, y: 150, width: 200, height: 80)))
    }

    func testSnapAttachesToPhoneAndUsesBoundedScreenSpaceThreshold() throws {
        let first = screen("one", 800, 0, 300, 500)
        let proposed = screen("two", 1_110, 20, 300, 500)
        let snapped = try XCTUnwrap(DesktopPhonePlacement.snap(proposed: proposed, macSize: mac, screens: [first]))
        XCTAssertEqual(snapped.rect, CGRect(x: 1_100, y: 20, width: 300, height: 500))
        XCTAssertTrue(DesktopPhonePlacement.isValid(macSize: mac, screens: [first, snapped]))
        XCTAssertNil(DesktopPhonePlacement.snap(proposed: screen("new", 850, 0, 300, 500), macSize: mac, screens: [], maxDistance: 32))
        XCTAssertNotNil(DesktopPhonePlacement.snap(proposed: screen("new", 820, 0, 300, 500), macSize: mac, screens: [], maxDistance: 32))
        XCTAssertNil(DesktopPhonePlacement.snap(proposed: screen("new", 800, 0, 300, 500), macSize: mac, screens: [first]))
        XCTAssertNil(DesktopPhonePlacement.snap(proposed: proposed, macSize: mac, screens: [first], maxDistance: .nan))
    }

    func testSnapRepositionsExistingScreenAndIgnoresDisconnectedAnchors() throws {
        let first = screen("one", 800, 0, 300, 500)
        let island = screen("island", 2_000, 0, 300, 500)
        XCTAssertNil(DesktopPhonePlacement.snap(proposed: screen("new", 2_310, 0, 300, 500), macSize: mac, screens: [island]))
        let moved = try XCTUnwrap(DesktopPhonePlacement.snap(proposed: screen("one", 810, 20, 300, 500), macSize: mac, screens: [first]))
        XCTAssertEqual(moved.id, first.id)
        XCTAssertEqual(moved.x, 800)
        let corner = screen("corner", 810, 610, 300, 500)
        let a = DesktopPhonePlacement.snap(proposed: corner, macSize: mac, screens: [])
        let b = DesktopPhonePlacement.snap(proposed: corner, macSize: mac, screens: [])
        XCTAssertEqual(a, b)
        XCTAssertNotNil(a)
    }

    func testEveryHeightDifferingPhoneSeamGetsReachableStairs() {
        let topology = DesktopPhoneTopology(macSize: mac, screens: [
            screen("one", 800, 0, 300, 500),
            screen("two", 800, 500, 300, 500),
            screen("three", 1_100, 200, 300, 500)
        ])
        XCTAssertEqual(topology.screens.count, 3)
        for connection in topology.connections where connection.from.y != connection.to.y {
            let steps = connection.stairPlatforms(maximumRise: 72)
            var previous = min(connection.from.y, connection.to.y)
            XCTAssertFalse(steps.isEmpty)
            for step in steps {
                XCTAssertLessThanOrEqual(step.y - previous, 72.001)
                XCTAssertTrue(topology.contains(CGRect(x: step.x, y: step.y - 1, width: step.width, height: 1)))
                previous = step.y
            }
            XCTAssertEqual(previous, max(connection.from.y, connection.to.y), accuracy: 0.001)
        }
    }

    func testScreenAndSeamWireValuesRoundTrip() throws {
        let screens = [screen("one", 800, 0, 300, 500), screen("two", 1_100, 0, 300, 500)]
        XCTAssertEqual(try JSONDecoder().decode([DesktopPhoneScreen].self, from: JSONEncoder().encode(screens)), screens)
        let seams = DesktopPhonePlacement.seams(macSize: mac, screens: screens)
        XCTAssertEqual(try JSONDecoder().decode([DesktopPhoneSeamSnapshot].self, from: JSONEncoder().encode(seams)), seams)
        XCTAssertEqual(seams.first?.from, "mac")
    }

    func testPortraitLandscapeMetadataRoundTripsAndOldScreensDefaultToPortrait() throws {
        let rotated = DesktopPhoneScreen(id: "one", rect: CGRect(x: 800, y: 0, width: 500, height: 300), rotation: 90)
        XCTAssertEqual(rotated.rotation, 90)
        XCTAssertEqual(rotated.rect.size, CGSize(width: 500, height: 300), "The caller already supplies rotated dimensions")
        XCTAssertEqual(try JSONDecoder().decode(DesktopPhoneScreen.self, from: JSONEncoder().encode(rotated)), rotated)
        let legacy = Data(#"{"id":"old","x":800,"y":0,"width":300,"height":500}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(DesktopPhoneScreen.self, from: legacy).rotation, 0)
        XCTAssertTrue(DesktopPhonePlacement.isValid(macSize: mac, screens: [rotated]))
        XCTAssertEqual(DesktopPhonePlacement.connectedScreens(macSize: mac, screens: [rotated]).first?.rotation, 90)
    }

    func testSnapPreservesQuarterTurnAndOtherAnglesAreRejected() throws {
        let proposed = DesktopPhoneScreen(id: "one", rect: CGRect(x: 810, y: 0, width: 500, height: 300), rotation: 90)
        let snapped = try XCTUnwrap(DesktopPhonePlacement.snap(proposed: proposed, macSize: mac, screens: []))
        XCTAssertEqual(snapped.rotation, 90)
        XCTAssertEqual(snapped.rect, CGRect(x: 800, y: 0, width: 500, height: 300))
        for angle in [-90, 45, 180, 270, 360] {
            let invalid = DesktopPhoneScreen(id: "invalid", rect: CGRect(x: 800, y: 0, width: 300, height: 500), rotation: angle)
            XCTAssertFalse(DesktopPhonePlacement.isValid(macSize: mac, screens: [invalid]))
            XCTAssertTrue(DesktopPhonePlacement.connectedScreens(macSize: mac, screens: [invalid]).isEmpty)
            XCTAssertNil(DesktopPhonePlacement.snap(proposed: invalid, macSize: mac, screens: []))
        }
    }

    private func screen(_ id: String, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> DesktopPhoneScreen {
        .init(id: id, rect: CGRect(x: x, y: y, width: width, height: height))
    }

    private func contains(_ line: DesktopPhoneBoundarySegment, _ point: CGPoint) -> Bool {
        if line.start.x == line.end.x {
            return point.x == line.start.x && point.y >= min(line.start.y, line.end.y) && point.y <= max(line.start.y, line.end.y)
        }
        return point.y == line.start.y && point.x >= min(line.start.x, line.end.x) && point.x <= max(line.start.x, line.end.x)
    }
}
