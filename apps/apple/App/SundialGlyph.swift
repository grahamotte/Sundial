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
        blade.move(to: point(1, 1.54))
        blade.addLine(to: point(15.91, 16.46))
        blade.addLine(to: point(16.81, 15.56))
        blade.addLine(to: point(14.18, 9.91))
        blade.addArc(center: point(18.46, 7.91), radius: 4.72 * unit, startAngle: .pi * 155 / 180, endAngle: .pi * 252 / 180, clockwise: false)
        blade.addLine(to: point(17, 1.54))
        blade.closeSubpath()
        return blade
    }
}
