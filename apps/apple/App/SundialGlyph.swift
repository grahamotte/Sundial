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
        let blade = CGMutablePath()
        blade.move(to: point(1, 2.2))
        blade.addLine(to: point(14.2, 16.8))
        blade.addLine(to: point(16.6, 15.6))
        blade.addCurve(to: point(17, 1.2), control1: point(11.4, 10.4), control2: point(11.4, 3.2))
        blade.closeSubpath()
        return blade
    }
}
