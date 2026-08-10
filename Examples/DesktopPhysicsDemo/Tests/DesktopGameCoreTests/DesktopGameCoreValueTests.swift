import Foundation
import Testing
@testable import DesktopGameCore

@Suite("Portable 3D values")
struct DesktopGameCoreValueTests {
    @Test("Vectors reject nonfinite components")
    func vectorsRejectNonfiniteComponents() {
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopVector3(x: .infinity, y: 0, z: 0)
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopVector3(x: 0, y: .nan, z: 0)
        }
    }

    @Test("Quaternions normalize finite nonzero values")
    func quaternionsNormalize() throws {
        let quaternion = try DesktopQuaternion(x: 0, y: 0, z: 2, w: 2)

        #expect(abs(quaternion.magnitude - 1) < 0.000_000_001)
        #expect(quaternion.x == 0)
        #expect(quaternion.y == 0)
        #expect(abs(quaternion.z - (1 / sqrt(2))) < 0.000_000_001)
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopQuaternion(x: 0, y: 0, z: 0, w: 0)
        }
    }

    @Test("Quaternion hemisphere canonicalizes equivalent rotations")
    func quaternionHemisphereIsCanonical() throws {
        let positive = try DesktopQuaternion(x: 1, y: 2, z: 3, w: 4)
        let negative = try DesktopQuaternion(x: -1, y: -2, z: -3, w: -4)
        let zeroWPositiveX = try DesktopQuaternion(x: 1, y: 0, z: 0, w: 0)
        let zeroWNegativeX = try DesktopQuaternion(x: -1, y: 0, z: 0, w: 0)
        let zeroWXZeroPositiveY = try DesktopQuaternion(x: 0, y: 1, z: 0, w: 0)
        let zeroWXZeroNegativeY = try DesktopQuaternion(x: 0, y: -1, z: 0, w: 0)

        #expect(positive == negative)
        #expect(positive.hashValue == negative.hashValue)
        #expect(Set([positive, negative]).count == 1)
        #expect(zeroWPositiveX == zeroWNegativeX)
        #expect(zeroWXZeroPositiveY == zeroWXZeroNegativeY)
        #expect(zeroWNegativeX.x == 1)
        #expect(zeroWXZeroNegativeY.y == 1)
    }

    @Test("Decoded quaternions and identifiers preserve validation")
    func decodedValuesPreserveValidation() {
        let zeroQuaternion = Data(#"{"x":0,"y":0,"z":0,"w":0}"#.utf8)
        let emptyIdentifier = Data("\"\"".utf8)

        #expect(throws: DesktopGameValidationError.self) {
            try JSONDecoder().decode(DesktopQuaternion.self, from: zeroQuaternion)
        }
        #expect(throws: DesktopGameValidationError.self) {
            try JSONDecoder().decode(DesktopEntityID.self, from: emptyIdentifier)
        }
    }

    @Test("Depth and viewport values enforce the right-handed contract")
    func viewportContract() throws {
        let viewport = try DesktopViewport(
            id: DesktopViewportID(validating: "primary"),
            width: 1_800,
            height: 1_169,
            depthRange: try DesktopDepthRange(minZ: -30, maxZ: 4)
        )

        #expect(viewport.coordinateSystem == .rightHandedXRightYUpZTowardViewer)
        #expect(viewport.origin == .screenPlaneBottomLeft)
        #expect(viewport.units == .worldUnits)
        #expect(viewport.desktopPlaneZ == 0)
        #expect(
            try viewport.worldPosition(
                fromScreenPlaneTopLeft: DesktopVector3(x: 20, y: 40, z: -2)
            ) == DesktopVector3(x: 20, y: 1_129, z: -2)
        )
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopDepthRange(minZ: 1, maxZ: -1)
        }
    }

    @Test("Viewport coordinate semantics are explicit on the wire")
    func viewportCoordinateSemanticsEncodeAndRejectDrift() throws {
        let viewport = try DesktopViewport(
            id: DesktopViewportID(validating: "primary"),
            width: 1_800,
            height: 1_169,
            depthRange: try DesktopDepthRange(minZ: -30, maxZ: 4)
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = String(decoding: try encoder.encode(viewport), as: UTF8.self)

        #expect(encoded.contains(#""origin":"screen_plane_bottom_left""#))
        #expect(encoded.contains(#""units":"world_units""#))

        let invalidOrigin = encoded.replacingOccurrences(
            of: "screen_plane_bottom_left",
            with: "screen_plane_top_left"
        )
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(DesktopViewport.self, from: Data(invalidOrigin.utf8))
        }
    }

    @Test("Top-left observation coordinates project to the bottom-left fixture")
    func coordinateConversionFixture() throws {
        let url = try #require(
            Bundle.module.url(
                forResource: "coordinate_conversion_v1",
                withExtension: "json"
            )
        )
        let fixture = try JSONDecoder().decode(
            CoordinateConversionFixture.self,
            from: Data(contentsOf: url)
        )
        let viewport = try DesktopViewport(
            id: DesktopViewportID(validating: "primary"),
            width: 1_800,
            height: fixture.viewportHeight,
            depthRange: try DesktopDepthRange(minZ: -30, maxZ: 4)
        )

        #expect(
            try viewport.worldPosition(
                fromScreenPlaneTopLeft: fixture.sourceScreenPlaneTopLeft
            ) == fixture.expectedWorld
        )
    }

    @Test("Identifiers reject empty values")
    func identifiersRejectEmptyValues() {
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopEntityID(validating: "  ")
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopWorldSessionID(validating: "")
        }
        #expect(DesktopEntityID(rawValue: "  ") == nil)
    }
}

private struct CoordinateConversionFixture: Decodable {
    let viewportHeight: Double
    let sourceScreenPlaneTopLeft: DesktopVector3
    let expectedWorld: DesktopVector3

    enum CodingKeys: String, CodingKey {
        case viewportHeight = "viewport_height"
        case sourceScreenPlaneTopLeft = "source_screen_plane_top_left"
        case expectedWorld = "expected_world"
    }
}
