import AppKit

enum SundialGlyph {
    static let menuBarImage: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.addPath(path(in: rect))
            context.setFillColor(NSColor.black.cgColor)
            context.fillPath()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Sundial"
        return image
    }()

    static func path(in rect: CGRect) -> CGPath {
        let width = rect.width
        let height = rect.height
        let plate = CGRect(x: rect.minX + width * 0.06, y: rect.minY + height * 0.08, width: width * 0.88, height: height * 0.38)
        let ring = CGPath(ellipseIn: plate, transform: nil)
            .copy(strokingWithWidth: width * 0.10, lineCap: .round, lineJoin: .round, miterLimit: 10)
        let gnomon = CGMutablePath()
        gnomon.move(to: CGPoint(x: plate.midX - width * 0.30, y: plate.midY))
        gnomon.addLine(to: CGPoint(x: plate.midX + width * 0.07, y: rect.minY + height * 0.97))
        gnomon.addLine(to: CGPoint(x: plate.midX + width * 0.07, y: plate.midY))
        gnomon.closeSubpath()
        let shadow = CGMutablePath()
        shadow.move(to: CGPoint(x: plate.midX - width * 0.10, y: plate.midY))
        shadow.addLine(to: CGPoint(x: plate.midX + width * 0.07, y: plate.midY))
        shadow.addLine(to: CGPoint(x: plate.maxX - width * 0.12, y: plate.minY + height * 0.10))
        shadow.closeSubpath()
        return ring.union(gnomon).union(shadow)
    }
}
