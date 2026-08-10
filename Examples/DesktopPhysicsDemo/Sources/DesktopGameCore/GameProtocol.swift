import Foundation

public struct DesktopGameDeltaV1: Codable, Equatable, Sendable {
    public let upsertedSurfaces: [DesktopGameSurface]
    public let removedSurfaceIDs: [DesktopSurfaceID]
    public let upsertedAvatars: [DesktopGameAvatar]
    public let removedAvatarIDs: [DesktopEntityID]
    public let upsertedObjects: [DesktopGameObject]
    public let removedObjectIDs: [DesktopEntityID]

    public init(
        upsertedSurfaces: [DesktopGameSurface] = [],
        removedSurfaceIDs: [DesktopSurfaceID] = [],
        upsertedAvatars: [DesktopGameAvatar] = [],
        removedAvatarIDs: [DesktopEntityID] = [],
        upsertedObjects: [DesktopGameObject] = [],
        removedObjectIDs: [DesktopEntityID] = []
    ) throws {
        try Self.requireUnique(
            upsertedSurfaces.map(\.id),
            field: "delta.upserted_surfaces"
        )
        try Self.requireUnique(
            removedSurfaceIDs,
            field: "delta.removed_surface_ids"
        )
        try Self.requireUnique(
            upsertedAvatars.map(\.id),
            field: "delta.upserted_avatars"
        )
        try Self.requireUnique(
            removedAvatarIDs,
            field: "delta.removed_avatar_ids"
        )
        try Self.requireUnique(
            upsertedObjects.map(\.id),
            field: "delta.upserted_objects"
        )
        try Self.requireUnique(
            removedObjectIDs,
            field: "delta.removed_object_ids"
        )

        let upsertedSurfaceIDs = Set(upsertedSurfaces.map(\.id))
        guard upsertedSurfaceIDs.isDisjoint(with: removedSurfaceIDs) else {
            throw DesktopGameValidationError.invalidValue(
                field: "delta.surface_upsert_remove_conflict"
            )
        }

        let avatarUpserts = Set(upsertedAvatars.map(\.id))
        let objectUpserts = Set(upsertedObjects.map(\.id))
        let avatarRemovals = Set(removedAvatarIDs)
        let objectRemovals = Set(removedObjectIDs)
        guard avatarUpserts.isDisjoint(with: objectUpserts),
              avatarRemovals.isDisjoint(with: objectRemovals),
              avatarUpserts.isDisjoint(with: avatarRemovals),
              objectUpserts.isDisjoint(with: objectRemovals),
              avatarUpserts.isDisjoint(with: objectRemovals),
              objectUpserts.isDisjoint(with: avatarRemovals) else {
            throw DesktopGameValidationError.invalidValue(
                field: "delta.entity_identity_conflict"
            )
        }

        self.upsertedSurfaces = upsertedSurfaces
        self.removedSurfaceIDs = removedSurfaceIDs
        self.upsertedAvatars = upsertedAvatars
        self.removedAvatarIDs = removedAvatarIDs
        self.upsertedObjects = upsertedObjects
        self.removedObjectIDs = removedObjectIDs
    }

    enum CodingKeys: String, CodingKey {
        case upsertedSurfaces = "upserted_surfaces"
        case removedSurfaceIDs = "removed_surface_ids"
        case upsertedAvatars = "upserted_avatars"
        case removedAvatarIDs = "removed_avatar_ids"
        case upsertedObjects = "upserted_objects"
        case removedObjectIDs = "removed_object_ids"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            upsertedSurfaces: container.decode([DesktopGameSurface].self, forKey: .upsertedSurfaces),
            removedSurfaceIDs: container.decode([DesktopSurfaceID].self, forKey: .removedSurfaceIDs),
            upsertedAvatars: container.decode([DesktopGameAvatar].self, forKey: .upsertedAvatars),
            removedAvatarIDs: container.decode([DesktopEntityID].self, forKey: .removedAvatarIDs),
            upsertedObjects: container.decode([DesktopGameObject].self, forKey: .upsertedObjects),
            removedObjectIDs: container.decode([DesktopEntityID].self, forKey: .removedObjectIDs)
        )
    }

    private static func requireUnique<ID: Hashable>(
        _ identifiers: [ID],
        field: String
    ) throws {
        guard Set(identifiers).count == identifiers.count else {
            throw DesktopGameValidationError.duplicateIdentifier(field)
        }
    }
}

