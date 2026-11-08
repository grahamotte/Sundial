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
        let center = point(9, 6.6)
        let face = CGRect(x: center.x - 7.5 * unit, y: center.y - 3.4 * unit, width: 15 * unit, height: 6.8 * unit)
        let faceFill = CGPath(ellipseIn: face, transform: nil)
        let faceClearance = faceFill.union(outline(faceFill, 1.6))
        let base = CGPath(ellipseIn: face.offsetBy(dx: 0, dy: -2 * unit), transform: nil)
        let band = CGPath(rect: CGRect(x: face.minX, y: face.midY - 2 * unit, width: face.width, height: 2 * unit), transform: nil)
        let rim = base.union(band).subtracting(faceClearance)
        let ticks = CGMutablePath()
        for degrees: CGFloat in [25, 200, 250, 295] {
            let angle = degrees * .pi / 180
            let outer = CGPoint(x: center.x + cos(angle) * 6.3 * unit, y: center.y + sin(angle) * 2.75 * unit)
            let inner = CGPoint(x: center.x + cos(angle) * 5.2 * unit, y: center.y + sin(angle) * 2.25 * unit)
            ticks.move(to: inner)
            ticks.addLine(to: outer)
        }
        let tickCuts = outline(ticks, 0.85)
        let gnomon = CGMutablePath()
        gnomon.move(to: point(5.0, 7.0))
        gnomon.addLine(to: point(9.6, 16.6))
        gnomon.addLine(to: point(9.6, 7.0))
        gnomon.closeSubpath()
        let shadow = CGMutablePath()
        shadow.move(to: point(6.4, 7.0))
        shadow.addLine(to: point(9.6, 7.0))
        shadow.addLine(to: point(14.0, 4.0))
        shadow.closeSubpath()
        let dial = faceFill.subtracting(tickCuts).subtracting(shadow).subtracting(outline(gnomon, 1.6).union(gnomon))
        return dial.union(rim).union(gnomon)
    }
}
