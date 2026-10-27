import AppKit
import SwiftUI

enum Solar {
    static let plate = color(light: 0xEEE8D5, dark: 0x073642, lightContrast: 0xE6DFC8, darkContrast: 0x002B36)
    static let paper = color(light: 0xFDF6E3, dark: 0x002B36, lightContrast: 0xFFFFFF, darkContrast: 0x001F27)
    static let ink = color(light: 0x073642, dark: 0xEEE8D5, lightContrast: 0x002B36, darkContrast: 0xFDF6E3)
    static let muted = color(light: 0x4F646B, dark: 0x93A1A1, lightContrast: 0x3D4F55, darkContrast: 0xB8C4C4)
    static let hairline = color(light: 0xD9D2BC, dark: 0x0E4553, lightContrast: 0x93A1A1, darkContrast: 0x586E75)
    static let horizon = color(light: 0xB3AC97, dark: 0x3B5F69, lightContrast: 0x657B83, darkContrast: 0x839496)
    static let sun = color(light: 0xA07800, dark: 0xD9A400, lightContrast: 0x7A5C00, darkContrast: 0xF0C33C)
    static let sunlight = color(light: 0xB58900, dark: 0xB58900, lightContrast: 0xB58900, darkContrast: 0xB58900)
    static let sky = color(light: 0x1F6FA8, dark: 0x3A9AE0, lightContrast: 0x15577F, darkContrast: 0x6CB6EC)
    static let storm = color(light: 0xDC322F, dark: 0xEC4D49, lightContrast: 0xB0201D, darkContrast: 0xFF6F6B)
    static let stormText = color(light: 0xB0201D, dark: 0xFF6F6B, lightContrast: 0x8E1A17, darkContrast: 0xFF8E8A)
    static let dusk = color(light: 0x6E7C7C, dark: 0x839496, lightContrast: 0x56635F, darkContrast: 0xA3B1B1)

    static func color(light: UInt32, dark: UInt32, lightContrast: UInt32, darkContrast: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            switch appearance.bestMatch(from: [.aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua]) {
            case .darkAqua?: return nsColor(dark)
            case .accessibilityHighContrastAqua?: return nsColor(lightContrast)
            case .accessibilityHighContrastDarkAqua?: return nsColor(darkContrast)
            default: return nsColor(light)
            }
        })
    }

    private static func nsColor(_ hex: UInt32) -> NSColor {
        NSColor(
            srgbRed: CGFloat(hex >> 16 & 0xFF) / 255,
            green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension RunRecord.Status {
    var tint: Color {
        switch self {
        case .running: return Solar.sky
        case .succeeded: return Solar.sun
        case .failed, .interrupted: return Solar.storm
        }
    }

    var textTint: Color {
        isFailure ? Solar.stormText : tint
    }
}
