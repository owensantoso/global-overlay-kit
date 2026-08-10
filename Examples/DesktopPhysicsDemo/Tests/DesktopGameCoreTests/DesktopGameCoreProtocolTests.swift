import Foundation
import Testing
@testable import DesktopGameCore

@Suite("Desktop game-state protocol")
struct DesktopGameCoreProtocolTests {
    @Test("Planar fixture round-trips without private desktop metadata")
    func planarFixtureRoundTripsPrivately() throws {
        let envelope = try Fixtures.planarEnvelope()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(envelope)
        let json = try #require(String(data: data, encoding: .utf8))
        let decoded = try JSONDecoder().decode(DesktopGameEnvelope.self, from: data)
        let golden = try FixtureLoader.text(named: "planar_snapshot_v1")

        #expect(decoded == envelope)
        #expect(json == golden)
        #expect(json.contains("window_id") == false)
        #expect(json.contains("process_id") == false)
        #expect(json.contains("application_name") == false)
        #expect(json.contains("window_title") == false)
        #expect(json.contains("Private Notes") == false)
    }

    @Test("Snapshot rejects duplicate entity identities")
    func snapshotRejectsDuplicateEntityIdentities() throws {
        let avatar = try Fixtures.avatar(id: "entity-1", z: 0)
        let object = try Fixtures.object(id: "entity-1", z: 0)

        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameSnapshot(
                viewport: Fixtures.viewport,
                rules: Fixtures.rules,
                surfaces: [],
                avatars: [avatar],
                objects: [object]
            )
        }
    }

    @Test("Delta envelopes require an exact earlier base sequence")
    func deltaBaseSequenceIsValidated() throws {
        let sessionID = try DesktopWorldSessionID(validating: "world-1")
        let delta = try DesktopGameDeltaV1()

        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameEnvelope(
                worldSessionID: sessionID,
                sequence: 4,
                baseSequence: nil,
                tick: 20,
                payload: .delta(delta)
            )
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameEnvelope(
                worldSessionID: sessionID,
                sequence: 4,
                baseSequence: 4,
                tick: 20,
                payload: .delta(delta)
            )
        }
        let envelope = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 4,
            baseSequence: 3,
            tick: 20,
            payload: .delta(delta)
        )
        #expect(envelope.baseSequence == 3)
    }

    @Test("Replica detects a lost delta and recovers from a full snapshot")
    func replicaSequenceRecovery() throws {
        let sessionID = try DesktopWorldSessionID(validating: "world-1")
        let state = DesktopReplicaSequenceCoordinator()
        let first = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 1,
            tick: 10,
            payload: .snapshot(Fixtures.snapshot(avatarZ: 0, objectZ: 0))
        )
        let second = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 2,
            baseSequence: 1,
            tick: 11,
            payload: .delta(try DesktopGameDeltaV1())
        )
        let lostBase = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 4,
            baseSequence: 3,
            tick: 13,
            payload: .delta(try DesktopGameDeltaV1())
        )
        let recovery = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 5,
            tick: 14,
            payload: .snapshot(Fixtures.snapshot(avatarZ: 0, objectZ: 0))
        )

        #expect(state.apply(first) { _ in } == .applied)
        #expect(state.apply(second) { _ in } == .applied)
        #expect(state.apply(lostBase) { _ in } == .requiresFullSnapshot)
        #expect(state.latestSequence == 2)
        #expect(state.apply(recovery) { _ in } == .applied)
        #expect(state.latestSequence == 5)
        #expect(state.latestTick == 14)
    }

    @Test("A delta cannot cross world sessions")
    func deltaCannotCrossWorldSessions() throws {
        let state = DesktopReplicaSequenceCoordinator()
        let snapshot = try DesktopGameEnvelope(
            worldSessionID: try DesktopWorldSessionID(validating: "world-1"),
            sequence: 1,
            tick: 1,
            payload: .snapshot(Fixtures.snapshot(avatarZ: 0, objectZ: 0))
        )
        let foreignDelta = try DesktopGameEnvelope(
            worldSessionID: try DesktopWorldSessionID(validating: "world-2"),
            sequence: 2,
            baseSequence: 1,
            tick: 2,
            payload: .delta(try DesktopGameDeltaV1())
        )

        #expect(state.apply(snapshot) { _ in } == .applied)
        #expect(state.apply(foreignDelta) { _ in } == .requiresFullSnapshot)
        #expect(state.worldSessionID == (try DesktopWorldSessionID(validating: "world-1")))
        #expect(state.latestSequence == 1)
    }

    @Test("Duplicate and reordered state payloads are rejected without advancing")
    func duplicateAndReorderedAdmissionIsRejected() throws {
        let sessionID = try DesktopWorldSessionID(validating: "world-1")
        let state = DesktopReplicaSequenceCoordinator()
        let first = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 1,
            tick: 10,
            payload: .snapshot(Fixtures.snapshot(avatarZ: 0, objectZ: 0))
        )
        let second = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 2,
            baseSequence: 1,
            tick: 11,
            payload: .delta(try DesktopGameDeltaV1())
        )

        #expect(state.apply(first) { _ in } == .applied)
        #expect(state.apply(first) { _ in } == .requiresFullSnapshot)
        #expect(state.latestSequence == 1)
        #expect(state.apply(second) { _ in } == .applied)
        #expect(state.apply(second) { _ in } == .requiresFullSnapshot)
        #expect(state.apply(first) { _ in } == .requiresFullSnapshot)
        #expect(state.latestSequence == 2)
    }

    @Test("Replica application failure does not advance committed state")
    func replicaApplicationFailureDoesNotAdvance() throws {
        let envelope = try DesktopGameEnvelope(
            worldSessionID: DesktopWorldSessionID(validating: "world-1"),
            sequence: 1,
            tick: 10,
            payload: .snapshot(Fixtures.snapshot(avatarZ: 0, objectZ: 0))
        )
        let state = DesktopReplicaSequenceCoordinator()

        #expect(throws: ExpectedApplicationFailure.self) {
            try state.apply(envelope) { _ in
                throw ExpectedApplicationFailure.failed
            }
        }
        #expect(state.worldSessionID == nil)
        #expect(state.latestSequence == nil)
        #expect(state.latestTick == nil)

        #expect(state.apply(envelope) { _ in } == .applied)
        #expect(state.latestSequence == 1)
        #expect(state.latestTick == 10)
    }

    @Test("Replica rejects stale simulation ticks without advancing")
    func replicaRejectsStaleTicks() throws {
        let sessionID = try DesktopWorldSessionID(validating: "world-1")
        let state = DesktopReplicaSequenceCoordinator()
        let snapshot = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 1,
            tick: 10,
            payload: .snapshot(Fixtures.snapshot(avatarZ: 0, objectZ: 0))
        )
        let oldTick = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 2,
            baseSequence: 1,
            tick: 9,
            payload: .delta(try DesktopGameDeltaV1())
        )

        #expect(state.apply(snapshot) { _ in } == .applied)
        #expect(state.apply(oldTick) { _ in } == .requiresFullSnapshot)
        #expect(state.latestSequence == 1)
        #expect(state.latestTick == 10)
    }

    @Test("Competing replica updates cannot apply an older payload after a newer commit")
    func competingReplicaApplicationsAreAtomic() async throws {
        let sessionID = try DesktopWorldSessionID(validating: "world-1")
        let coordinator = DesktopReplicaSequenceCoordinator()
        let base = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 1,
            tick: 10,
            payload: .snapshot(Fixtures.snapshot(avatarZ: 0, objectZ: 0))
        )
        let older = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 2,
            baseSequence: 1,
            tick: 11,
            payload: .delta(try DesktopGameDeltaV1())
        )
        let newer = try DesktopGameEnvelope(
            worldSessionID: sessionID,
            sequence: 3,
            baseSequence: 1,
            tick: 12,
            payload: .delta(try DesktopGameDeltaV1())
        )
        let log = ReplicaApplicationLog()
        let newerApplicationGate = BlockingApplicationGate()
        let olderStarted = TestSignal()

        #expect(coordinator.apply(base) { _ in } == .applied)

        let newerTask = Task.detached {
            coordinator.apply(newer) { envelope in
                log.append(envelope.sequence)
                newerApplicationGate.enterAndWait()
            }
        }
        newerApplicationGate.waitUntilEntered()
        let olderTask = Task.detached {
            olderStarted.signal()
            return coordinator.apply(older) { envelope in
                log.append(envelope.sequence)
            }
        }
        olderStarted.wait()
        newerApplicationGate.release()

        #expect(await newerTask.value == .applied)
        #expect(await olderTask.value == .requiresFullSnapshot)
        #expect(log.values == [3])
        #expect(coordinator.latestSequence == 3)
        #expect(coordinator.latestTick == 12)
    }

    @Test("Delta rejects duplicate, conflicting, and cross-kind entity IDs")
    func deltaCollectionsAreUnambiguous() throws {
        let surface = try Fixtures.surface()
        let surfaceID = surface.id
        let avatar = try Fixtures.avatar(id: "entity-1", z: 0)
        let object = try Fixtures.object(id: "entity-1", z: 0)

        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(upsertedSurfaces: [surface, surface])
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(removedSurfaceIDs: [surfaceID, surfaceID])
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(
                upsertedSurfaces: [surface],
                removedSurfaceIDs: [surfaceID]
            )
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(upsertedAvatars: [avatar, avatar])
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(removedAvatarIDs: [avatar.id, avatar.id])
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(upsertedObjects: [object, object])
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(removedObjectIDs: [object.id, object.id])
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(
                upsertedAvatars: [avatar],
                removedAvatarIDs: [avatar.id]
            )
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(
                upsertedObjects: [object],
                removedObjectIDs: [object.id]
            )
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(
                upsertedAvatars: [avatar],
                upsertedObjects: [object]
            )
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(
                removedAvatarIDs: [avatar.id],
                removedObjectIDs: [avatar.id]
            )
        }
        #expect(throws: DesktopGameValidationError.self) {
            try DesktopGameDeltaV1(
                upsertedAvatars: [avatar],
                removedObjectIDs: [avatar.id]
            )
        }
    }

    @Test("Malformed delta collections fail at the JSON decode boundary")
    func malformedDeltaFailsDecoding() throws {
        let surfaceID = try DesktopSurfaceID(validating: "surface-1")
        let valid = try DesktopGameDeltaV1(removedSurfaceIDs: [surfaceID])
        let encoded = String(decoding: try JSONEncoder().encode(valid), as: UTF8.self)
        let duplicate = encoded.replacingOccurrences(
            of: #""removed_surface_ids":["surface-1"]"#,
            with: #""removed_surface_ids":["surface-1","surface-1"]"#
        )

        #expect(throws: DesktopGameValidationError.self) {
            try JSONDecoder().decode(DesktopGameDeltaV1.self, from: Data(duplicate.utf8))
        }
    }

    @Test("Authority ledger prevents entity identity reuse within a session")
    func entityIdentityNeverReusesWithinSession() throws {
        let firstSession = try DesktopWorldSessionID(validating: "world-1")
        let secondSession = try DesktopWorldSessionID(validating: "world-2")
        let entityID = try DesktopEntityID(validating: "entity-1")
        let ledger = DesktopEntityIdentityLedger(worldSessionID: firstSession)

        try ledger.spawn(entityID)
        try ledger.despawn(entityID)
        #expect(throws: DesktopEntityIdentityLedgerError.reused(entityID)) {
            try ledger.spawn(entityID)
        }

        let newSessionLedger = DesktopEntityIdentityLedger(worldSessionID: secondSession)
        try newSessionLedger.spawn(entityID)
        #expect(newSessionLedger.activeIDs == [entityID])
    }

    @Test("Authority ledger aliases one atomic owner under concurrent access")
    func entityIdentityLedgerIsSharedAndAtomic() async throws {
        let ledger = DesktopEntityIdentityLedger(
            worldSessionID: try DesktopWorldSessionID(validating: "world-1")
        )
        let alias = ledger
        let sharedID = try DesktopEntityID(validating: "shared")

        try alias.spawn(sharedID)
        #expect(ledger.activeIDs == [sharedID])

        let contestedID = try DesktopEntityID(validating: "contested")
        let successCount = await withTaskGroup(of: Bool.self, returning: Int.self) { group in
            for _ in 0..<32 {
                group.addTask {
                    do {
                        try ledger.spawn(contestedID)
                        return true
                    } catch {
                        return false
                    }
                }
            }
            var count = 0
            for await succeeded in group where succeeded {
                count += 1
            }
            return count
        }

        #expect(successCount == 1)
        #expect(ledger.activeIDs == [sharedID, contestedID])
    }

    @Test("Unknown optional JSON fields are ignored within protocol version one")
    func unknownOptionalFieldsAreIgnored() throws {
        let golden = try FixtureLoader.text(named: "planar_snapshot_v1")
        let extended = String(golden.dropLast())
            + #", "future_optional":{"capability":"depth"}}"#

        let decoded = try JSONDecoder().decode(
            DesktopGameEnvelope.self,
            from: Data(extended.utf8)
        )
        let expected = try Fixtures.planarEnvelope()

        #expect(decoded == expected)
    }

    @Test("Unsupported protocol versions fail decoding")
    func unsupportedProtocolFailsDecoding() throws {
        let golden = try FixtureLoader.text(named: "planar_snapshot_v1")
        let unsupported = golden.replacingOccurrences(
            of: #""protocol_major":1"#,
            with: #""protocol_major":2"#
        )

        #expect(throws: DesktopGameValidationError.self) {
            try JSONDecoder().decode(DesktopGameEnvelope.self, from: Data(unsupported.utf8))
        }
    }

    @Test("Planar capability accepts Z-zero state and rejects depth")
    func planarCapabilityIsExplicit() throws {
        let planar = try Fixtures.snapshot(avatarZ: 0, objectZ: 0)
        let depth = try Fixtures.snapshot(avatarZ: -3, objectZ: 0)
        let depthEnvelope = try DesktopGameEnvelope(
            worldSessionID: try DesktopWorldSessionID(validating: "world-1"),
            sequence: 2,
            tick: 11,
            payload: .snapshot(depth)
        )
        let depthEncoder = JSONEncoder()
        depthEncoder.outputFormatting = [.sortedKeys]
        let depthData = try depthEncoder.encode(depthEnvelope)
        let depthGolden = try FixtureLoader.text(named: "depth_snapshot_v1")

        #expect(String(decoding: depthData, as: UTF8.self) == depthGolden)
        #expect(try JSONDecoder().decode(DesktopGameEnvelope.self, from: depthData) == depthEnvelope)

        try DesktopPlanarCapability.validate(planar)
        #expect(throws: DesktopPlanarCapabilityError.self) {
            try DesktopPlanarCapability.validate(depth)
        }
        #expect(planar.surfaces[0].desktopLayerRank == 7)
        #expect(planar.surfaces[0].geometry.start.z == 0)
    }

    @Test("Planar capability rejects unsafe tolerance values")
    func planarToleranceIsBounded() throws {
        let planar = try Fixtures.snapshot(avatarZ: 0, objectZ: 0)

        for tolerance in [-1, .infinity, .nan, 0.01] {
            #expect(throws: DesktopPlanarCapabilityError.self) {
                try DesktopPlanarCapability.validate(planar, tolerance: tolerance)
            }
        }
        try DesktopPlanarCapability.validate(planar, tolerance: 0.001)
    }

    @Test("Semantic inputs and events round-trip")
    func semanticMessagesRoundTrip() throws {
        let actorID = try DesktopEntityID(validating: "avatar-1")
        let input = DesktopGameInput(
            id: try DesktopInputID(validating: "input-1"),
            actorID: actorID,
            inputSequence: 9,
            intendedTick: 42,
            action: .dragBegan(
                entityID: actorID,
                worldPosition: try DesktopVector3(x: 12, y: 24, z: 0)
            )
        )
        let event = DesktopGameEvent(
            id: try DesktopEventID(validating: "event-1"),
            tick: 42,
            kind: .wallTraversalBegan,
            entityID: actorID,
            surfaceID: try DesktopSurfaceID(validating: "surface-1")
        )
        let payloads: [DesktopGamePayload] = [.inputs([input]), .events([event])]

        for payload in payloads {
            let data = try JSONEncoder().encode(payload)
            #expect(try JSONDecoder().decode(DesktopGamePayload.self, from: data) == payload)
        }
    }
}

