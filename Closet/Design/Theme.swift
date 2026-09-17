import SwiftUI
import UIKit

/// The app's visual language, in one place.
///
/// Colours are declared as dynamic light/dark pairs rather than asset entries so
/// the whole palette is readable and adjustable from a single file.
enum Theme {

    // MARK: - Palette

    /// Builds a colour that resolves differently in light and dark appearance.
    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    // Brand
    static let indigo = dynamic(light: 0x3B3F94, dark: 0x8A8FE8)
    static let violet = dynamic(light: 0x7A3EA8, dark: 0xC08FE6)
    static let amber  = dynamic(light: 0xC97E12, dark: 0xF0B457)
    static let teal   = dynamic(light: 0x0E9B85, dark: 0x45D6BC)

    /// The primary action colour.
    static let accent = dynamic(light: 0x6D3AA0, dark: 0xB98BE0)

    // Surfaces — a warm off-white in light, a deep indigo-black in dark, so the
    // app never looks like a plain system form.
    static let canvas      = dynamic(light: 0xF6F4F1, dark: 0x121119)
    static let surface     = dynamic(light: 0xFFFFFF, dark: 0x1D1B26)
    static let surfaceRaised = dynamic(light: 0xFFFFFF, dark: 0x272534)
    static let hairline    = dynamic(light: 0xE6E1DB, dark: 0x343143)

    // Text
    static let ink       = dynamic(light: 0x1A1823, dark: 0xF4F2F7)
    static let inkSoft   = dynamic(light: 0x605B6B, dark: 0xA8A2B8)
    static let inkFaint  = dynamic(light: 0x8F8899, dark: 0x736D84)

    // Semantic
    static let positive = dynamic(light: 0x0E8A57, dark: 0x4FD198)
    static let caution  = dynamic(light: 0xC2660C, dark: 0xF2A950)
    static let critical = dynamic(light: 0xC0392B, dark: 0xF0776A)

    /// The header gradient, echoing the app icon.
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [indigo, violet],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Metrics

    enum Radius {
        static let card: CGFloat = 20
        static let control: CGFloat = 14
        static let chip: CGFloat = 10
    }

    enum Space {
        static let tight: CGFloat = 8
        static let snug: CGFloat = 12
        static let normal: CGFloat = 16
        static let loose: CGFloat = 24
        static let section: CGFloat = 32
    }

    // MARK: - Type

    /// SF Rounded throughout: warmer than the default face, which suits an app
    /// about getting dressed rather than filing a tax return.
    static func display(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
    static func title(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold, design: .rounded) }
    static var heading: Font { .system(.headline, design: .rounded) }
    static var body: Font { .system(.subheadline, design: .rounded) }
    static var caption: Font { .system(.caption, design: .rounded) }
}

extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Reusable surfaces

/// The standard panel: a rounded surface with a hairline border, and a soft
/// shadow in light mode only — shadows on dark backgrounds just look like mud.
struct SurfaceCard: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat = Theme.Space.normal
    var radius: CGFloat = Theme.Radius.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
            .shadow(
                color: scheme == .dark ? .clear : Color.black.opacity(0.05),
                radius: 12, x: 0, y: 4
            )
    }
}

extension View {
    func surfaceCard(
        padding: CGFloat = Theme.Space.normal,
        radius: CGFloat = Theme.Radius.card
    ) -> some View {
        modifier(SurfaceCard(padding: padding, radius: radius))
    }

    /// Full-width primary action.
    func primaryAction() -> some View {
        self
            .font(Theme.heading)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }

    /// Full-width secondary action.
    func secondaryAction() -> some View {
        self
            .font(Theme.heading)
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Theme.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1)
            )
    }
}
