import Foundation

public struct DesktopGameRules: Codable, Equatable, Sendable {
    public let id: String
    public let revision: UInt64
    public let fixedTickRate: Double
    public let gravity: DesktopVector3

    public init(
        id: String,
        revision: UInt64,
        fixedTickRate: Double,
        gravity: DesktopVector3
    ) throws {
        try validateIdentifier(id, field: "rules_id")
        guard fixedTickRate.isFinite else {
            throw DesktopGameValidationError.nonfinite(field: "fixed_tick_rate")
        }
        guard fixedTickRate > 0 else {
            throw DesktopGameValidationError.invalidValue(field: "fixed_tick_rate")
        }
        self.id = id
        self.revision = revision
        self.fixedTickRate = fixedTickRate
        self.gravity = gravity
    }

    enum CodingKeys: String, CodingKey {
        case id, revision, gravity
        case fixedTickRate = "fixed_tick_rate"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(String.self, forKey: .id),
            revision: container.decode(UInt64.self, forKey: .revision),
            fixedTickRate: container.decode(Double.self, forKey: .fixedTickRate),
            gravity: container.decode(DesktopVector3.self, forKey: .gravity)
        )
    }
}

public enum DesktopSourceSide: String, Codable, CaseIterable, Sendable {
    case minX = "min_x"
    case maxX = "max_x"
    case minY = "min_y"
    case maxY = "max_y"
}

public struct DesktopExtrudedSegment: Codable, Equatable, Sendable {
    public let start: DesktopVector3
    public let end: DesktopVector3
    public let thickness: Double
    public let depthRange: DesktopDepthRange

    public init(
        start: DesktopVector3,
        end: DesktopVector3,
        thickness: Double,
        depthRange: DesktopDepthRange
    ) throws {
        guard thickness.isFinite else {
            throw DesktopGameValidationError.nonfinite(field: "surface_thickness")
        }
        guard thickness > 0, start != end else {
            throw DesktopGameValidationError.invalidValue(field: "surface_geometry")
        }
        self.start = start
        self.end = end
        self.thickness = thickness
        self.depthRange = depthRange
    }

    enum CodingKeys: String, CodingKey {
        case start, end, thickness
        case depthRange = "depth_range"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            start: container.decode(DesktopVector3.self, forKey: .start),
            end: container.decode(DesktopVector3.self, forKey: .end),
            thickness: container.decode(Double.self, forKey: .thickness),
            depthRange: container.decode(DesktopDepthRange.self, forKey: .depthRange)
        )
    }
}

public enum DesktopSurfaceCollisionRole: String, Codable, CaseIterable, Hashable, Sendable {
    case objectSolid = "object_solid"
    case playerLanding = "player_landing"
    case playerWall = "player_wall"
}

public struct DesktopGameSurface: Codable, Equatable, Sendable {
    public let id: DesktopSurfaceID
    public let sourceGroupID: DesktopSourceGroupID
    public let sourceSide: DesktopSourceSide
    public let desktopLayerRank: Int
    public let geometry: DesktopExtrudedSegment
    public let collisionRoles: [DesktopSurfaceCollisionRole]

    public init(
        id: DesktopSurfaceID,
        sourceGroupID: DesktopSourceGroupID,
        sourceSide: DesktopSourceSide,
        desktopLayerRank: Int,
        geometry: DesktopExtrudedSegment,
        collisionRoles: [DesktopSurfaceCollisionRole]
    ) throws {
        guard desktopLayerRank >= 0 else {
            throw DesktopGameValidationError.invalidValue(field: "desktop_layer_rank")
        }
        guard Set(collisionRoles).count == collisionRoles.count else {
            throw DesktopGameValidationError.invalidValue(field: "collision_roles")
        }
        self.id = id
        self.sourceGroupID = sourceGroupID
        self.sourceSide = sourceSide
        self.desktopLayerRank = desktopLayerRank
        self.geometry = geometry
        self.collisionRoles = collisionRoles
    }

    enum CodingKeys: String, CodingKey {
        case id, geometry
        case sourceGroupID = "source_group_id"
        case sourceSide = "source_side"
        case desktopLayerRank = "desktop_layer_rank"
        case collisionRoles = "collision_roles"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(DesktopSurfaceID.self, forKey: .id),
            sourceGroupID: container.decode(DesktopSourceGroupID.self, forKey: .sourceGroupID),
            sourceSide: container.decode(DesktopSourceSide.self, forKey: .sourceSide),
            desktopLayerRank: container.decode(Int.self, forKey: .desktopLayerRank),
            geometry: container.decode(DesktopExtrudedSegment.self, forKey: .geometry),
            collisionRoles: container.decode([DesktopSurfaceCollisionRole].self, forKey: .collisionRoles)
        )
    }
}

