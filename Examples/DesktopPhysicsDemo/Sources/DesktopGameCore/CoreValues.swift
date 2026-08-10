import Foundation

public enum DesktopGameValidationError: Error, Equatable, Sendable {
    case nonfinite(field: String)
    case invalidIdentifier(field: String)
    case nonNormalizableQuaternion
    case invalidRange(field: String)
    case invalidValue(field: String)
    case duplicateIdentifier(String)
    case invalidEnvelope(String)
}

func validateIdentifier(_ rawValue: String, field: String) throws {
    guard rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
        throw DesktopGameValidationError.invalidIdentifier(field: field)
    }
}

/// A hosted world's lifetime. A new hosted world creates a new value.
public struct DesktopWorldSessionID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(validating rawValue: String) throws {
        try validateIdentifier(rawValue, field: "world_session_id")
        self.rawValue = rawValue
    }

    public init?(rawValue: String) {
        guard let value = try? Self(validating: rawValue) else { return nil }
        self = value
    }

    public init(from decoder: Decoder) throws {
        try self.init(validating: decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct DesktopViewportID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    public let rawValue: String
    public init(validating rawValue: String) throws { try validateIdentifier(rawValue, field: "viewport_id"); self.rawValue = rawValue }
    public init?(rawValue: String) { guard let value = try? Self(validating: rawValue) else { return nil }; self = value }
    public init(from decoder: Decoder) throws { try self.init(validating: decoder.singleValueContainer().decode(String.self)) }
    public func encode(to encoder: Encoder) throws { var container = encoder.singleValueContainer(); try container.encode(rawValue) }
}

/// Authority-minted identity that must never be reused within one world session.
public struct DesktopEntityID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    public let rawValue: String

    public init(validating rawValue: String) throws {
        try validateIdentifier(rawValue, field: "entity_id")
        self.rawValue = rawValue
    }

    public init?(rawValue: String) {
        guard let value = try? Self(validating: rawValue) else { return nil }
        self = value
    }

    public init(from decoder: Decoder) throws {
        try self.init(validating: decoder.singleValueContainer().decode(String.self))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public struct DesktopSurfaceID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    public let rawValue: String
    public init(validating rawValue: String) throws { try validateIdentifier(rawValue, field: "surface_id"); self.rawValue = rawValue }
    public init?(rawValue: String) { guard let value = try? Self(validating: rawValue) else { return nil }; self = value }
    public init(from decoder: Decoder) throws { try self.init(validating: decoder.singleValueContainer().decode(String.self)) }
    public func encode(to encoder: Encoder) throws { var container = encoder.singleValueContainer(); try container.encode(rawValue) }
}

public struct DesktopSourceGroupID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    public let rawValue: String
    public init(validating rawValue: String) throws { try validateIdentifier(rawValue, field: "source_group_id"); self.rawValue = rawValue }
    public init?(rawValue: String) { guard let value = try? Self(validating: rawValue) else { return nil }; self = value }
    public init(from decoder: Decoder) throws { try self.init(validating: decoder.singleValueContainer().decode(String.self)) }
    public func encode(to encoder: Encoder) throws { var container = encoder.singleValueContainer(); try container.encode(rawValue) }
}

public struct DesktopInputID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    public let rawValue: String
    public init(validating rawValue: String) throws { try validateIdentifier(rawValue, field: "input_id"); self.rawValue = rawValue }
    public init?(rawValue: String) { guard let value = try? Self(validating: rawValue) else { return nil }; self = value }
    public init(from decoder: Decoder) throws { try self.init(validating: decoder.singleValueContainer().decode(String.self)) }
    public func encode(to encoder: Encoder) throws { var container = encoder.singleValueContainer(); try container.encode(rawValue) }
}

public struct DesktopEventID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
    public let rawValue: String
    public init(validating rawValue: String) throws { try validateIdentifier(rawValue, field: "event_id"); self.rawValue = rawValue }
    public init?(rawValue: String) { guard let value = try? Self(validating: rawValue) else { return nil }; self = value }
    public init(from decoder: Decoder) throws { try self.init(validating: decoder.singleValueContainer().decode(String.self)) }
    public func encode(to encoder: Encoder) throws { var container = encoder.singleValueContainer(); try container.encode(rawValue) }
}

