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
        blade.move(to: point(0.8, 2.7))
        blade.addLine(to: point(15.6, 16.1))
        blade.addLine(to: point(17, 15.4))
        blade.addCurve(to: point(17.4, 1.9), control1: point(9.4, 8.1), control2: point(11.6, 2.5))
        blade.closeSubpath()
        return blade
    }
}