public struct DesktopAssetReference: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let revision: String
    public let contentHash: String

    public init(id: String, revision: String, contentHash: String) throws {
        try validateIdentifier(id, field: "asset_id")
        try validateIdentifier(revision, field: "asset_revision")
        try validateIdentifier(contentHash, field: "asset_content_hash")
        self.id = id
        self.revision = revision
        self.contentHash = contentHash
    }

    enum CodingKeys: String, CodingKey {
        case id, revision
        case contentHash = "content_hash"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(String.self, forKey: .id),
            revision: container.decode(String.self, forKey: .revision),
            contentHash: container.decode(String.self, forKey: .contentHash)
        )
    }
}

public struct DesktopPickMaskReference: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let revision: String
    public let contentHash: String

    public init(id: String, revision: String, contentHash: String) throws {
        try validateIdentifier(id, field: "pick_mask_id")
        try validateIdentifier(revision, field: "pick_mask_revision")
        try validateIdentifier(contentHash, field: "pick_mask_content_hash")
        self.id = id
        self.revision = revision
        self.contentHash = contentHash
    }

    enum CodingKeys: String, CodingKey {
        case id, revision
        case contentHash = "content_hash"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(String.self, forKey: .id),
            revision: container.decode(String.self, forKey: .revision),
            contentHash: container.decode(String.self, forKey: .contentHash)
        )
    }
}

public struct DesktopVisualTransform: Codable, Equatable, Sendable {
    public let localPose: DesktopPose3D
    public let scale: DesktopVector3

    public init(localPose: DesktopPose3D, scale: DesktopVector3) throws {
        guard scale.x > 0, scale.y > 0, scale.z > 0 else {
            throw DesktopGameValidationError.invalidValue(field: "visual_scale")
        }
        self.localPose = localPose
        self.scale = scale
    }

    enum CodingKeys: String, CodingKey {
        case scale
        case localPose = "local_pose"
    }

    private init(validatedLocalPose localPose: DesktopPose3D, scale: DesktopVector3) {
        self.localPose = localPose
        self.scale = scale
    }

    public static let identity = DesktopVisualTransform(
        validatedLocalPose: .identity,
        scale: .one
    )

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            localPose: container.decode(DesktopPose3D.self, forKey: .localPose),
            scale: container.decode(DesktopVector3.self, forKey: .scale)
        )
    }
}

public struct DesktopAvatarVisual: Codable, Equatable, Sendable {
    public let asset: DesktopAssetReference
    public let animationClipID: String
    public let frameID: String?
    public let normalizedPhase: Double?
    public let drawTransform: DesktopVisualTransform
    public let pickMask: DesktopPickMaskReference

    public init(
        asset: DesktopAssetReference,
        animationClipID: String,
        frameID: String?,
        normalizedPhase: Double?,
        drawTransform: DesktopVisualTransform,
        pickMask: DesktopPickMaskReference
    ) throws {
        try validateIdentifier(animationClipID, field: "animation_clip_id")
        if let frameID {
            try validateIdentifier(frameID, field: "frame_id")
        }
        if let normalizedPhase {
            guard normalizedPhase.isFinite else {
                throw DesktopGameValidationError.nonfinite(field: "normalized_phase")
            }
            guard (0...1).contains(normalizedPhase) else {
                throw DesktopGameValidationError.invalidRange(field: "normalized_phase")
            }
        }
        guard (frameID != nil) != (normalizedPhase != nil) else {
            throw DesktopGameValidationError.invalidValue(field: "animation_sample")
        }
        self.asset = asset
        self.animationClipID = animationClipID
        self.frameID = frameID
        self.normalizedPhase = normalizedPhase
        self.drawTransform = drawTransform
        self.pickMask = pickMask
    }

    enum CodingKeys: String, CodingKey {
        case asset
        case animationClipID = "animation_clip_id"
        case frameID = "frame_id"
        case normalizedPhase = "normalized_phase"
        case drawTransform = "draw_transform"
        case pickMask = "pick_mask"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            asset: container.decode(DesktopAssetReference.self, forKey: .asset),
            animationClipID: container.decode(String.self, forKey: .animationClipID),
            frameID: container.decodeIfPresent(String.self, forKey: .frameID),
            normalizedPhase: container.decodeIfPresent(Double.self, forKey: .normalizedPhase),
            drawTransform: container.decode(DesktopVisualTransform.self, forKey: .drawTransform),
            pickMask: container.decode(DesktopPickMaskReference.self, forKey: .pickMask)
        )
    }
}

