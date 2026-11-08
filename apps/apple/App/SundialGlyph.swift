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
        let unit = rect.width / 18
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * unit, y: rect.minY + y * unit)
        }
        func outline(_ path: CGPath, _ width: CGFloat) -> CGPath {
            path.copy(strokingWithWidth: width * unit, lineCap: .round, lineJoin: .round, miterLimit: 10)
        }
        let dial = CGRect(x: rect.minX + 1.4 * unit, y: rect.minY + 1.4 * unit, width: 15.2 * unit, height: 15.2 * unit)
        let ring = outline(CGPath(ellipseIn: dial, transform: nil), 1.6)
        let gnomon = CGMutablePath()
        gnomon.move(to: point(5.6, 7.6))
        gnomon.addLine(to: point(10, 14.4))
        gnomon.addLine(to: point(10, 7.6))
        gnomon.closeSubpath()
        let shadow = CGMutablePath()
        shadow.move(to: point(10, 7.6))
        shadow.addLine(to: point(12.8, 5))
        return ring.union(gnomon).union(outline(shadow, 1.7))
    }
}
