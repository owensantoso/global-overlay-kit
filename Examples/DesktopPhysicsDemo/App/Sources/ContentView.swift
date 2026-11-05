import AppKit
import DesktopPhysicsKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: PhysicsDemoModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Desktop Physics Demo")
                    .font(.title2.weight(.semibold))
                Text("A reusable SpriteKit world rendered above your normal apps.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Label(model.statusText, systemImage: model.overlayIsVisible ? "circle.fill" : "circle")
                .foregroundStyle(model.errorMessage == nil ? Color.primary : Color.red)

            Button("Phone screens…") { openWindow(id: "phone") }

            GroupBox("Spawn objects") {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Shape", selection: $model.selectedShape) {
                        ForEach(DesktopPhysicsShape.allCases, id: \.self) { shape in
                            Text(shape.rawValue.capitalized).tag(shape)
                        }
                    }

                    Toggle("Randomize object size", isOn: $model.randomizeObjectSize)

                    if model.randomizeObjectSize {
                        HStack {
                            Text("Size range")
                            Spacer()
                            Text("\(format(model.randomMinimumDiameter))–\(format(model.randomMaximumDiameter)) pt")
                                .foregroundStyle(.secondary)
                        }
                        RangeSlider(
                            lowerValue: $model.randomMinimumDiameter,
                            upperValue: $model.randomMaximumDiameter,
                            bounds: 1...model.maximumObjectDiameter
                        )
                    } else {
                        HStack {
                            Text("Object size")
                            Slider(
                                value: $model.objectDiameter,
                                in: 1...model.maximumObjectDiameter
                            )
                            Text("\(format(model.objectDiameter)) pt")
                                .monospacedDigit()
                                .frame(width: 54, alignment: .trailing)
                        }
                    }
                    HStack {
                        Button("Spawn") { model.spawnObject() }
                        Button("Clear") { model.clearObjects() }
                            .disabled(model.objectCount == 0)
                        Button(model.overlayIsVisible ? "Hide Overlay" : "Show Overlay") {
                            model.toggleOverlay()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            GroupBox("Interaction") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Game world mode", isOn: Binding(
                        get: { model.gameWorldModeEnabled },
                        set: { model.setGameWorldModeEnabled($0) }
                    ))

                    Toggle("Use app windows as platforms", isOn: Binding(
                        get: { model.windowPlatformsEnabled },
                        set: { model.setWindowPlatformsEnabled($0) }
                    ))

                    Toggle("Show platform outlines", isOn: Binding(
                        get: { model.windowPlatformOutlinesVisible },
                        set: { model.setWindowPlatformOutlinesVisible($0) }
                    ))
                    .disabled(!model.windowPlatformsEnabled)

                    Toggle("Character lands on top and bottom edges", isOn: Binding(
                        get: { model.playerWindowCollisionEnabled },
                        set: { model.setPlayerWindowCollisionEnabled($0) }
                    ))
                    .disabled(!model.windowPlatformsEnabled)

                    Toggle("Use left and right edges as walls", isOn: Binding(
                        get: { model.playerWindowSideCollisionEnabled },
                        set: { model.setPlayerWindowSideCollisionEnabled($0) }
                    ))
                    .disabled(!model.windowPlatformsEnabled)

                    if model.windowPlatformsEnabled {
                        Label(
                            windowPlatformSummary,
                            systemImage: "macwindow.on.rectangle"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        Text("Fully covered window areas are removed using front-to-back rectangular occlusion.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if model.windowPlatformOutlinesVisible {
                            Text("Cyan = visible object collider · yellow = one-way landing edges")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(model.windowPlatformMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Cursor pushes objects", isOn: Binding(
                        get: { model.cursorCollisionEnabled },
                        set: { model.setCursorCollisionEnabled($0) }
                    ))

                    Toggle("Click and drag objects and player", isOn: Binding(
                        get: { model.objectDraggingEnabled },
                        set: { model.setObjectDraggingEnabled($0) }
                    ))

                    if model.objectDraggingEnabled {
                        Label(
                            "DRAG MODE ON — object/player hit regions capture clicks",
                            systemImage: "hand.draw.fill"
                        )
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.orange)
                    }

                    HStack {
                        Text("Cursor hitbox")
                        Slider(
                            value: Binding(
                                get: { model.cursorColliderDiameter },
                                set: { model.setCursorColliderDiameter($0) }
                            ),
                            in: 1...model.maximumObjectDiameter
                        )
                        Text("\(format(model.cursorColliderDiameter)) pt")
                            .monospacedDigit()
                            .frame(width: 54, alignment: .trailing)
                    }

                    HStack {
                        Picker("Player", selection: $model.selectedPlayerAppearance) {
                            ForEach(DesktopPlayerAppearance.allCases, id: \.self) { appearance in
                                Text(appearance.displayName).tag(appearance)
                            }
                        }

                        Button(model.hasPlayer ? "Replace player" : "Spawn player") {
                            model.spawnPlayer()
                        }
                    }
                    HStack {
                        Text("Jump height")
                        Slider(
                            value: Binding(
                                get: { model.playerJumpHeight },
                                set: { model.setPlayerJumpHeight($0) }
                            ),
                            in: 40...model.maximumPlayerJumpHeight
                        )
                        Text("\(format(model.playerJumpHeight)) pt")
                            .monospacedDigit()
                            .frame(width: 62, alignment: .trailing)
                    }

                    HStack {
                        Picker(
                            "Controls",
                            selection: Binding(
                                get: { model.controlScheme },
                                set: { model.setControlScheme($0) }
                            )
                        ) {
                            ForEach(DesktopGameControlScheme.allCases, id: \.self) { scheme in
                                Text(scheme.displayName).tag(scheme)
                            }
                        }

                        Button(model.controlsEnabled ? "Turn Controls Off" : "Turn Controls On") {
                            model.toggleControls()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(model.controlsEnabled ? .red : .accentColor)
                    }

                    Toggle("Spacebar jumps", isOn: Binding(
                        get: { model.spacebarJumpEnabled },
                        set: { model.setSpacebarJumpEnabled($0) }
                    ))

                    if model.controlsEnabled {
                        Label(controlSummary, systemImage: "keyboard.fill")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.orange)
                        Text("Jump once more in mid-air for a double jump. With side walls on, double-tap toward a wall and hold the second press to wall-run.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if !model.accessibilityTrusted {
                        Text("Global controls need Accessibility access. Turning them on requests it; they stay off until macOS grants it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(footerText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            HStack {
                if let controlMessage = model.controlMessage {
                    Text(controlMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Quit Demo") {
                    model.stop()
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .frame(width: 480)
        .padding(20)
        .background(ControlWindowLevelGuard())
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.refreshSystemState()
            }
        }
    }

    private func format(_ value: CGFloat) -> String {
        String(Int(value.rounded()))
    }

    private var controlSummary: String {
        let space = model.spacebarJumpEnabled ? "/Space" : ""
        return switch model.controlScheme {
        case .wasd:
            "CONTROLS ON — A/D move · Shift runs · W\(space) jumps · S+Jump drops · C sits"
        case .arrows:
            "CONTROLS ON — Left/Right move · Shift runs · Up\(space) jumps · Down+Jump drops · C sits"
        case .both:
            "CONTROLS ON — A/D or arrows move · Shift runs · W/Up\(space) jumps · Down+Jump drops · C sits"
        }
    }

    private var windowPlatformSummary: String {
        let noun = model.windowPlatformCount == 1 ? "visible region" : "visible regions"
        let sides = model.playerWindowSideCollisionEnabled
            ? "; visible left/right edges are player walls"
            : ""
        return "\(model.windowPlatformCount) \(noun): solid for objects; top and bottom are one-way player platforms\(sides)."
    }

    private var footerText: String {
        if model.objectDraggingEnabled {
            "Drag mode captures clicks only over an object or the player; empty desktop stays click-through. Command-modified shortcuts, including Command-Tab, are never captured."
        } else {
            "The overlay is click-through. Drag mode captures only object/player hit regions. Command-modified shortcuts, including Command-Tab, are never captured. Reopen this window from the Dock or with Command-0."
        }
    }
}

private struct ControlWindowLevelGuard: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        ControlWindowLevelView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class ControlWindowLevelView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.level = NSWindow.Level(
            rawValue: NSWindow.Level.floating.rawValue + 1
        )
    }
}

private struct RangeSlider: View {
    private enum ActiveHandle {
        case lower
        case upper
    }

    @Binding var lowerValue: CGFloat
    @Binding var upperValue: CGFloat
    let bounds: ClosedRange<CGFloat>
    @State private var activeHandle: ActiveHandle?

    var body: some View {
        GeometryReader { geometry in
            let width = max(1, geometry.size.width)
            let lowerX = xPosition(for: lowerValue, width: width)
            let upperX = xPosition(for: upperValue, width: width)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(height: 4)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(0, upperX - lowerX), height: 4)
                    .offset(x: lowerX)
                handle(
                    value: lowerValue,
                    label: "Minimum object size"
                )
                .position(x: lowerX, y: geometry.size.height / 2)
                handle(
                    value: upperValue,
                    label: "Maximum object size"
                )
                .position(x: upperX, y: geometry.size.height / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        if activeHandle == nil {
                            activeHandle = abs(gesture.startLocation.x - lowerX)
                                <= abs(gesture.startLocation.x - upperX)
                                ? .lower : .upper
                        }
                        let value = valueAt(x: gesture.location.x, width: width)
                        if activeHandle == .lower {
                            lowerValue = min(value, upperValue)
                        } else {
                            upperValue = max(value, lowerValue)
                        }
                    }
                    .onEnded { _ in
                        activeHandle = nil
                    }
            )
        }
        .frame(height: 24)
    }

    private func handle(
        value: CGFloat,
        label: String
    ) -> some View {
        Circle()
            .fill(Color.accentColor)
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .frame(width: 16, height: 16)
            .accessibilityLabel(label)
            .accessibilityValue("\(Int(value.rounded())) points")
    }

    private func xPosition(for value: CGFloat, width: CGFloat) -> CGFloat {
        let span = max(1, bounds.upperBound - bounds.lowerBound)
        return (value - bounds.lowerBound) / span * width
    }

    private func valueAt(x: CGFloat, width: CGFloat) -> CGFloat {
        let ratio = min(max(x / max(1, width), 0), 1)
        return bounds.lowerBound + ratio * (bounds.upperBound - bounds.lowerBound)
    }
}
