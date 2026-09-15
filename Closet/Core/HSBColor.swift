import Foundation

/// A colour in hue/saturation/brightness space. Pure value type with no UIKit
/// dependency so the matching rules stay testable and cheap.
struct HSBColor: Equatable, Hashable {
    /// 0..<360
    var hue: Double
    /// 0...1
    var saturation: Double
    /// 0...1
    var brightness: Double

    init(hue: Double, saturation: Double, brightness: Double) {
        self.hue = hue.truncatingRemainder(dividingBy: 360)
        self.saturation = min(max(saturation, 0), 1)
        self.brightness = min(max(brightness, 0), 1)
    }

    init(red: Double, green: Double, blue: Double) {
        let r = min(max(red, 0), 1), g = min(max(green, 0), 1), b = min(max(blue, 0), 1)
        let maxV = max(r, g, b), minV = min(r, g, b)
        let delta = maxV - minV

        var h = 0.0
        if delta > 0.00001 {
            if maxV == r {
                h = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
            } else if maxV == g {
                h = 60 * (((b - r) / delta) + 2)
            } else {
                h = 60 * (((r - g) / delta) + 4)
            }
        }
        if h < 0 { h += 360 }

        self.hue = h
        self.saturation = maxV <= 0.00001 ? 0 : delta / maxV
        self.brightness = maxV
    }

    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        if s.count == 3 {
            s = s.map { "\($0)\($0)" }.joined()
        }
        guard s.count == 6, let value = UInt32(s, radix: 16) else {
            self.init(red: 0.5, green: 0.5, blue: 0.5)
            return
        }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }

    var rgb: (red: Double, green: Double, blue: Double) {
        let c = brightness * saturation
        let x = c * (1 - abs((hue / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = brightness - c
        let (r1, g1, b1): (Double, Double, Double)
        switch hue {
        case 0..<60:    (r1, g1, b1) = (c, x, 0)
        case 60..<120:  (r1, g1, b1) = (x, c, 0)
        case 120..<180: (r1, g1, b1) = (0, c, x)
        case 180..<240: (r1, g1, b1) = (0, x, c)
        case 240..<300: (r1, g1, b1) = (x, 0, c)
        default:        (r1, g1, b1) = (c, 0, x)
        }
        return (r1 + m, g1 + m, b1 + m)
    }

    var hex: String {
        let (r, g, b) = rgb
        return String(format: "#%02X%02X%02X",
                      Int((r * 255).rounded()),
                      Int((g * 255).rounded()),
                      Int((b * 255).rounded()))
    }

    /// Shortest distance between two hues on the wheel, 0...180.
    func hueDistance(to other: HSBColor) -> Double {
        let d = abs(hue - other.hue).truncatingRemainder(dividingBy: 360)
        return d > 180 ? 360 - d : d
    }

    /// How "goes with anything" this colour is, 0...1.
    /// True greys and blacks score 1. Navy, denim, khaki and olive score high because
    /// in practice they behave as neutrals even though they carry real saturation.
    var neutrality: Double {
        // Achromatic: little saturation, or so dark/light that hue stops reading.
        if saturation <= 0.12 { return 1.0 }
        if brightness <= 0.16 { return 1.0 }
        if saturation <= 0.22 { return 0.9 }

        // Navy and charcoal-blue.
        if (200...255).contains(hue) && brightness <= 0.45 { return 0.85 }
        // Denim.
        if (195...245).contains(hue) && saturation <= 0.55 && (0.3...0.75).contains(brightness) {
            return 0.7
        }
        // Khaki, camel, beige, tan, olive. Olive runs more saturated than the
        // rest of this family, so the cap has to clear it.
        if (20...95).contains(hue) && saturation <= 0.65 && brightness >= 0.25 { return 0.7 }
        // Deep muted tones — burgundy, forest green. Kept tight: a saturated
        // dark colour like royal purple is a statement, not a neutral.
        if brightness <= 0.35 && saturation <= 0.60 { return 0.55 }

        return 0.0
    }

    var isNeutral: Bool { neutrality >= 0.55 }
    /// Loud enough that two of them in one outfit start to fight.
    var isVivid: Bool { saturation >= 0.55 && brightness >= 0.45 && neutrality < 0.55 }

    /// Everyday name for the colour, used to write the explanations.
    var name: String {
        if brightness <= 0.12 { return "black" }
        if saturation <= 0.10 {
            switch brightness {
            case ..<0.28: return "charcoal"
            case ..<0.55: return "grey"
            case ..<0.85: return "light grey"
            default: return "white"
            }
        }
        if (200...255).contains(hue) && brightness <= 0.45 && saturation > 0.35 { return "navy" }
        // Dark and barely saturated reads as charcoal whatever the hue leans toward.
        if saturation <= 0.35 && brightness <= 0.35 { return "charcoal" }

        let base: String
        switch hue {
        case 0..<12, 348..<360: base = "red"
        case 12..<24: base = (brightness <= 0.55 || saturation >= 0.75) ? "rust" : "coral"
        case 24..<42: base = saturation <= 0.5 ? "camel" : "orange"
        case 42..<62: base = saturation <= 0.5 ? "khaki" : "yellow"
        case 62..<95: base = brightness <= 0.5 ? "olive" : "lime"
        case 95..<155: base = brightness <= 0.4 ? "forest green" : "green"
        case 155..<185: base = "teal"
        case 185..<205: base = "sky blue"
        case 205..<250: base = "blue"
        case 250..<280: base = "indigo"
        case 280..<310: base = "purple"
        case 310..<334: base = "magenta"
        default: base = (brightness <= 0.60 && saturation >= 0.55) ? "burgundy" : "pink"
        }

        if brightness <= 0.34 && !["rust", "olive", "forest green", "burgundy", "navy"].contains(base) {
            return "deep \(base)"
        }
        if saturation <= 0.30 && brightness >= 0.80 { return "pale \(base)" }
        return base
    }
}
