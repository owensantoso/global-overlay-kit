import AppKit
import SwiftUI

@main
@MainActor
struct DesktopPhysicsDemoApp: App {
    @NSApplicationDelegateAdaptor(DemoAppDelegate.self)
    private var appDelegate

    @StateObject private var model = PhysicsDemoModel.shared

    var body: some Scene {
        WindowGroup("Desktop Physics Demo", id: "main") {
            ContentView(model: model)
                .onAppear {
                    model.startIfNeeded()
                }
        }
        .windowResizability(.contentSize)

        .commands {
            DemoCommands()
        }
    }
}

@MainActor
private final class DemoAppDelegate: NSObject, NSApplicationDelegate {
    private var semanticActionObserver: NSObjectProtocol?

    func applicationWillFinishLaunching(_ notification: Notification) {
        semanticActionObserver = DistributedNotificationCenter.default().addObserver(
            forName: SemanticActionTransportNotification.name,
            object: Bundle.main.bundleIdentifier,
            queue: .main
        ) { notification in
            guard let value = notification.userInfo?[
                SemanticActionTransportNotification.urlKey
            ] as? String,
                  let url = URL(string: value) else {
                return
            }
            Task { @MainActor in
                PhysicsDemoModel.shared.performSemanticAction(url)
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        let now = ActionLatencyDiagnostics.monotonicNanoseconds()
        ActionLatencyDiagnostics.logger.info(
            "event=application.did_finish_launching monotonic_ns=\(now, privacy: .public)"
        )
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            PhysicsDemoModel.shared.performSemanticAction(url)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let semanticActionObserver {
            DistributedNotificationCenter.default().removeObserver(
                semanticActionObserver
            )
        }
    }
}

private struct DemoCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .windowArrangement) {
            Button("Show Desktop Physics Controls") {
                openWindow(id: "main")
            }
            .keyboardShortcut("0", modifiers: .command)
        }
    }
}