public enum DesktopSemanticInputAction: Equatable, Sendable {
    case move(direction: DesktopVector3)
    case jumpPressed
    case jumpReleased
    case runChanged(isHeld: Bool)
    case dropThrough
    case wallTraversal
    case dragBegan(entityID: DesktopEntityID, worldPosition: DesktopVector3)
    case dragMoved(worldPosition: DesktopVector3)
    case dragEnded(worldPosition: DesktopVector3)
}

extension DesktopSemanticInputAction: Codable {
    private enum Kind: String, Codable {
        case move
        case jumpPressed = "jump_pressed"
        case jumpReleased = "jump_released"
        case runChanged = "run_changed"
        case dropThrough = "drop_through"
        case wallTraversal = "wall_traversal"
        case dragBegan = "drag_began"
        case dragMoved = "drag_moved"
        case dragEnded = "drag_ended"
    }

    private enum CodingKeys: String, CodingKey {
        case kind, direction
        case isHeld = "is_held"
        case entityID = "entity_id"
        case worldPosition = "world_position"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .move:
            self = .move(direction: try container.decode(DesktopVector3.self, forKey: .direction))
        case .jumpPressed: self = .jumpPressed
        case .jumpReleased: self = .jumpReleased
        case .runChanged:
            self = .runChanged(isHeld: try container.decode(Bool.self, forKey: .isHeld))
        case .dropThrough: self = .dropThrough
        case .wallTraversal: self = .wallTraversal
        case .dragBegan:
            self = .dragBegan(
                entityID: try container.decode(DesktopEntityID.self, forKey: .entityID),
                worldPosition: try container.decode(DesktopVector3.self, forKey: .worldPosition)
            )
        case .dragMoved:
            self = .dragMoved(
                worldPosition: try container.decode(DesktopVector3.self, forKey: .worldPosition)
            )
        case .dragEnded:
            self = .dragEnded(
                worldPosition: try container.decode(DesktopVector3.self, forKey: .worldPosition)
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .move(direction):
            try container.encode(Kind.move, forKey: .kind)
            try container.encode(direction, forKey: .direction)
        case .jumpPressed:
            try container.encode(Kind.jumpPressed, forKey: .kind)
        case .jumpReleased:
            try container.encode(Kind.jumpReleased, forKey: .kind)
        case let .runChanged(isHeld):
            try container.encode(Kind.runChanged, forKey: .kind)
            try container.encode(isHeld, forKey: .isHeld)
        case .dropThrough:
            try container.encode(Kind.dropThrough, forKey: .kind)
        case .wallTraversal:
            try container.encode(Kind.wallTraversal, forKey: .kind)
        case let .dragBegan(entityID, worldPosition):
            try container.encode(Kind.dragBegan, forKey: .kind)
            try container.encode(entityID, forKey: .entityID)
            try container.encode(worldPosition, forKey: .worldPosition)
        case let .dragMoved(worldPosition):
            try container.encode(Kind.dragMoved, forKey: .kind)
            try container.encode(worldPosition, forKey: .worldPosition)
        case let .dragEnded(worldPosition):
            try container.encode(Kind.dragEnded, forKey: .kind)
            try container.encode(worldPosition, forKey: .worldPosition)
        }
    }
}

public struct DesktopGameInput: Codable, Equatable, Sendable {
    public let id: DesktopInputID
    public let actorID: DesktopEntityID
    public let inputSequence: UInt64
    public let intendedTick: UInt64?
    public let action: DesktopSemanticInputAction

    public init(
        id: DesktopInputID,
        actorID: DesktopEntityID,
        inputSequence: UInt64,
        intendedTick: UInt64? = nil,
        action: DesktopSemanticInputAction
    ) {
        self.id = id
        self.actorID = actorID
        self.inputSequence = inputSequence
        self.intendedTick = intendedTick
        self.action = action
    }

    enum CodingKeys: String, CodingKey {
        case id, action
        case actorID = "actor_id"
        case inputSequence = "input_sequence"
        case intendedTick = "intended_tick"
    }
}

public enum DesktopGameEventKind: String, Codable, CaseIterable, Sendable {
    case spawned, despawned, jumped, landed
    case wallTraversalBegan = "wall_traversal_began"
    case wallTraversalEnded = "wall_traversal_ended"
    case dragBegan = "drag_began"
    case dragEnded = "drag_ended"
}

public struct DesktopGameEvent: Codable, Equatable, Sendable {
    public let id: DesktopEventID
    public let tick: UInt64
    public let kind: DesktopGameEventKind
    public let entityID: DesktopEntityID?
    public let surfaceID: DesktopSurfaceID?

