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
        let face = CGRect(origin: point(1.5, 2.6), size: CGSize(width: 15 * unit, height: 7 * unit))
        let faceRing = CGPath(ellipseIn: face.insetBy(dx: 0.7 * unit, dy: 0.7 * unit), transform: nil)
            .copy(strokingWithWidth: 1.4 * unit, lineCap: .round, lineJoin: .round, miterLimit: 10)
        let base = CGPath(ellipseIn: face.offsetBy(dx: 0, dy: -1.6 * unit), transform: nil)
        let band = CGPath(rect: CGRect(x: face.minX, y: face.midY - 1.6 * unit, width: face.width, height: 1.6 * unit), transform: nil)
        let faceFill = CGPath(ellipseIn: face, transform: nil)
        let rim = base.union(band).subtracting(faceFill)
        let gnomon = CGMutablePath()
        gnomon.move(to: point(5.2, 6.1))
        gnomon.addLine(to: point(9.8, 15.8))
        gnomon.addLine(to: point(9.8, 6.1))
        gnomon.closeSubpath()
        let gnomonGap = gnomon.copy(strokingWithWidth: 1.6 * unit, lineCap: .round, lineJoin: .round, miterLimit: 10)
        let shadow = CGMutablePath()
        shadow.move(to: point(7.4, 6.1))
        shadow.addLine(to: point(9.8, 6.1))
        shadow.addLine(to: point(14.0, 4.2))
        shadow.closeSubpath()
        let sun = CGPath(ellipseIn: CGRect(origin: point(1.6, 13.4), size: CGSize(width: 3 * unit, height: 3 * unit)), transform: nil)
        return faceRing.union(rim).subtracting(gnomonGap).union(gnomon).union(shadow).union(sun)
    }
}
