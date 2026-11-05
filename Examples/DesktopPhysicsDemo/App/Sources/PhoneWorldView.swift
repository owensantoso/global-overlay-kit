import AppKit
import CoreImage.CIFilterBuiltins
import DesktopPhysicsKit
import SwiftUI

struct PhoneWorldView: View {
    @ObservedObject var connection: PhoneWorldConnection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(connection.status).font(.headline)
                    Spacer()
                    if connection.enabled {
                        Button("Disconnect all phones") { connection.disconnect() }
                    } else {
                        Button("Connect phones") { connection.connect() }.buttonStyle(.borderedProminent)
                    }
                }
                if connection.enabled {
                    pairing
                    PhoneArrangementCanvas(connection: connection)
                        .frame(height: 380)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    selection
                    Text(connection.layoutMessage ?? "Drag screens together until their edges snap. Arrow keys slide the selected screen along its edge.")
                        .font(.callout).foregroundStyle(.secondary)
                    Button("Return character to Mac") { connection.returnToMac() }
                }
            }
            .padding(22)
        }
        .frame(width: 780, height: 720)
    }

    @ViewBuilder private var pairing: some View {
        if let url = connection.pairingURL, let image = qrImage(url) {
            HStack(spacing: 18) {
                Image(nsImage: image).interpolation(.none).resizable()
                    .frame(width: 136, height: 136).padding(10).background(.white)
                    .accessibilityLabel("QR code to join this world from another phone")
                VStack(alignment: .leading, spacing: 10) {
                    Text("Scan this code on each phone.")
                    Text("Use your private Tailscale network.")
                        .font(.callout).foregroundStyle(.secondary)
                    HStack {
                        Button("Copy pairing link") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(url.absoluteString, forType: .string)
                        }
                        Button("Reset all pairings") { connection.newPairing() }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder private var selection: some View {
        if let item = connection.phones.first(where: { $0.id == connection.selectedID }) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.label).font(.headline)
                    Text(connection.stateText(for: item)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("Scale")
                Slider(value: Binding(get: { connection.scale(for: item.id) },
                    set: { connection.setScale($0, for: item.id) }), in: 0.2...0.9)
                    .frame(width: 180).accessibilityLabel("\(item.label) world scale")
                Button("Rotate view") { connection.rotateScreen(item.id) }
                Button("Remove phone") { connection.removePhone(item.id) }
            }
        } else {
            Text(connection.phones.isEmpty ? "Paired phones appear here." : "Select a phone to adjust its scale.")
                .font(.callout).foregroundStyle(.secondary)
        }
    }

    private func qrImage(_ url: URL) -> NSImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let rep = NSCIImageRep(ciImage: output.transformed(by: CGAffineTransform(scaleX: 8, y: 8)))
        let image = NSImage(size: rep.size); image.addRepresentation(rep)
        return image
    }
}

private struct ArrangementProjection {
    let world: CGRect
    let scale: CGFloat
    let offset: CGPoint

    init(mac: CGSize, phones: [PhoneScreenItem], size: CGSize) {
        let margin = max(250, phones.map { max($0.screen.width, $0.screen.height) }.max() ?? 400) + 40
        let bounds = phones.reduce(CGRect(origin: .zero, size: mac)) { $0.union($1.screen.rect) }.insetBy(dx: -margin, dy: -margin)
        world = bounds
        scale = max(0.01, min(size.width / bounds.width, size.height / bounds.height))
        offset = CGPoint(x: (size.width - bounds.width * scale) / 2,
            y: (size.height - bounds.height * scale) / 2)
    }
    func point(_ point: CGPoint) -> CGPoint {
        CGPoint(x: offset.x + (point.x - world.minX) * scale,
            y: offset.y + (world.maxY - point.y) * scale)
    }
    func frame(_ rect: CGRect) -> CGRect {
        CGRect(origin: point(CGPoint(x: rect.minX, y: rect.maxY)),
            size: CGSize(width: rect.width * scale, height: rect.height * scale))
    }
}

