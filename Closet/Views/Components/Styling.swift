import SwiftUI

extension Color {
    /// Builds a colour from "#RRGGBB". Falls back to grey on anything unparseable.
    init(hex: String) {
        let c = HSBColor(hex: hex)
        let (r, g, b) = c.rgb
        self.init(red: r, green: g, blue: b)
    }
}

extension HSBColor {
    var swiftUIColor: Color {
        let (r, g, b) = rgb
        return Color(red: r, green: g, blue: b)
    }

    /// A readable foreground colour to lay over this one.
    var contrastingForeground: Color {
        brightness > 0.65 ? .black : .white
    }
}

extension ReasonTone {
    var color: Color {
        switch self {
        case .positive: return Theme.positive
        case .caution: return Theme.caution
        case .info: return Theme.inkFaint
        }
    }
}
