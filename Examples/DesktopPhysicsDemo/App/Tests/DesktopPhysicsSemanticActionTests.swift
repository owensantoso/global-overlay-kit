import Foundation
import XCTest
@testable import DesktopPhysicsDemo

final class DesktopPhysicsSemanticActionTests: XCTestCase {
    func testResolvesSpawnWithNoDiagnosticRunID() {
        let url = URL(
            string: "owensantoso-desktopphysics://spawn/random-object"
        )!

        XCTAssertEqual(
            DesktopPhysicsSemanticAction.resolve(url),
            .spawnRandomObject(diagnosticRunID: nil)
        )
    }

    func testResolvesAndCanonicalizesTheTransportRunID() {
        let url = URL(
            string: "owensantoso-desktopphysics://spawn/random-object?run_id=B7184DB2-F168-4A13-A3E9-FE33C600DBCA"
        )!

        XCTAssertEqual(
            DesktopPhysicsSemanticAction.resolve(url),
            .spawnRandomObject(
                diagnosticRunID: "b7184db2-f168-4a13-a3e9-fe33c600dbca"
            )
        )
    }

    func testRejectsUnknownRoutesAndParameters() {
        let invalidURLs = [
            "desktopphysics://spawn/random-object",
            "owensantoso-desktopphysics://clear/all",
            "owensantoso-desktopphysics://spawn/random-object?mode=random",
            "owensantoso-desktopphysics://spawn/random-object?run_id=not-a-uuid",
            "owensantoso-desktopphysics://spawn/random-object?run_id=B7184DB2-F168-4A13-A3E9-FE33C600DBCA&extra=1",
            "owensantoso-desktopphysics://spawn/random-object#fragment"
        ]

        for value in invalidURLs {
            XCTAssertNil(
                DesktopPhysicsSemanticAction.resolve(URL(string: value)!),
                value
            )
        }
    }
}
