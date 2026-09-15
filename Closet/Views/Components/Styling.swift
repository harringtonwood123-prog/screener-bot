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

/// The rounded panel used throughout the app.
struct CardBackground: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding))
    }
}

extension ReasonTone {
    var color: Color {
        switch self {
        case .positive: return .green
        case .caution: return .orange
        case .info: return .secondary
        }
    }
}
