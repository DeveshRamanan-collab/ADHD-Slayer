import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// The few colours the Live Activities use, as hex pairs (dark, light), matching the Figma tokens and
/// the app's own colours. The widget extension can't see the app's asset catalog, so they live here.
/// The Dynamic Island is black in both appearances, so island content always takes the dark values.
public enum GlancePalette {
    public struct Pair: Hashable, Sendable {
        public let dark: String
        public let light: String

        public init(dark: String, light: String) {
            self.dark = dark
            self.light = light
        }
    }

    /// Accent gold: the ring, the compact time and the best-focus stretch.
    public static let accent = Pair(dark: "D8BC88", light: "9B783F")
    /// Lighter focus (lilac).
    public static let lighter = Pair(dark: "A897AE", light: "8A7792")
    /// Winding down (dusk rose).
    public static let windDown = Pair(dark: "C99C8D", light: "AC6E5B")
    /// A low-focus stretch (slate).
    public static let lowFocus = Pair(dark: "98A5B6", light: "6D7F93")
    /// Open time and the ring's track (tertiary ink).
    public static let tertiary = Pair(dark: "7E776F", light: "8A8077")
    /// Text.
    public static let ink = Pair(dark: "EEE8DF", light: "221C18")
    public static let inkSoft = Pair(dark: "C4BCB2", light: "4E4640")
    /// Text on the accent gold.
    public static let onAccent = Pair(dark: "1B1714", light: "F6F1E9")
    /// The Done button, and the text on it.
    public static let doneFill = Pair(dark: "E9E1D4", light: "2A231F")
    public static let onDone = Pair(dark: "1B1714", light: "F6F1E9")

    public static func stretch(_ stretch: Stretch) -> Pair {
        switch stretch {
        case .best: accent
        case .lighter: lighter
        case .lowFocus: lowFocus
        case .windDown: windDown
        case .open: tertiary
        }
    }

    /// Red, green and blue in 0...1 from "D8BC88".
    public static func components(_ hex: String) -> (red: Double, green: Double, blue: Double) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0
        return (Double((value >> 16) & 0xFF) / 255, Double((value >> 8) & 0xFF) / 255, Double(value & 0xFF) / 255)
    }
}

#if canImport(SwiftUI)
extension GlancePalette.Pair {
    public var darkColor: Color { Self.color(dark) }
    public var lightColor: Color { Self.color(light) }

    /// The colour for an appearance.
    public func color(_ scheme: ColorScheme) -> Color { scheme == .dark ? darkColor : lightColor }

    private static func color(_ hex: String) -> Color {
        let c = GlancePalette.components(hex)
        return Color(.sRGB, red: c.red, green: c.green, blue: c.blue, opacity: 1)
    }
}
#endif