public enum DesktopAvatarMotion: String, Codable, CaseIterable, Sendable {
    case idle, walk, run, jump
    case wallSlide = "wall_slide"
    case sit
}

public struct DesktopAvatarLocomotion: Codable, Equatable, Sendable {
    public let motion: DesktopAvatarMotion
    public let grounded: Bool
    public let supportSurfaceID: DesktopSurfaceID?
    public let remainingAirJumps: UInt8
    public let wallTraversal: DesktopWallTraversalState?

    public init(
        motion: DesktopAvatarMotion,
        grounded: Bool,
        supportSurfaceID: DesktopSurfaceID?,
        remainingAirJumps: UInt8,
        wallTraversal: DesktopWallTraversalState? = nil
    ) {
        self.motion = motion
        self.grounded = grounded
        self.supportSurfaceID = supportSurfaceID
        self.remainingAirJumps = remainingAirJumps
        self.wallTraversal = wallTraversal
    }

    enum CodingKeys: String, CodingKey {
        case motion, grounded
        case supportSurfaceID = "support_surface_id"
        case remainingAirJumps = "remaining_air_jumps"
        case wallTraversal = "wall_traversal"
    }
}

public struct DesktopGameAvatar: Codable, Equatable, Sendable {
    public let id: DesktopEntityID
    public let ownerID: String?
    public let pose: DesktopPose3D
    public let kinematics: DesktopKinematics3D
    public let facing: DesktopVector3
    public let locomotion: DesktopAvatarLocomotion
    public let visual: DesktopAvatarVisual

    public init(
        id: DesktopEntityID,
        ownerID: String? = nil,
        pose: DesktopPose3D,
        kinematics: DesktopKinematics3D,
        facing: DesktopVector3,
        locomotion: DesktopAvatarLocomotion,
        visual: DesktopAvatarVisual
    ) throws {
        guard facing.magnitude > 0.000_000_001 else {
            throw DesktopGameValidationError.invalidValue(field: "facing")
        }
        if let ownerID { try validateIdentifier(ownerID, field: "owner_id") }
        self.id = id
        self.ownerID = ownerID
        self.pose = pose
        self.kinematics = kinematics
        self.facing = try facing.normalized()
        self.locomotion = locomotion
        self.visual = visual
    }

    enum CodingKeys: String, CodingKey {
        case id, pose, kinematics, facing, locomotion, visual
        case ownerID = "owner_id"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(DesktopEntityID.self, forKey: .id),
            ownerID: container.decodeIfPresent(String.self, forKey: .ownerID),
            pose: container.decode(DesktopPose3D.self, forKey: .pose),
            kinematics: container.decode(DesktopKinematics3D.self, forKey: .kinematics),
            facing: container.decode(DesktopVector3.self, forKey: .facing),
            locomotion: container.decode(DesktopAvatarLocomotion.self, forKey: .locomotion),
            visual: container.decode(DesktopAvatarVisual.self, forKey: .visual)
        )
    }
}

public enum DesktopObjectShapeKind: String, Codable, CaseIterable, Sendable {
    case circle, box, triangle
}

public struct DesktopObjectShape: Codable, Equatable, Sendable {
    public let kind: DesktopObjectShapeKind
    public let size: DesktopVector3

    public init(kind: DesktopObjectShapeKind, size: DesktopVector3) throws {
        guard size.x > 0, size.y > 0, size.z > 0 else {
            throw DesktopGameValidationError.invalidValue(field: "object_size")
        }
        self.kind = kind
        self.size = size
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            kind: container.decode(DesktopObjectShapeKind.self, forKey: .kind),
            size: container.decode(DesktopVector3.self, forKey: .size)
        )
    }
}

public struct DesktopMaterialReference: Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let revision: UInt64

    public init(id: String, revision: UInt64) throws {
        try validateIdentifier(id, field: "material_id")
        self.id = id
        self.revision = revision
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            id: container.decode(String.self, forKey: .id),
            revision: container.decode(UInt64.self, forKey: .revision)
        )
    }
}

public struct DesktopGameObject: Codable, Equatable, Sendable {
    public let id: DesktopEntityID
    public let shape: DesktopObjectShape
    public let pose: DesktopPose3D
    public let kinematics: DesktopKinematics3D
    public let material: DesktopMaterialReference