private struct PhoneArrangementCanvas: View {
    @ObservedObject var connection: PhoneWorldConnection
    @FocusState private var focusedID: String?
    @State private var drag: ScreenDrag?
    @State private var resize: ScreenResize?
    @State private var dragCancelled = false
    @GestureState private var gestureActive = false

    private struct ScreenDrag {
        let id: String
        let original: DesktopPhoneScreen
        let projection: ArrangementProjection
        let viewport: CGSize
        var proposed: DesktopPhoneScreen
        var snapped: DesktopPhoneScreen?
    }

    private struct ScreenResize {
        let id: String
        let original: DesktopPhoneScreen
        let viewport: CGSize
        let projection: ArrangementProjection
        let startScale: Double
        let directions: CGPoint
        var scale: Double
        var preview: PhoneResizePreview?
    }

    var body: some View {
        GeometryReader { geometry in
            let projection = resize?.projection ?? drag?.projection ?? ArrangementProjection(mac: connection.macSize,
                phones: connection.phones, size: geometry.size)
            ZStack(alignment: .topLeading) {
                macTile(projection: projection)
                seamPaths(projection: projection)
                ForEach(connection.phones) { item in
                    phoneTile(item, projection: projection)
                    if connection.selectedID == item.id, connection.activeScreenIDs.contains(item.id), drag == nil {
                        resizeHandle(item, projection: projection)
                    }
                }
                if let drag, let item = connection.phones.first(where: { $0.id == drag.id }) {
                    ghost(item, drag: drag)
                    ghostOpenings(drag)
                }
                if let resize { resizeGhosts(resize) }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .coordinateSpace(name: "phone-arrangement")
            .onExitCommand {
                if drag != nil || resize != nil { drag = nil; resize = nil; dragCancelled = true }
            }
            .onChange(of: gestureActive) { _, active in
                if !active { drag = nil; resize = nil; dragCancelled = false }
            }
            .onChange(of: connection.phones) { _, phones in
                if let drag {
                    let current = phones.first { $0.id == drag.id }
                    if current?.connected != true || current?.screen != drag.original || current?.viewport != drag.viewport {
                        self.drag = nil; dragCancelled = true
                    }
                }
                if let resize {
                    let current = phones.first { $0.id == resize.id }
                    if current?.connected != true || current?.screen != resize.original || current?.viewport != resize.viewport {
                        self.resize = nil; dragCancelled = true
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Screen arrangement")
    }

    private func macTile(projection: ArrangementProjection) -> some View {
        let frame = projection.frame(CGRect(origin: .zero, size: connection.macSize))
        return RoundedRectangle(cornerRadius: 6)
            .fill(Color.secondary.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.5), lineWidth: 1.5))
            .overlay(Text("Mac").font(.callout.weight(.medium)))
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY)
            .accessibilityLabel("Mac, fixed screen")
    }

    private func seamPaths(projection: ArrangementProjection) -> some View {
        let active = connection.phones.filter { connection.activeScreenIDs.contains($0.id) }.map(\.screen)
        let seams = DesktopPhonePlacement.seams(macSize: connection.macSize, screens: active)
        return Path { path in
            for seam in seams {
                path.move(to: projection.point(CGPoint(x: seam.x1, y: seam.y1)))
                path.addLine(to: projection.point(CGPoint(x: seam.x2, y: seam.y2)))
            }
        }.stroke(Color.cyan, lineWidth: 5).allowsHitTesting(false)
    }

    private func phoneTile(_ item: PhoneScreenItem, projection: ArrangementProjection) -> some View {
        let frame = projection.frame(item.screen.rect)
        let selected = connection.selectedID == item.id
        let active = connection.activeScreenIDs.contains(item.id)
        return RoundedRectangle(cornerRadius: 7)
            .fill(active ? Color.cyan.opacity(0.1) : Color.secondary.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(selected ? Color.accentColor : Color.secondary,
                style: StrokeStyle(lineWidth: selected ? 2.5 : 1.5, dash: active ? [] : [4, 3])))
            .overlay(alignment: .center) {
                VStack(spacing: 3) {
                    Text(item.label).font(.system(size: 11, weight: .medium)).lineLimit(1).minimumScaleFactor(0.8)
                    if item.screen.rotation == 90 { Text("90°").font(.system(size: 9)) }
                    if !active { Text(connection.stateText(for: item)).font(.system(size: 9)).multilineTextAlignment(.center) }
                }.padding(4).allowsHitTesting(false)
            }
            .frame(width: frame.width, height: frame.height)
            .contentShape(Rectangle())
            .opacity(isEditing(item) ? 0.25 : 1)
            .offset(x: frame.minX, y: frame.minY)
            .focusable()
            .focused($focusedID, equals: item.id)
            .onTapGesture { connection.selectedID = item.id; focusedID = item.id }
            .onMoveCommand { connection.nudgeScreen(item.id, direction: $0) }
            .gesture(dragGesture(item, projection: projection))
            .accessibilityLabel(item.label)
            .accessibilityValue(connection.stateText(for: item))
            .accessibilityHint("Drag against a connected edge. Arrow keys slide along an edge; Shift moves farther.")
            .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func dragGesture(_ item: PhoneScreenItem, projection: ArrangementProjection) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named("phone-arrangement"))
            .updating($gestureActive) { _, active, _ in active = true }
            .onChanged { value in
                guard !dragCancelled else { return }
                connection.selectedID = item.id
                focusedID = item.id
                let start = drag.flatMap { $0.id == item.id ? $0 : nil }
                    ?? ScreenDrag(id: item.id, original: item.screen, projection: projection,
                        viewport: item.viewport, proposed: item.screen, snapped: item.screen)
                let rect = start.original.rect.offsetBy(dx: value.translation.width / start.projection.scale,
                    dy: -value.translation.height / start.projection.scale)
                let proposed = DesktopPhoneScreen(id: item.id, rect: rect)
                drag = ScreenDrag(id: start.id, original: start.original, projection: start.projection,
                    viewport: start.viewport, proposed: proposed,
                    snapped: connection.snappedScreen(proposed, maxDistance: min(120, 32 / start.projection.scale)))
            }
            .onEnded { value in
                defer { self.drag = nil; dragCancelled = false }
                guard !dragCancelled else { return }
                guard let drag, drag.id == item.id else { return }
                guard let current = connection.phones.first(where: { $0.id == item.id }),
                      current.connected, current.screen == drag.original, current.viewport == drag.viewport else { return }
                let rect = drag.original.rect.offsetBy(dx: value.translation.width / drag.projection.scale,
                    dy: -value.translation.height / drag.projection.scale)
                connection.moveScreen(DesktopPhoneScreen(id: item.id, rect: rect), maxDistance: min(120, 32 / drag.projection.scale))
            }
    }

    private func isEditing(_ item: PhoneScreenItem) -> Bool {
        if drag?.id == item.id || resize?.id == item.id { return true }
        return resize?.preview?.screens.first(where: { $0.id == item.id }).map { $0.rect != item.screen.rect } ?? false
    }

    private func resizeHandle(_ item: PhoneScreenItem, projection: ArrangementProjection) -> some View {
        let frame = projection.frame(item.screen.rect)
        let directions = connection.resizeDirections(for: item.id)
        return Text("Resize").font(.system(size: 8, weight: .medium))
            .frame(width: 38, height: 18)
            .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 3))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.accentColor, lineWidth: 1))
            .contentShape(Rectangle())
            .offset(x: directions.x > 0 ? frame.maxX - 40 : frame.minX + 2,
                y: directions.y > 0 ? frame.minY + 2 : frame.maxY - 20)
            .gesture(resizeGesture(item, projection: projection, directions: directions))
            .accessibilityLabel("Resize \(item.label)")
            .accessibilityHint("The selected screen's Scale slider also changes its size.")
    }

    private func resizeGesture(_ item: PhoneScreenItem, projection: ArrangementProjection, directions: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named("phone-arrangement"))
            .updating($gestureActive) { _, active, _ in active = true }
            .onChanged { value in
                guard !dragCancelled else { return }
                let start = resize ?? ScreenResize(id: item.id, original: item.screen, viewport: item.viewport,
                    projection: projection, startScale: connection.scale(for: item.id), directions: directions,
                    scale: connection.scale(for: item.id), preview: nil)
                let dx = value.translation.width * start.directions.x / (start.original.width * start.projection.scale)
                let dy = -value.translation.height * start.directions.y / (start.original.height * start.projection.scale)
                let factor = max(0.1, 1 + (abs(dx) >= abs(dy) ? dx : dy))
                let scale = min(0.9, max(0.2, start.startScale * factor))
                resize = ScreenResize(id: start.id, original: start.original, viewport: start.viewport,
                    projection: start.projection, startScale: start.startScale, directions: start.directions,
                    scale: scale, preview: connection.resizePreview(scale, for: item.id))
            }
            .onEnded { _ in
                defer { resize = nil; dragCancelled = false }
                guard !dragCancelled, let resize,
                      let current = connection.phones.first(where: { $0.id == resize.id }), current.connected,
                      current.screen == resize.original, current.viewport == resize.viewport,
                      connection.resizePreview(resize.scale, for: resize.id) != nil else { return }
                connection.setScale(resize.scale, for: resize.id)
            }
    }

    @ViewBuilder private func resizeGhosts(_ resize: ScreenResize) -> some View {
        if let preview = resize.preview {
            ForEach(preview.screens.filter { screen in
                screen.id == resize.id || connection.phones.first(where: { $0.id == screen.id })?.screen.rect != screen.rect
            }, id: \.id) { screen in
                let item = connection.phones.first { $0.id == screen.id }
                let drag = ScreenDrag(id: screen.id, original: screen, projection: resize.projection,
                    viewport: resize.viewport, proposed: screen, snapped: screen)
                if let item { ghost(item, drag: drag) }
            }
        } else if let item = connection.phones.first(where: { $0.id == resize.id }) {
            let drag = ScreenDrag(id: resize.id, original: resize.original, projection: resize.projection,
                viewport: resize.viewport, proposed: resize.original, snapped: nil)
            ghost(item, drag: drag)
        }
    }

    private func ghost(_ item: PhoneScreenItem, drag: ScreenDrag) -> some View {
        let screen = drag.snapped ?? drag.proposed
        let frame = drag.projection.frame(screen.rect)
        return RoundedRectangle(cornerRadius: 7)
            .fill(Color(nsColor: .windowBackgroundColor).opacity(0.95))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(drag.snapped == nil ? Color.orange : Color.accentColor, lineWidth: 3))
            .overlay {
                VStack(spacing: 4) {
                    Text(item.label).font(.caption.weight(.semibold))
                    Text(drag.snapped == nil ? "Connect an edge" : "Drop here").font(.system(size: 9)).multilineTextAlignment(.center)
                }.padding(3)
            }
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.minX, y: frame.minY)
            .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func ghostOpenings(_ drag: ScreenDrag) -> some View {
        let screens = connection.phones.filter { connection.activeScreenIDs.contains($0.id) && $0.id != drag.id }.map(\.screen)
            + (drag.snapped.map { [$0] } ?? [])
        let seams = DesktopPhonePlacement.seams(macSize: connection.macSize, screens: screens)
            .filter { $0.from == drag.id || $0.to == drag.id }
        return Path { path in
            for seam in seams {
                path.move(to: drag.projection.point(CGPoint(x: seam.x1, y: seam.y1)))
                path.addLine(to: drag.projection.point(CGPoint(x: seam.x2, y: seam.y2)))
            }
        }.stroke(Color.cyan, lineWidth: 6).allowsHitTesting(false).accessibilityHidden(true)
    }
}