private enum ExpectedApplicationFailure: Error {
    case failed
}

private final class ReplicaApplicationLog: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [UInt64] = []

    var values: [UInt64] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ sequence: UInt64) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(sequence)
    }
}

private final class BlockingApplicationGate: @unchecked Sendable {
    private let condition = NSCondition()
    private var entered = false
    private var released = false

    func enterAndWait() {
        condition.lock()
        entered = true
        condition.broadcast()
        while released == false {
            condition.wait()
        }
        condition.unlock()
    }

    func waitUntilEntered() {
        condition.lock()
        while entered == false {
            condition.wait()
        }
        condition.unlock()
    }

    func release() {
        condition.lock()
        released = true
        condition.broadcast()
        condition.unlock()
    }
}

private final class TestSignal: @unchecked Sendable {
    private let condition = NSCondition()
    private var signaled = false

    func signal() {
        condition.lock()
        signaled = true
        condition.broadcast()
        condition.unlock()
    }

    func wait() {
        condition.lock()
        while signaled == false {
            condition.wait()
        }
        condition.unlock()
    }
}

private enum FixtureLoader {
    static func text(named name: String) throws -> String {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "json"))
        return try String(contentsOf: url, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private enum Fixtures {
    static let viewport = try! DesktopViewport(
        id: DesktopViewportID(validating: "primary"),
        width: 1_800,
        height: 1_169,
        depthRange: DesktopDepthRange(minZ: -20, maxZ: 3)
    )
    static let rules = try! DesktopGameRules(
        id: "desktop-platformer",
        revision: 1,
        fixedTickRate: 60,
        gravity: DesktopVector3(x: 0, y: -9.8, z: 0)
    )

    static func planarEnvelope() throws -> DesktopGameEnvelope {
        try DesktopGameEnvelope(
            worldSessionID: DesktopWorldSessionID(validating: "world-1"),
            sequence: 1,
            tick: 10,
            payload: .snapshot(snapshot(avatarZ: 0, objectZ: 0))
        )
    }

    static func snapshot(avatarZ: Double, objectZ: Double) throws -> DesktopGameSnapshot {
        try DesktopGameSnapshot(
            viewport: viewport,
            rules: rules,
            surfaces: [surface()],
            avatars: [avatar(id: "avatar-1", z: avatarZ)],
            objects: [object(id: "object-1", z: objectZ)]
        )
    }

    static func surface() throws -> DesktopGameSurface {
        try DesktopGameSurface(
            id: DesktopSurfaceID(validating: "surface-1"),
            sourceGroupID: DesktopSourceGroupID(validating: "source-alias-9"),
            sourceSide: .minY,
            desktopLayerRank: 7,
            geometry: DesktopExtrudedSegment(
                start: DesktopVector3(x: 20, y: 100, z: 0),
                end: DesktopVector3(x: 900, y: 100, z: 0),
                thickness: 2,
                depthRange: DesktopDepthRange(minZ: -1, maxZ: 1)
            ),
            collisionRoles: [.objectSolid, .playerLanding]
        )
    }

    static func avatar(id: String, z: Double) throws -> DesktopGameAvatar {
        let entityID = try DesktopEntityID(validating: id)
        let hasDepth = z != 0
        let orientation = hasDepth
            ? try DesktopQuaternion(
                x: sin(Double.pi / 8),
                y: 0,
                z: 0,
                w: cos(Double.pi / 8)
            )
            : .identity
        let kinematics = hasDepth
            ? DesktopKinematics3D(
                linearVelocity: try DesktopVector3(x: 0, y: 0, z: -2),
                angularVelocity: try DesktopVector3(x: 0, y: 0.5, z: 0)
            )
            : .stationary
        return try DesktopGameAvatar(
            id: entityID,
            pose: DesktopPose3D(
                position: DesktopVector3(x: 80, y: 120, z: z),
                orientation: orientation
            ),
            kinematics: kinematics,
            facing: DesktopVector3(x: 1, y: 0, z: 0),
            locomotion: DesktopAvatarLocomotion(
                motion: .idle,
                grounded: true,
                supportSurfaceID: try DesktopSurfaceID(validating: "surface-1"),
                remainingAirJumps: 1
            ),
            visual: DesktopAvatarVisual(
                asset: try DesktopAssetReference(
                    id: "stick-figure",
                    revision: "1",
                    contentHash: "sha256:asset"
                ),
                animationClipID: "idle",
                frameID: "fighter_Idle_0001",
                normalizedPhase: nil,
                drawTransform: .identity,
                pickMask: try DesktopPickMaskReference(
                    id: "stick-figure-idle-1",
                    revision: "1",
                    contentHash: "sha256:mask"
                )
            )
        )
    }

    static func object(id: String, z: Double) throws -> DesktopGameObject {
        try DesktopGameObject(
            id: DesktopEntityID(validating: id),
            shape: DesktopObjectShape(
                kind: .circle,
                size: DesktopVector3(x: 48, y: 48, z: 2)
            ),
            pose: DesktopPose3D(
                position: DesktopVector3(x: 400, y: 700, z: z),
                orientation: .identity
            ),
            kinematics: .stationary,
            material: DesktopMaterialReference(id: "rubber", revision: 1)
        )
    }
}