public struct DesktopVector3: Codable, Equatable, Hashable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double

    public init(x: Double, y: Double, z: Double) throws {
        guard x.isFinite, y.isFinite, z.isFinite else {
            throw DesktopGameValidationError.nonfinite(field: "vector")
        }
        self.x = x
        self.y = y
        self.z = z
    }

    private init(validatedX x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    public static let zero = DesktopVector3(validatedX: 0, y: 0, z: 0)
    public static let one = DesktopVector3(validatedX: 1, y: 1, z: 1)

    public var magnitude: Double { hypot(hypot(x, y), z) }

    public func normalized() throws -> DesktopVector3 {
        let magnitude = magnitude
        guard magnitude.isFinite, magnitude > 0.000_000_001 else {
            throw DesktopGameValidationError.invalidValue(field: "normalized_vector")
        }
        return try DesktopVector3(x: x / magnitude, y: y / magnitude, z: z / magnitude)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            x: container.decode(Double.self, forKey: .x),
            y: container.decode(Double.self, forKey: .y),
            z: container.decode(Double.self, forKey: .z)
        )
    }
}

/// Unit rotation with a canonical sign: positive W wins; when W is zero, the
/// first nonzero X/Y/Z component is positive.
public struct DesktopQuaternion: Codable, Equatable, Hashable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double
    public let w: Double

    public init(x: Double, y: Double, z: Double, w: Double) throws {
        guard x.isFinite, y.isFinite, z.isFinite, w.isFinite else {
            throw DesktopGameValidationError.nonfinite(field: "quaternion")
        }
        let magnitude = hypot(hypot(x, y), hypot(z, w))
        guard magnitude.isFinite, magnitude > 0.000_000_001 else {
            throw DesktopGameValidationError.nonNormalizableQuaternion
        }
        var normalizedX = x / magnitude
        var normalizedY = y / magnitude
        var normalizedZ = z / magnitude
        var normalizedW = w / magnitude
        let shouldFlipHemisphere = normalizedW < 0
            || (normalizedW == 0 && normalizedX < 0)
            || (normalizedW == 0 && normalizedX == 0 && normalizedY < 0)
            || (normalizedW == 0 && normalizedX == 0 && normalizedY == 0
                && normalizedZ < 0)
        if shouldFlipHemisphere {
            normalizedX = -normalizedX
            normalizedY = -normalizedY
            normalizedZ = -normalizedZ
            normalizedW = -normalizedW
        }
        self.x = normalizedX == 0 ? 0 : normalizedX
        self.y = normalizedY == 0 ? 0 : normalizedY
        self.z = normalizedZ == 0 ? 0 : normalizedZ
        self.w = normalizedW == 0 ? 0 : normalizedW
    }

    private init(validatedX x: Double, y: Double, z: Double, w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    public static let identity = DesktopQuaternion(validatedX: 0, y: 0, z: 0, w: 1)
    public var magnitude: Double { hypot(hypot(x, y), hypot(z, w)) }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            x: container.decode(Double.self, forKey: .x),
            y: container.decode(Double.self, forKey: .y),
            z: container.decode(Double.self, forKey: .z),
            w: container.decode(Double.self, forKey: .w)
        )
    }
}

public struct DesktopPose3D: Codable, Equatable, Sendable {
    public let position: DesktopVector3
    public let orientation: DesktopQuaternion

    public init(position: DesktopVector3, orientation: DesktopQuaternion) {
        self.position = position
        self.orientation = orientation
    }

    public static let identity = DesktopPose3D(position: .zero, orientation: .identity)
}

public struct DesktopKinematics3D: Codable, Equatable, Sendable {
    public let linearVelocity: DesktopVector3
    public let angularVelocity: DesktopVector3

    public init(linearVelocity: DesktopVector3, angularVelocity: DesktopVector3) {
        self.linearVelocity = linearVelocity
        self.angularVelocity = angularVelocity
    }

