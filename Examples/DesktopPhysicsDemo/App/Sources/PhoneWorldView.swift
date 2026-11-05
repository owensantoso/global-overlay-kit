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
                        Button("Disconnect") { connection.disconnect() }
                    } else {
                        Button("Connect phone") { connection.connect() }
                            .buttonStyle(.borderedProminent)
                    }
                }
                if connection.enabled {
                    if let url = connection.pairingURL, let image = qrImage(url) {
                        HStack(alignment: .center, spacing: 18) {
                            Image(nsImage: image).interpolation(.none).resizable()
                                .frame(width: 172, height: 172).padding(12).background(.white)
                                .accessibilityLabel("QR code to pair the phone screen")
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Scan with your phone camera.")
                                Text("The phone needs access to your private Tailscale network.")
                                    .font(.callout).foregroundStyle(.secondary)
                                Button("Copy pairing link") {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(url.absoluteString, forType: .string)
                                }
                                Button("New pairing code") { connection.newPairing() }
                            }
                        }
                    }
                    PlacementDiagram(mac: connection.macSize, phone: previewRegion)
                        .frame(height: 180)
                        .accessibilityLabel("Phone placement: \(edgeLabel(connection.edge)) of Mac")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone position").font(.headline)
                        HStack {
                            ForEach(DesktopPhoneEdge.allCases, id: \.self) { edge in
                                Button(edgeLabel(edge)) { connection.edge = edge }
                                    .buttonStyle(.bordered)
                                    .tint(connection.edge == edge ? .accentColor : .secondary)
                                    .accessibilityAddTraits(connection.edge == edge ? .isSelected : [])
                            }
                        }
                    }
                    VStack(spacing: 6) {
                        HStack { Text(alignmentStart); Spacer(); Text(alignmentEnd) }
                            .font(.callout)
                        Slider(value: $connection.alignment, in: 0...1)
                            .accessibilityLabel("Phone alignment")
                        HStack { Text("Smaller world area"); Spacer(); Text("Larger world area") }
                            .font(.callout)
                        Slider(value: $connection.scale, in: 0.2...0.9)
                            .accessibilityLabel("Phone world scale")
                    }
                    Text("Match the diagram to where the phone sits. Rotation follows the phone’s page.")
                        .font(.callout).foregroundStyle(.secondary)
                    HStack {
                        Button("Return character to Mac") { connection.returnToMac() }
                        Spacer()
                        Text("To phone: cross the cyan opening.")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(22)
        }
        .frame(width: 540, height: 640)
    }

    private var previewRegion: CGRect {
        if let region = connection.region { return region }
        let width = connection.macSize.height * connection.scale
        return DesktopPhoneLayout(edge: connection.edge, alignment: connection.alignment,
            width: width, height: width * 1.6).rect(adjacentTo: connection.macSize)
    }
    private var alignmentStart: String {
        connection.edge == .left || connection.edge == .right ? "Bottom aligned" : "Left aligned"
    }
    private var alignmentEnd: String {
        connection.edge == .left || connection.edge == .right ? "Top aligned" : "Right aligned"
    }
    private func edgeLabel(_ edge: DesktopPhoneEdge) -> String {
        switch edge { case .left: "Left"; case .right: "Right"; case .bottom: "Below"; case .top: "Above" }
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

private struct PlacementDiagram: View {
    let mac: CGSize
    let phone: CGRect
    var body: some View {
        GeometryReader { geometry in
            let macRect = CGRect(origin: .zero, size: mac)
            let union = macRect.union(phone).insetBy(dx: -45, dy: -45)
            let scale = min(geometry.size.width / union.width, geometry.size.height / union.height)
            let x = (geometry.size.width - union.width * scale) / 2
            let y = (geometry.size.height - union.height * scale) / 2
            ZStack(alignment: .topLeading) {
                diagramRect(macRect, union: union, scale: scale, x: x, y: y, label: "Mac", phone: false)
                diagramRect(phone, union: union, scale: scale, x: x, y: y, label: "Phone", phone: true)
                Path { path in
                    let vertical = phone.minX == macRect.maxX || phone.maxX == macRect.minX
                    let start: CGPoint
                    let end: CGPoint
                    if vertical {
                        let sx = phone.minX == macRect.maxX ? macRect.maxX : macRect.minX
                        start = CGPoint(x: sx, y: max(phone.minY, macRect.minY))
                        end = CGPoint(x: sx, y: min(phone.maxY, macRect.maxY))
                    } else {
                        let sy = phone.minY == macRect.maxY ? macRect.maxY : macRect.minY
                        start = CGPoint(x: max(phone.minX, macRect.minX), y: sy)
                        end = CGPoint(x: min(phone.maxX, macRect.maxX), y: sy)
                    }
                    path.move(to: CGPoint(x: x + (start.x - union.minX) * scale, y: y + (union.maxY - start.y) * scale))
                    path.addLine(to: CGPoint(x: x + (end.x - union.minX) * scale, y: y + (union.maxY - end.y) * scale))
                }
                .stroke(Color.cyan, lineWidth: 5)
            }
        }
    }
    private func diagramRect(_ rect: CGRect, union: CGRect, scale: CGFloat, x: CGFloat, y: CGFloat, label: String, phone: Bool) -> some View {
        RoundedRectangle(cornerRadius: phone ? 7 : 4)
            .fill(phone ? Color.cyan.opacity(0.16) : Color.secondary.opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: phone ? 7 : 4).stroke(phone ? Color.cyan : Color.secondary, lineWidth: 2))
            .overlay(Text(label).font(.caption.weight(.medium)))
            .frame(width: rect.width * scale, height: rect.height * scale)
            .offset(x: x + (rect.minX - union.minX) * scale, y: y + (union.maxY - rect.maxY) * scale)
    }
}