    public init(
        id: DesktopEventID,
        tick: UInt64,
        kind: DesktopGameEventKind,
        entityID: DesktopEntityID? = nil,
        surfaceID: DesktopSurfaceID? = nil
    ) {
        self.id = id
        self.tick = tick
        self.kind = kind
        self.entityID = entityID
        self.surfaceID = surfaceID
    }

    enum CodingKeys: String, CodingKey {
        case id, tick, kind
        case entityID = "entity_id"
        case surfaceID = "surface_id"
    }
}

public enum DesktopGamePayload: Equatable, Sendable {
    case snapshot(DesktopGameSnapshot)
    case delta(DesktopGameDeltaV1)
    case inputs([DesktopGameInput])
    case events([DesktopGameEvent])
}

extension DesktopGamePayload: Codable {
    private enum Kind: String, Codable { case snapshot, delta, inputs, events }
    private enum CodingKeys: String, CodingKey { case kind, data }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .snapshot:
            self = .snapshot(try container.decode(DesktopGameSnapshot.self, forKey: .data))
        case .delta:
            self = .delta(try container.decode(DesktopGameDeltaV1.self, forKey: .data))
        case .inputs:
            self = .inputs(try container.decode([DesktopGameInput].self, forKey: .data))
        case .events:
            self = .events(try container.decode([DesktopGameEvent].self, forKey: .data))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .snapshot(snapshot):
            try container.encode(Kind.snapshot, forKey: .kind)
            try container.encode(snapshot, forKey: .data)
        case let .delta(delta):
            try container.encode(Kind.delta, forKey: .kind)
            try container.encode(delta, forKey: .data)
        case let .inputs(inputs):
            try container.encode(Kind.inputs, forKey: .kind)
            try container.encode(inputs, forKey: .data)
        case let .events(events):
            try container.encode(Kind.events, forKey: .kind)
            try container.encode(events, forKey: .data)
        }
    }
}

public struct DesktopGameEnvelope: Codable, Equatable, Sendable {
    public static let currentProtocolMajor: UInt16 = 1
    public static let currentSchemaVersion: UInt16 = 1

    public let protocolMajor: UInt16
    public let schemaVersion: UInt16
    public let worldSessionID: DesktopWorldSessionID
    public let sequence: UInt64
    public let baseSequence: UInt64?
    public let tick: UInt64
    public let payload: DesktopGamePayload

    public init(
        worldSessionID: DesktopWorldSessionID,
        sequence: UInt64,
        baseSequence: UInt64? = nil,
        tick: UInt64,
        payload: DesktopGamePayload
    ) throws {
        let isDelta: Bool = if case .delta = payload { true } else { false }
        guard isDelta == (baseSequence != nil) else {
            throw DesktopGameValidationError.invalidEnvelope(
                "base_sequence is required only for delta payloads"
            )
        }
        if let baseSequence, baseSequence >= sequence {
            throw DesktopGameValidationError.invalidEnvelope(
                "base_sequence must be earlier than sequence"
            )
        }
        protocolMajor = Self.currentProtocolMajor
        schemaVersion = Self.currentSchemaVersion
        self.worldSessionID = worldSessionID
        self.sequence = sequence
        self.baseSequence = baseSequence
        self.tick = tick
        self.payload = payload
    }

    enum CodingKeys: String, CodingKey {
        case sequence, tick, payload
        case protocolMajor = "protocol_major"
        case schemaVersion = "schema_version"
        case worldSessionID = "world_session_id"
        case baseSequence = "base_sequence"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let protocolMajor = try container.decode(UInt16.self, forKey: .protocolMajor)
        let schemaVersion = try container.decode(UInt16.self, forKey: .schemaVersion)
        guard protocolMajor == Self.currentProtocolMajor,
              schemaVersion == Self.currentSchemaVersion else {
            throw DesktopGameValidationError.invalidEnvelope("unsupported protocol or schema")
        }
        try self.init(
            worldSessionID: container.decode(DesktopWorldSessionID.self, forKey: .worldSessionID),
            sequence: container.decode(UInt64.self, forKey: .sequence),
            baseSequence: container.decodeIfPresent(UInt64.self, forKey: .baseSequence),
            tick: container.decode(UInt64.self, forKey: .tick),
            payload: container.decode(DesktopGamePayload.self, forKey: .payload)
        )
    }
}

public enum DesktopReplicaApplicationResult: Equatable, Sendable {
    case applied
    case requiresFullSnapshot
    case notStatePayload
}

