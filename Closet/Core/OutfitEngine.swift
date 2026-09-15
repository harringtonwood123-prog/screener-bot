import Foundation

/// Builds outfit recommendations from a wardrobe, an occasion and the weather.
///
/// The approach is deliberately simple and explainable: score every garment for
/// how well it suits the occasion and conditions, keep the best few per slot,
/// then score the combinations of those on colour and coherence. Every points
/// deduction has a sentence attached, which is what the result screen shows.
enum OutfitEngine {

    /// How many candidates to keep per slot before combining. Keeps the search
    /// to a few hundred combinations even for a large wardrobe.
    private static let keepPerSlot = 6

    struct Result {
        var outfits: [Outfit]
        /// Set when the wardrobe can't produce a complete outfit.
        var shortfall: [GarmentSlot]
    }

    static func recommend(
        wardrobe: [Garment],
        occasion: Occasion,
        weather: WeatherSnapshot,
        limit: Int = 3
    ) -> Result {
        let band = weather.band

        // 1. Score each garment in isolation.
        var pools: [GarmentSlot: [(garment: Garment, score: Double)]] = [:]
        for slot in GarmentSlot.allCases {
            let scored = wardrobe
                .filter { $0.slot == slot }
                .map { (garment: $0, score: garmentScore($0, occasion: occasion, weather: weather)) }
                .filter { $0.score > 0 }
                .sorted { $0.score > $1.score }
            pools[slot] = Array(scored.prefix(keepPerSlot))
        }

        // 2. Bail out early if a required slot is empty.
        let missing = GarmentSlot.required.filter { (pools[$0]?.isEmpty ?? true) }
        guard missing.isEmpty else { return Result(outfits: [], shortfall: missing) }

        let tops = pools[.top] ?? []
        let bottoms = pools[.bottom] ?? []
        let shoes = pools[.shoes] ?? []

        // Outerwear is optional unless it's cold. `nil` means "no jacket".
        var outerOptions: [(garment: Garment, score: Double)?] = (pools[.outerwear] ?? []).map { Optional($0) }
        let outerRequired = band.needsOuterwear || weather.expectsPrecipitation
        if !outerRequired || outerOptions.isEmpty {
            outerOptions.append(nil)
        }

        // 3. Score every combination.
        var candidates: [Outfit] = []
        for t in tops {
            for b in bottoms {
                for s in shoes {
                    for o in outerOptions {
                        var items = [t.garment, b.garment, s.garment]
                        var total = t.score + b.score + s.score
                        if let o {
                            items.append(o.garment)
                            total += o.score
                        }
                        let base = total / Double(items.count)
                        candidates.append(
                            assemble(items: items, baseScore: base, occasion: occasion, weather: weather)
                        )
                    }
                }
            }
        }

        // 4. Keep the best, but avoid returning three near-identical outfits.
        let ranked = candidates.sorted { $0.score > $1.score }
        var chosen: [Outfit] = []
        for outfit in ranked {
            let tooSimilar = chosen.contains { existing in
                let shared = Set(existing.items.map(\.id)).intersection(outfit.items.map(\.id))
                return shared.count >= max(2, outfit.items.count - 1)
            }
            if !tooSimilar { chosen.append(outfit) }
            if chosen.count == limit { break }
        }
        // If everything was "too similar" we still owe the user a result.
        if chosen.isEmpty, let best = ranked.first { chosen = [best] }

        return Result(outfits: chosen, shortfall: [])
    }

    // MARK: - Per-garment scoring

    /// 0 means "never suggest this here"; otherwise 0...1.
    static func garmentScore(_ g: Garment, occasion: Occasion, weather: WeatherSnapshot) -> Double {
        // Hard exclusions: gym kit at a wedding, or a blazer on a run.
        if occasion.wantsAthletic {
            // Only things you'd actually train in.
            if !g.kind.suitsSport { return 0 }
        } else {
            if g.kind.isAthletic { return 0 }
        }
        // Sport is forgiving — an ordinary tee and sneakers are fine at the gym —
        // so allow a wider band there than for occasions with a dress code.
        let tolerance = occasion.wantsAthletic ? 2 : 1
        guard occasion.formalityRange.contains(g.formality)
                || abs(g.formality - occasion.idealFormality) <= tolerance else { return 0 }

        var score = 0.5

        // Formality proximity.
        let gap = abs(g.formality - occasion.idealFormality)
        score += [0.30, 0.18, 0.04][min(gap, 2)]

        // Weather suitability for this single item.
        let band = weather.band
        switch band {
        case .hot, .warm:
            score += Double(g.breathability) * 0.05
            score -= Double(max(0, g.warmth - 2)) * 0.09
        case .mild:
            score += Double(g.breathability) * 0.015
        case .cool:
            score += Double(g.warmth) * 0.025
        case .cold, .freezing:
            score += Double(g.warmth) * 0.05
            score -= Double(max(0, 4 - g.breathability)) * 0.005
        }

        if weather.expectsPrecipitation && g.isWaterResistant { score += 0.12 }
        if weather.expectsPrecipitation && g.kind == .sandals { score -= 0.35 }
        if weather.isWindy && g.kind.blocksWind { score += 0.08 }

        // Nudge toward clothes that have been sitting unworn, and toward favourites.
        score += min(Double(g.daysSinceWorn), 21.0) / 21.0 * 0.10
        if g.isFavourite { score += 0.06 }

        return min(max(score, 0.01), 1.0)
    }

