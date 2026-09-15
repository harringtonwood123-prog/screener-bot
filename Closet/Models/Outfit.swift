import Foundation

enum ReasonTone: String, Codable {
    case positive
    case caution
    case info
}

/// One line of the "why this works" explanation shown under a recommendation.
struct Reason: Identifiable, Hashable {
    let id = UUID()
    let symbol: String
    let text: String
    let tone: ReasonTone

    static func good(_ symbol: String, _ text: String) -> Reason {
        Reason(symbol: symbol, text: text, tone: .positive)
    }
    static func warn(_ symbol: String, _ text: String) -> Reason {
        Reason(symbol: symbol, text: text, tone: .caution)
    }
    static func info(_ symbol: String, _ text: String) -> Reason {
        Reason(symbol: symbol, text: text, tone: .info)
    }
}

/// A complete recommendation: the clothes, how strong the pick is, and why.
struct Outfit: Identifiable {
    let id = UUID()
    var items: [Garment]
    var occasion: Occasion
    /// 0...1
    var score: Double
    var reasons: [Reason]

    func item(in slot: GarmentSlot) -> Garment? {
        items.first { $0.slot == slot }
    }

    var top: Garment? { item(in: .top) }
    var bottom: Garment? { item(in: .bottom) }
    var shoes: Garment? { item(in: .shoes) }
    var outerwear: Garment? { item(in: .outerwear) }

    /// Total insulation carried by the outfit.
    var totalWarmth: Int { items.reduce(0) { $0 + $1.warmth } }

    var title: String {
        let names = [top, bottom].compactMap { $0?.color.name }
        if names.count == 2 { return "\(names[0].capitalizedFirst) & \(names[1])" }
        return occasion.title
    }

    /// Short verdict used as the headline on the result screen.
    var verdict: String {
        switch score {
        case 0.82...: return "Great match"
        case 0.68..<0.82: return "Solid pick"
        case 0.52..<0.68: return "Works"
        default: return "Best available"
        }
    }
}
