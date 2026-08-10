import Testing
@testable import DesktopGameCore

@Suite("Portable interaction policies")
struct DesktopGameCorePolicyTests {
    @Test("Painted selection chooses the frontmost draggable painted candidate")
    func paintedSelectionUsesCoverageAndLayering() throws {
        let selected = DesktopPaintedCandidateSelection.frontmost(
            in: [
                DesktopPaintedCandidate(
                    entityID: try DesktopEntityID(validating: "front-transparent"),
                    frontToBackRank: 0,
                    isDraggable: true,
                    isPaintedAtPoint: false
                ),
                DesktopPaintedCandidate(
                    entityID: try DesktopEntityID(validating: "front-painted-not-draggable"),
                    frontToBackRank: 1,
                    isDraggable: false,
                    isPaintedAtPoint: true
                ),
                DesktopPaintedCandidate(
                    entityID: try DesktopEntityID(validating: "chosen"),
                    frontToBackRank: 2,
                    isDraggable: true,
                    isPaintedAtPoint: true
                ),
                DesktopPaintedCandidate(
                    entityID: try DesktopEntityID(validating: "back"),
                    frontToBackRank: 3,
                    isDraggable: true,
                    isPaintedAtPoint: true
                )
            ]
        )

        #expect(selected == (try DesktopEntityID(validating: "chosen")))
    }

    @Test("Equal painted ranks resolve by entity ID independent of input order")
    func paintedSelectionTieIsDeterministic() throws {
        let first = DesktopPaintedCandidate(
            entityID: try DesktopEntityID(validating: "avatar-a"),
            frontToBackRank: 2,
            isDraggable: true,
            isPaintedAtPoint: true
        )
        let second = DesktopPaintedCandidate(
            entityID: try DesktopEntityID(validating: "avatar-b"),
            frontToBackRank: 2,
            isDraggable: true,
            isPaintedAtPoint: true
        )

        #expect(
            DesktopPaintedCandidateSelection.frontmost(in: [first, second])
                == first.entityID
        )
        #expect(
            DesktopPaintedCandidateSelection.frontmost(in: [second, first])
                == first.entityID
        )
    }

    @Test("Toward-wall jump excludes every coincident feature on the contacted plane")
    func towardWallJumpBeginsCoincidentPlaneTraversal() throws {
        let featureID = try DesktopSurfaceID(validating: "left-edge")
        let contact = try DesktopWallContact(
            featureID: featureID,
            directionFromPlayer: .negativeX,
            planeX: 100
        )

        let decision = try DesktopWallTraversalPolicy.jumpDecision(
            contact: contact,
            horizontalIntent: .negativeX,
            jumpPressed: true,
            coincidentTolerance: 0.25
        )
        let state = try #require(decision.traversalState)
        let coincident = try DesktopWallContact(
            featureID: DesktopSurfaceID(validating: "same-plane-edge"),
            directionFromPlayer: .negativeX,
            planeX: 100.2
        )
        let distinctPlane = try DesktopWallContact(
            featureID: DesktopSurfaceID(validating: "distinct-plane-edge"),
            directionFromPlayer: .negativeX,
            planeX: 100.3
        )
        let oppositeDirection = try DesktopWallContact(
            featureID: DesktopSurfaceID(validating: "opposite-edge"),
            directionFromPlayer: .positiveX,
            planeX: 100
        )

        #expect(decision.kind == .traverse)
        #expect(state.excludes(contact))
        #expect(state.excludes(coincident))
        #expect(state.excludes(distinctPlane) == false)
        #expect(state.excludes(oppositeDirection))
    }

    @Test("Traversal remains active after center crossing until full bounds clear")
    func traversalSurvivesCenterDirectionFlip() throws {
        let state = try DesktopWallTraversalState(
            featureID: DesktopSurfaceID(validating: "left-edge"),
            direction: .negativeX,
            planeX: 100,
            coincidentTolerance: 0.25
        )
        let flippedContact = try DesktopWallContact(
            featureID: DesktopSurfaceID(validating: "same-plane-after-crossing"),
            directionFromPlayer: .positiveX,
            planeX: 100.1
        )
        let straddlingBounds = try DesktopHorizontalBounds(minX: 95, maxX: 105)

        #expect(state.excludes(flippedContact))
        #expect(state.shouldClear(previousBounds: straddlingBounds) == false)
        #expect(
            state.shouldClear(
                previousBounds: try DesktopHorizontalBounds(minX: 80, maxX: 99)
            )
        )
    }

    @Test("Away and neutral jumps remain ordinary outward wall jumps")
    func awayAndNeutralStayOutward() throws {
        let contact = try DesktopWallContact(
            featureID: DesktopSurfaceID(validating: "left-edge"),
            directionFromPlayer: .negativeX,
            planeX: 100
        )

        for intent in [DesktopHorizontalDirection.neutral, .positiveX] {
            let decision = try DesktopWallTraversalPolicy.jumpDecision(
                contact: contact,
                horizontalIntent: intent,
                jumpPressed: true
            )
            #expect(decision.kind == .outwardWallJump)
            #expect(decision.traversalState == nil)
        }
    }

    @Test("Clearance is symmetric and uses previous-frame full bounds")
    func traversalClearanceIsSymmetric() throws {
        let left = try DesktopWallTraversalState(
            featureID: DesktopSurfaceID(validating: "left"),
            direction: .negativeX,
            planeX: 100
        )
        let right = try DesktopWallTraversalState(
            featureID: DesktopSurfaceID(validating: "right"),
            direction: .positiveX,
            planeX: 100
        )

        #expect(left.shouldClear(previousBounds: try DesktopHorizontalBounds(minX: 70, maxX: 99)))
        #expect(left.shouldClear(previousBounds: try DesktopHorizontalBounds(minX: 70, maxX: 101)) == false)
        #expect(right.shouldClear(previousBounds: try DesktopHorizontalBounds(minX: 101, maxX: 130)))
        #expect(right.shouldClear(previousBounds: try DesktopHorizontalBounds(minX: 99, maxX: 130)) == false)
    }
}