    enum CodingKeys: String, CodingKey {
        case linearVelocity = "linear_velocity"
        case angularVelocity = "angular_velocity"
    }

    public static let stationary = DesktopKinematics3D(
        linearVelocity: .zero,
        angularVelocity: .zero
    )
}

public struct DesktopDepthRange: Codable, Equatable, Sendable {
    public let minZ: Double
    public let maxZ: Double

    public init(minZ: Double, maxZ: Double) throws {
        guard minZ.isFinite, maxZ.isFinite else {
            throw DesktopGameValidationError.nonfinite(field: "depth_range")
        }
        guard minZ <= maxZ else {
            throw DesktopGameValidationError.invalidRange(field: "depth_range")
        }
        self.minZ = minZ
        self.maxZ = maxZ
    }

    enum CodingKeys: String, CodingKey {
        case minZ = "min_z"
        case maxZ = "max_z"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            minZ: container.decode(Double.self, forKey: .minZ),
            maxZ: container.decode(Double.self, forKey: .maxZ)
        )
    }
}

public enum DesktopCoordinateSystem: String, Codable, Sendable {
    case rightHandedXRightYUpZTowardViewer = "right_handed_x_right_y_up_z_toward_viewer"
}

public enum DesktopViewportOrigin: String, Codable, Sendable {
    case screenPlaneBottomLeft = "screen_plane_bottom_left"
}

public enum DesktopCoordinateUnits: String, Codable, Sendable {
    case worldUnits = "world_units"
}

public struct DesktopViewport: Codable, Equatable, Sendable {
    public let id: DesktopViewportID
    public let width: Double
    public let height: Double
    public let depthRange: DesktopDepthRange
    public let coordinateSystem: DesktopCoordinateSystem
    public let origin: DesktopViewportOrigin
    public let units: DesktopCoordinateUnits
    public let desktopPlaneZ: Double

    public init(
        id: DesktopViewportID,
        width: Double,
        height: Double,
        depthRange: DesktopDepthRange
    ) throws {
        guard width.isFinite, height.isFinite else {
            throw DesktopGameValidationError.nonfinite(field: "viewport")
        }
        guard width > 0, height > 0 else {
            throw DesktopGameValidationError.invalidValue(field: "viewport")
        }
        self.id = id
        self.width = width
        self.height = height
        self.depthRange = depthRange
        coordinateSystem = .rightHandedXRightYUpZTowardViewer
        origin = .screenPlaneBottomLeft
        units = .worldUnits
        desktopPlaneZ = 0
    }

    /// Converts an observation-space point whose origin is the top-left of
    /// this screen plane into the canonical bottom-left world coordinate.
    public func worldPosition(
        fromScreenPlaneTopLeft position: DesktopVector3
    ) throws -> DesktopVector3 {
        try DesktopVector3(x: position.x, y: height - position.y, z: position.z)
    }

    enum CodingKeys: String, CodingKey {
        case id, width, height
        case depthRange = "depth_range"
        case coordinateSystem = "coordinate_system"
        case origin, units
        case desktopPlaneZ = "desktop_plane_z"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let coordinateSystem = try container.decode(DesktopCoordinateSystem.self, forKey: .coordinateSystem)
        let origin = try container.decode(DesktopViewportOrigin.self, forKey: .origin)
        let units = try container.decode(DesktopCoordinateUnits.self, forKey: .units)
        let desktopPlaneZ = try container.decode(Double.self, forKey: .desktopPlaneZ)
        guard coordinateSystem == .rightHandedXRightYUpZTowardViewer,
              origin == .screenPlaneBottomLeft,
              units == .worldUnits,
              desktopPlaneZ == 0 else {
            throw DesktopGameValidationError.invalidValue(field: "coordinate_system")
        }
        try self.init(
            id: container.decode(DesktopViewportID.self, forKey: .id),
            width: container.decode(Double.self, forKey: .width),
            height: container.decode(Double.self, forKey: .height),
            depthRange: container.decode(DesktopDepthRange.self, forKey: .depthRange)
        )
    }
}
