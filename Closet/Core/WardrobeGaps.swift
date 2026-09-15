import Foundation

/// Something the wardrobe is missing, and why it's worth filling.
struct WardrobeGap: Identifiable {
    let id = UUID()
    let kind: GarmentKind
    /// Why this matters, in the user's terms.
    let rationale: String
    /// Higher shows first.
    let priority: Int
    /// Which occasion prompted it, if any.
    let occasion: Occasion?
}

/// Works out what's missing from a wardrobe.
///
/// This is what powers the Shop tab: every suggestion is grounded in a real gap
/// the recommender hit, rather than an arbitrary product feed.
enum WardrobeGaps {

    static func analyse(
        wardrobe: [Garment],
        weather: WeatherSnapshot
    ) -> [WardrobeGap] {
        var gaps: [WardrobeGap] = []

        // 1. Occasions the wardrobe simply can't dress for.
        for occasion in Occasion.allCases {
            let result = OutfitEngine.recommend(wardrobe: wardrobe, occasion: occasion, weather: weather, limit: 1)

            for slot in result.shortfall {
                gaps.append(
                    WardrobeGap(
                        kind: defaultKind(for: slot, occasion: occasion),
                        rationale: "You've got no \(slot.title.lowercased()) that work for \(occasion.title.lowercased()).",
                        priority: 100,
                        occasion: occasion
                    )
                )
            }

            // 2. Occasions it can dress for, but only just.
            if result.shortfall.isEmpty, let best = result.outfits.first, best.score < 0.62 {
                if let weakest = weakestSlot(in: best, occasion: occasion, weather: weather) {
                    gaps.append(
                        WardrobeGap(
                            kind: defaultKind(for: weakest, occasion: occasion),
                            rationale: "Your best \(occasion.title.lowercased()) outfit is a stretch — a better \(weakest.title.lowercased()) option would lift it.",
                            priority: 60,
                            occasion: occasion
                        )
                    )
                }
            }
        }

        // 3. Weather the wardrobe can't handle.
        if !wardrobe.contains(where: { $0.isWaterResistant }) {
            gaps.append(
                WardrobeGap(
                    kind: .rainJacket,
                    rationale: "Nothing in your closet sheds water. One waterproof layer covers every wet day.",
                    priority: 90,
                    occasion: nil
                )
            )
        }
        if !wardrobe.contains(where: { $0.warmth >= 4 }) {
            gaps.append(
                WardrobeGap(
                    kind: .sweater,
                    rationale: "You've no proper warm layer, so cold days fall back on stacking thin pieces.",
                    priority: 70,
                    occasion: nil
                )
            )
        }

        // 4. A wardrobe of nothing but loud colours is hard to combine.
        let blocks = wardrobe.filter { $0.slot == .top || $0.slot == .bottom }
        if blocks.count >= 4 {
            let neutrals = blocks.filter { $0.color.isNeutral }.count
            if Double(neutrals) / Double(blocks.count) < 0.35 {
                gaps.append(
                    WardrobeGap(
                        kind: .chinos,
                        rationale: "Most of your clothes are strong colours, which limits what goes together. A neutral bottom would pair with all of them.",
                        priority: 50,
                        occasion: nil
                    )
                )
            }
        }

        // Collapse duplicates, keeping the highest-priority reason for each kind.
        var byKind: [GarmentKind: WardrobeGap] = [:]
        for gap in gaps {
            if let existing = byKind[gap.kind], existing.priority >= gap.priority { continue }
            byKind[gap.kind] = gap
        }
        return byKind.values.sorted { $0.priority > $1.priority }
    }

    /// Which slot is dragging an otherwise-acceptable outfit down.
    private static func weakestSlot(
        in outfit: Outfit,
        occasion: Occasion,
        weather: WeatherSnapshot
    ) -> GarmentSlot? {
        outfit.items
            .map { ($0.slot, OutfitEngine.garmentScore($0, occasion: occasion, weather: weather)) }
            .min { $0.1 < $1.1 }?
            .0
    }

    /// The most generally useful thing to buy for a given slot and occasion.
    private static func defaultKind(for slot: GarmentSlot, occasion: Occasion?) -> GarmentKind {
        switch (slot, occasion) {
        case (.top, .businessCasual), (.top, .formal): return .oxfordShirt
        case (.top, .gym), (.top, .running): return .athleticTee
        case (.top, _): return .tShirt
        case (.bottom, .businessCasual): return .chinos
        case (.bottom, .formal): return .dressTrousers
        case (.bottom, .gym), (.bottom, .running): return .athleticShorts
        case (.bottom, _): return .jeans
        case (.shoes, .businessCasual), (.shoes, .formal): return .loafers
        case (.shoes, .gym), (.shoes, .running): return .runningShoes
        case (.shoes, _): return .sneakers
        case (.outerwear, .formal), (.outerwear, .businessCasual): return .blazer
        case (.outerwear, _): return .rainJacket
        case (.accessory, _): return .belt
        }
    }
}