    public init(
        id: DesktopEntityID,
        shape: DesktopObjectShape,
        pose: DesktopPose3D,
        kinematics: DesktopKinematics3D,
        material: DesktopMaterialReference
    ) {
        self.id = id
        self.shape = shape
        self.pose = pose
        self.kinematics = kinematics
        self.material = material
    }
}

public struct DesktopGameSnapshot: Codable, Equatable, Sendable {
    public let viewport: DesktopViewport
    public let rules: DesktopGameRules
    public let surfaces: [DesktopGameSurface]
    public let focusedSourceGroupID: DesktopSourceGroupID?
    public let avatars: [DesktopGameAvatar]
    public let objects: [DesktopGameObject]

    public init(
        viewport: DesktopViewport,
        rules: DesktopGameRules,
        surfaces: [DesktopGameSurface],
        focusedSourceGroupID: DesktopSourceGroupID? = nil,
        avatars: [DesktopGameAvatar],
        objects: [DesktopGameObject]
    ) throws {
        let surfaceIDs = surfaces.map(\.id)
        guard Set(surfaceIDs).count == surfaceIDs.count else {
            throw DesktopGameValidationError.duplicateIdentifier("surface")
        }
        let entityIDs = avatars.map(\.id) + objects.map(\.id)
        guard Set(entityIDs).count == entityIDs.count else {
            throw DesktopGameValidationError.duplicateIdentifier("entity")
        }
        if let focusedSourceGroupID,
           surfaces.contains(where: { $0.sourceGroupID == focusedSourceGroupID }) == false {
            throw DesktopGameValidationError.invalidValue(field: "focused_source_group_id")
        }
        self.viewport = viewport
        self.rules = rules
        self.surfaces = surfaces
        self.focusedSourceGroupID = focusedSourceGroupID
        self.avatars = avatars
        self.objects = objects
    }

    enum CodingKeys: String, CodingKey {
        case viewport, rules, surfaces, avatars, objects
        case focusedSourceGroupID = "focused_source_group_id"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            viewport: container.decode(DesktopViewport.self, forKey: .viewport),
            rules: container.decode(DesktopGameRules.self, forKey: .rules),
            surfaces: container.decode([DesktopGameSurface].self, forKey: .surfaces),
            focusedSourceGroupID: container.decodeIfPresent(DesktopSourceGroupID.self, forKey: .focusedSourceGroupID),
            avatars: container.decode([DesktopGameAvatar].self, forKey: .avatars),
            objects: container.decode([DesktopGameObject].self, forKey: .objects)
        )
    }
}

public enum DesktopEntityIdentityLedgerError: Error, Equatable, Sendable {
    case alreadyActive(DesktopEntityID)
    case reused(DesktopEntityID)
    case notActive(DesktopEntityID)
}

/// Single atomic authority-side identity history for one hosted world session.
/// Aliases share this ledger; despawned IDs remain retired for its lifetime.
/// `@unchecked Sendable` is justified because `NSLock` guards every access to
/// the only mutable stored value, `state`.
public final class DesktopEntityIdentityLedger: @unchecked Sendable {
    public let worldSessionID: DesktopWorldSessionID
    private let lock = NSLock()
    private var state: State

    private struct State {
        var activeIDs: Set<DesktopEntityID> = []
        var retiredIDs: Set<DesktopEntityID> = []
    }

    public var activeIDs: Set<DesktopEntityID> {
        withLockedState { $0.activeIDs }
    }

    public var retiredIDs: Set<DesktopEntityID> {
        withLockedState { $0.retiredIDs }
    }

    public init(worldSessionID: DesktopWorldSessionID) {
        self.worldSessionID = worldSessionID
        state = State()
    }

    public func spawn(_ entityID: DesktopEntityID) throws {
        try withLockedState { state in
            guard state.activeIDs.contains(entityID) == false else {
                throw DesktopEntityIdentityLedgerError.alreadyActive(entityID)
            }
            guard state.retiredIDs.contains(entityID) == false else {
                throw DesktopEntityIdentityLedgerError.reused(entityID)
            }
            state.activeIDs.insert(entityID)
        }
    }

    public func despawn(_ entityID: DesktopEntityID) throws {
        try withLockedState { state in
            guard state.activeIDs.remove(entityID) != nil else {
                throw DesktopEntityIdentityLedgerError.notActive(entityID)
            }
            state.retiredIDs.insert(entityID)
        }
    }

    private func withLockedState<Result>(
        _ body: (inout State) throws -> Result
    ) rethrows -> Result {
        lock.lock()
        defer { lock.unlock() }
        return try body(&state)
    }
}
