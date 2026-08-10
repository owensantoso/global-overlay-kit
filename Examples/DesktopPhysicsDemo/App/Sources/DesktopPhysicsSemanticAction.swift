import Foundation

enum DesktopPhysicsSemanticAction: Equatable {
    static let diagnosticRunIDQueryName = "run_id"

    case spawnRandomObject(diagnosticRunID: String?)

    static func resolve(_ url: URL) -> Self? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "owensantoso-desktopphysics",
              components.host?.lowercased() == "spawn",
              components.path == "/random-object",
              components.user == nil,
              components.password == nil,
              components.port == nil,
              components.fragment == nil else {
            return nil
        }
        guard let queryItems = components.queryItems else {
            return .spawnRandomObject(diagnosticRunID: nil)
        }
        guard queryItems.count == 1,
              queryItems[0].name == diagnosticRunIDQueryName,
              let value = queryItems[0].value,
              let runID = UUID(uuidString: value) else {
            return nil
        }
        return .spawnRandomObject(diagnosticRunID: runID.uuidString.lowercased())
    }
}