    // MARK: - Outfit assembly

    private static func assemble(
        items: [Garment],
        baseScore: Double,
        occasion: Occasion,
        weather: WeatherSnapshot
    ) -> Outfit {
        var reasons: [Reason] = []
        var score = baseScore

        // --- Colour ---
        // Only the large blocks drive the colour read.
        let blocks: [(label: String, color: HSBColor)] = items
            .filter { $0.slot != .accessory }
            .map { (label: $0.kind.displayName, color: $0.color) }
        let (colorScore, notes) = ColorTheory.evaluate(blocks)
        score = score * 0.55 + colorScore * 0.45

        if let headline = ColorTheory.headline(from: notes) {
            let isWarning = notes.contains { $0.isWarning }
            reasons.append(
                isWarning ? .warn("paintpalette.fill", headline)
                          : .good("paintpalette.fill", headline)
            )
        }

        // --- Warmth vs conditions ---
        let band = weather.band
        let warmth = items.reduce(0) { $0 + $1.warmth }
        // Floor of 4: the lightest possible outfit (tee + shorts + trainers) already
        // carries about that much, so a lower target would flag every summer pick.
        let target = max(4, band.targetWarmth + occasion.warmthAdjustment)
        let drift = warmth - target
        let temp = Int(weather.feelsLikeC.rounded())

        let warmthPenalty = Double(abs(drift)) * 0.035 * occasion.weatherWeight
        score -= min(warmthPenalty, 0.30)

        if abs(drift) <= 2 {
            reasons.append(.good(
                "thermometer.medium",
                "Right weight for \(temp)°, which is what it'll feel like out there."
            ))
        } else if drift < -2 {
            reasons.append(.warn(
                "thermometer.low",
                "This runs light for \(temp)° — add a layer if you'll be outside a while."
            ))
        } else {
            reasons.append(.warn(
                "thermometer.high",
                "This runs warm for \(temp)° — you may want to lose a layer indoors."
            ))
        }

        // --- Rain, wind, swing ---
        if weather.expectsPrecipitation {
            let covered = items.contains { $0.isWaterResistant }
            let openShoes = items.contains { $0.kind == .sandals }
            if covered && !openShoes {
                score += 0.05
                reasons.append(.good(
                    "umbrella.fill",
                    "\(weather.precipitationChance)% chance of rain, and this outfit can take it."
                ))
            } else {
                score -= 0.07
                reasons.append(.warn(
                    "umbrella.fill",
                    "\(weather.precipitationChance)% chance of rain and nothing here sheds water — take a jacket."
                ))
            }
        }

        if weather.isWindy {
            if items.contains(where: { $0.kind.blocksWind }) {
                reasons.append(.good(
                    "wind",
                    "Wind at \(Int(weather.windKph)) km/h — the outer layer cuts it."
                ))
            } else {
                score -= 0.04
                reasons.append(.warn(
                    "wind",
                    "It's blowing \(Int(weather.windKph)) km/h and nothing here blocks wind."
                ))
            }
        }

        if weather.hasBigSwing && items.contains(where: { $0.slot == .outerwear }) {
            reasons.append(.info(
                "arrow.up.arrow.down",
                "Swings from \(Int(weather.lowC))° to \(Int(weather.highC))° today — a layer you can take off helps."
            ))
        }

        // --- Formality coherence ---
        let formalities = items.filter { $0.slot != .accessory }.map(\.formality)
        if let lo = formalities.min(), let hi = formalities.max(), hi - lo >= 3 {
            score -= 0.12
            reasons.append(.warn(
                "arrow.left.and.right",
                "These pieces are pulling in different directions — one is much dressier than the rest."
            ))
        } else {
            reasons.append(.good(
                "checkmark.seal.fill",
                "Pitched right for \(occasion.title.lowercased())."
            ))
        }

        // --- Something unworn ---
        if let stale = items.filter({ $0.daysSinceWorn >= 21 }).max(by: { $0.daysSinceWorn < $1.daysSinceWorn }),
           stale.daysSinceWorn < 99 {
            reasons.append(.info(
                "sparkles",
                "You haven't worn the \(stale.name.lowercased()) in \(stale.daysSinceWorn) days."
            ))
        }

        return Outfit(
            items: items,
            occasion: occasion,
            score: min(max(score, 0), 1),
            reasons: reasons
        )
    }
}
