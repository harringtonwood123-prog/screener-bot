import Foundation

/// The relationship between two colours in an outfit.
enum ColorHarmony: String {
    case neutralPair      // two neutrals — always safe
    case neutralAnchor    // one neutral grounding one colour — the workhorse
    case monochrome       // same hue, different depth
    case flat             // same hue AND same depth — reads as a failed match
    case analogous        // neighbours on the wheel
    case complementary    // far enough apart to read as deliberate contrast
    case discord          // the awkward gap that tends to clash

    /// 0...1. Anything at or below `Self.weakThreshold` is worth warning about.
    var score: Double {
        switch self {
        case .neutralAnchor: return 0.92
        case .neutralPair: return 0.88
        case .complementary: return 0.82
        case .analogous: return 0.78
        case .monochrome: return 0.74
        case .flat: return 0.34
        case .discord: return 0.26
        }
    }

    static let weakThreshold = 0.40

    func explain(_ a: String, _ b: String) -> String {
        switch self {
        case .neutralPair:
            return "\(a.capitalizedFirst) and \(b) are both neutrals, so they can't clash."
        case .neutralAnchor:
            return "\(a.capitalizedFirst) is a neutral, which lets the \(b) carry the outfit."
        case .monochrome:
            return "\(a.capitalizedFirst) and \(b) are the same family at different depths — a clean tonal look."
        case .flat:
            return "\(a.capitalizedFirst) and \(b) are too close in both colour and depth, so the outfit reads flat."
        case .analogous:
            return "\(a.capitalizedFirst) sits next to \(b) on the colour wheel, so they blend easily."
        case .complementary:
            return "\(a.capitalizedFirst) and \(b) are opposites on the colour wheel — high contrast that works on purpose."
        case .discord:
            return "\(a.capitalizedFirst) and \(b) land in the awkward gap on the wheel and tend to clash."
        }
    }
}

enum ColorTheory {

    /// Classify how two garment colours relate.
    static func harmony(_ a: HSBColor, _ b: HSBColor) -> ColorHarmony {
        let aNeutral = a.isNeutral
        let bNeutral = b.isNeutral

        // Two neutrals always work. All-black, or a white tee with white sneakers,
        // is a deliberate look rather than a failed match.
        if aNeutral && bNeutral { return .neutralPair }
        if aNeutral != bNeutral { return .neutralAnchor }

        let distance = a.hueDistance(to: b)
        switch distance {
        case ..<16:
            return abs(a.brightness - b.brightness) >= 0.22 || abs(a.saturation - b.saturation) >= 0.30
                ? .monochrome
                : .flat
        case 16..<50: return .analogous
        // The genuinely awkward gap: red with yellow, orange with chartreuse.
        case 50..<95: return .discord
        // Classic opposites (red/green, blue/orange, yellow/purple) sit around
        // 120-145 degrees apart in HSB, not the 180 an artist's wheel implies —
        // so the whole upper range counts as deliberate contrast.
        default: return .complementary
        }
    }

    /// Score a whole set of garment colours, 0...1, plus the notable observations.
    /// Only the pairings a person actually notices are scored: the big blocks
    /// (top/bottom/shoes/outerwear) against each other. Accessories are ignored.
    static func evaluate(_ colors: [(label: String, color: HSBColor)]) -> (score: Double, notes: [ColorNote]) {
        guard colors.count >= 2 else { return (0.8, []) }

        var total = 0.0
        var count = 0.0
        var notes: [ColorNote] = []

        for i in colors.indices {
            for j in (i + 1)..<colors.count {
                let a = colors[i], b = colors[j]
                let h = harmony(a.color, b.color)
                total += h.score
                count += 1
                notes.append(
                    ColorNote(
                        harmony: h,
                        text: h.explain(a.color.name, b.color.name),
                        isWarning: h.score <= ColorHarmony.weakThreshold
                    )
                )
            }
        }

        var score = count > 0 ? total / count : 0.8

        // Too many loud colours at once. One statement piece is good; three is noise.
        let vividCount = colors.filter { $0.color.isVivid }.count
        if vividCount >= 3 {
            score -= 0.22
            notes.append(
                ColorNote(harmony: .discord,
                          text: "Three bold colours at once is a lot — let one of them lead.",
                          isWarning: true)
            )
        } else if vividCount == 2 {
            score -= 0.06
        }

        // Some separation in lightness between top and bottom keeps the silhouette readable.
        if let first = colors.first, let second = colors.dropFirst().first {
            if abs(first.color.brightness - second.color.brightness) < 0.08
                && first.color.hueDistance(to: second.color) < 25 {
                score -= 0.08
            }
        }

        return (min(max(score, 0), 1), notes)
    }

    /// The single most useful thing to say about an outfit's colours.
    static func headline(from notes: [ColorNote]) -> String? {
        if let warning = notes.first(where: { $0.isWarning }) { return warning.text }
        let ranked = notes.sorted { $0.harmony.score > $1.harmony.score }
        // Prefer a remark that says something, over "these two neutrals are fine".
        if let interesting = ranked.first(where: {
            $0.harmony == .complementary || $0.harmony == .analogous || $0.harmony == .monochrome
        }) {
            return interesting.text
        }
        return ranked.first?.text
    }
}

struct ColorNote: Identifiable, Hashable {
    let id = UUID()
    let harmony: ColorHarmony
    let text: String
    let isWarning: Bool
}

extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
