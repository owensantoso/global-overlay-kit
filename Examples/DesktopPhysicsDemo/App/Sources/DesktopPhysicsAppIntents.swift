import AppIntents
import Foundation

struct SpawnRandomObjectIntent: AppIntent {
    static let title: LocalizedStringResource = "Spawn Random Object"
    static let description = IntentDescription(
        "Spawns one random object in the desktop physics world."
    )
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult {
        let runID = UUID().uuidString.lowercased()
        let startedAt = ActionLatencyDiagnostics.monotonicNanoseconds()
        let signpostID = ActionLatencyDiagnostics.signposter.makeSignpostID()
        let interval = ActionLatencyDiagnostics.signposter.beginInterval(
            "SpawnRandomObjectIntent",
            id: signpostID,
            "run_id=\(runID, privacy: .public)"
        )
        ActionLatencyDiagnostics.logger.info(
            "event=intent.perform.started run_id=\(runID, privacy: .public) monotonic_ns=\(startedAt, privacy: .public)"
        )

        do {
            let objectCount = try PhysicsDemoModel.shared.spawnRandomObject(
                diagnosticRunID: runID
            )
            let completedAt = ActionLatencyDiagnostics.monotonicNanoseconds()
            let duration = ActionLatencyDiagnostics.milliseconds(
                from: startedAt,
                to: completedAt
            )
            ActionLatencyDiagnostics.logger.info(
                "event=intent.perform.completed run_id=\(runID, privacy: .public) monotonic_ns=\(completedAt, privacy: .public) duration_ms=\(duration, privacy: .public) object_count=\(objectCount, privacy: .public)"
            )
            ActionLatencyDiagnostics.signposter.endInterval(
                "SpawnRandomObjectIntent",
                interval,
                "run_id=\(runID, privacy: .public) outcome=ok"
            )
            return .result()
        } catch {
            let failedAt = ActionLatencyDiagnostics.monotonicNanoseconds()
            let duration = ActionLatencyDiagnostics.milliseconds(
                from: startedAt,
                to: failedAt
            )
            ActionLatencyDiagnostics.logger.error(
                "event=intent.perform.failed run_id=\(runID, privacy: .public) monotonic_ns=\(failedAt, privacy: .public) duration_ms=\(duration, privacy: .public) error=\(error.localizedDescription, privacy: .public)"
            )
            ActionLatencyDiagnostics.signposter.endInterval(
                "SpawnRandomObjectIntent",
                interval,
                "run_id=\(runID, privacy: .public) outcome=failed"
            )
            throw error
        }
    }
}

struct DesktopPhysicsAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SpawnRandomObjectIntent(),
            phrases: [
                "Spawn a random object in \(.applicationName)",
                "Drop a random object with \(.applicationName)"
            ],
            shortTitle: "Spawn Random Object",
            systemImageName: "circle.hexagongrid.fill"
        )
    }
}