/// Serializes validation, synchronous payload application, and committed
/// sequence advancement as one exclusive operation.
///
/// `@unchecked Sendable` is justified because `NSLock` guards all mutable
/// state. The nonescaping application closure runs while the lock is held and
/// must not call back into this coordinator.
public final class DesktopReplicaSequenceCoordinator: @unchecked Sendable {
    private let lock = NSLock()
    private var state = State()

    private struct State {
        var worldSessionID: DesktopWorldSessionID?
        var latestSequence: UInt64?
        var latestTick: UInt64?
    }

    public var worldSessionID: DesktopWorldSessionID? {
        withLockedState { $0.worldSessionID }
    }

    public var latestSequence: UInt64? {
        withLockedState { $0.latestSequence }
    }

    public var latestTick: UInt64? {
        withLockedState { $0.latestTick }
    }

    public init() {}

    public func apply(
        _ envelope: DesktopGameEnvelope,
        _ application: (DesktopGameEnvelope) throws -> Void
    ) rethrows -> DesktopReplicaApplicationResult {
        lock.lock()
        defer { lock.unlock() }

        switch envelope.payload {
        case .snapshot:
            let sameSession = state.worldSessionID == envelope.worldSessionID
            if sameSession {
                guard let latestSequence = state.latestSequence,
                      let latestTick = state.latestTick,
                      envelope.sequence > latestSequence,
                      envelope.tick >= latestTick else {
                    return .requiresFullSnapshot
                }
            }
        case .delta:
            guard state.worldSessionID == envelope.worldSessionID,
                  let latestSequence = state.latestSequence,
                  let latestTick = state.latestTick,
                  envelope.baseSequence == latestSequence,
                  envelope.sequence > latestSequence,
                  envelope.tick >= latestTick else {
                return .requiresFullSnapshot
            }
        case .inputs, .events:
            return .notStatePayload
        }

        try application(envelope)
        state.worldSessionID = envelope.worldSessionID
        state.latestSequence = envelope.sequence
        state.latestTick = envelope.tick
        return .applied
    }

    private func withLockedState<Result>(
        _ body: (State) -> Result
    ) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body(state)
    }
}

public enum DesktopPlanarCapabilityError: Error, Equatable, Sendable {
    case nonplanar(field: String)
    case invalidTolerance
}

public enum DesktopPlanarCapability {
    public static let maximumTolerance = 0.001

    public static func validate(
        _ snapshot: DesktopGameSnapshot,
        tolerance: Double = 0.000_000_1
    ) throws {
        guard tolerance.isFinite,
              (0...maximumTolerance).contains(tolerance) else {
            throw DesktopPlanarCapabilityError.invalidTolerance
        }
        guard abs(snapshot.rules.gravity.z) <= tolerance else {
            throw DesktopPlanarCapabilityError.nonplanar(field: "rules.gravity")
        }
        for surface in snapshot.surfaces {
            guard abs(surface.geometry.start.z) <= tolerance,
                  abs(surface.geometry.end.z) <= tolerance else {
                throw DesktopPlanarCapabilityError.nonplanar(field: "surface.geometry")
            }
        }
        for avatar in snapshot.avatars {
            try validate(
                pose: avatar.pose,
                kinematics: avatar.kinematics,
                field: "avatar",
                tolerance: tolerance
            )
            guard abs(avatar.facing.z) <= tolerance else {
                throw DesktopPlanarCapabilityError.nonplanar(field: "avatar.facing")
            }
            try validate(
                pose: avatar.visual.drawTransform.localPose,
                field: "avatar.visual",
                tolerance: tolerance
            )
        }
        for object in snapshot.objects {
            try validate(
                pose: object.pose,
                kinematics: object.kinematics,
                field: "object",
                tolerance: tolerance
            )
        }
    }

    private static func validate(
        pose: DesktopPose3D,
        kinematics: DesktopKinematics3D,
        field: String,
        tolerance: Double
    ) throws {
        try validate(pose: pose, field: field, tolerance: tolerance)
        guard abs(kinematics.linearVelocity.z) <= tolerance,
              abs(kinematics.angularVelocity.x) <= tolerance,
              abs(kinematics.angularVelocity.y) <= tolerance else {
            throw DesktopPlanarCapabilityError.nonplanar(field: "\(field).kinematics")
        }
    }

    private static func validate(
        pose: DesktopPose3D,
        field: String,
        tolerance: Double
    ) throws {
        guard abs(pose.position.z) <= tolerance,
              abs(pose.orientation.x) <= tolerance,
              abs(pose.orientation.y) <= tolerance else {
            throw DesktopPlanarCapabilityError.nonplanar(field: "\(field).pose")
        }
    }
}
