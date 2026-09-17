import XCTest
@testable import Closet

/// The recommender. The regression cases here are bugs that were caught by
/// testing the scoring rules before the app had ever been built.
final class OutfitEngineTests: XCTestCase {

    /// Stored, not computed: SampleData mints fresh identifiers on every read,
    /// so a computed property would hand each assertion a different wardrobe.
    private var wardrobe: [Garment] = []

    override func setUp() {
        super.setUp()
        wardrobe = SampleData.wardrobe
        Units.stored = .metric
    }

    override func tearDown() {
        Units.stored = .automatic
        super.tearDown()
    }

    // MARK: - Basics

    func testEveryOccasionGetsACompleteOutfit() {
        let weather = TestWeather.make(feelsLikeC: 18)
        for occasion in Occasion.allCases {
            let result = OutfitEngine.recommend(wardrobe: wardrobe, occasion: occasion, weather: weather)
            XCTAssertTrue(result.shortfall.isEmpty, "\(occasion.title) reported a shortfall")
            guard let outfit = result.outfits.first else {
                XCTFail("\(occasion.title) produced no outfit")
                continue
            }
            for slot in GarmentSlot.required {
                XCTAssertNotNil(outfit.item(in: slot), "\(occasion.title) is missing \(slot.title)")
            }
            XCTAssertFalse(outfit.reasons.isEmpty, "\(occasion.title) gave no explanation")
        }
    }

    func testEmptyWardrobeReportsWhatIsMissing() {
        let result = OutfitEngine.recommend(
            wardrobe: [], occasion: .casual, weather: TestWeather.make(feelsLikeC: 18)
        )
        XCTAssertTrue(result.outfits.isEmpty)
        XCTAssertEqual(Set(result.shortfall), Set(GarmentSlot.required))
    }

    func testAlternativesAreActuallyDifferent() {
        let result = OutfitEngine.recommend(
            wardrobe: wardrobe, occasion: .casual, weather: TestWeather.make(feelsLikeC: 18), limit: 3
        )
        guard result.outfits.count > 1 else { return }
        let first = Set(result.outfits[0].items.map(\.id))
        let second = Set(result.outfits[1].items.map(\.id))
        XCTAssertNotEqual(first, second, "the alternative should not be the same outfit")
    }

    // MARK: - Occasion fit

    func testGymNeverSuggestsFormalwear() {
        let result = OutfitEngine.recommend(
            wardrobe: wardrobe, occasion: .gym, weather: TestWeather.make(feelsLikeC: 18)
        )
        let kinds = result.outfits.first?.items.map(\.kind) ?? []
        for banned in [GarmentKind.blazer, .dressShoes, .dressTrousers, .dressShirt] {
            XCTAssertFalse(kinds.contains(banned), "\(banned.displayName) has no business at the gym")
        }
    }

    /// Regression: a denim jacket was being recommended for a 5k, because it
    /// passed on formality alone.
    func testSportNeverSuggestsStreetOuterwear() {
        let cold = TestWeather.make(feelsLikeC: 4)
        for occasion in [Occasion.gym, .running] {
            let result = OutfitEngine.recommend(wardrobe: wardrobe, occasion: occasion, weather: cold)
            let kinds = result.outfits.first?.items.map(\.kind) ?? []
            for banned in [GarmentKind.denimJacket, .blazer, .overcoat, .bomberJacket] {
                XCTAssertFalse(kinds.contains(banned),
                               "\(banned.displayName) suggested for \(occasion.title)")
            }
        }
    }

    func testOfficeNeverSuggestsGymKit() {
        let result = OutfitEngine.recommend(
            wardrobe: wardrobe, occasion: .businessCasual, weather: TestWeather.make(feelsLikeC: 18)
        )
        let kinds = result.outfits.first?.items.map(\.kind) ?? []
        for banned in [GarmentKind.athleticShorts, .athleticTee, .runningShoes, .joggers] {
            XCTAssertFalse(kinds.contains(banned), "\(banned.displayName) is not business casual")
        }
    }

    func testFormalWithoutDressTrousersReportsAShortfall() {
        let stripped = wardrobe.filter { $0.kind != .dressTrousers }
        let result = OutfitEngine.recommend(
            wardrobe: stripped, occasion: .formal, weather: TestWeather.make(feelsLikeC: 18)
        )
        XCTAssertEqual(result.shortfall, [.bottom])
    }

    // MARK: - Weather

    func testColdOutfitsCarryMoreWarmthThanHotOnes() {
        let cold = OutfitEngine.recommend(
            wardrobe: wardrobe, occasion: .casual, weather: TestWeather.make(feelsLikeC: -2), limit: 1
        ).outfits.first
        let hot = OutfitEngine.recommend(
            wardrobe: wardrobe, occasion: .casual, weather: TestWeather.make(feelsLikeC: 32), limit: 1
        ).outfits.first

        XCTAssertNotNil(cold)
        XCTAssertNotNil(hot)
        XCTAssertGreaterThan(cold!.totalWarmth, hot!.totalWarmth)
    }

    func testColdWeatherAddsALayer() {
        let result = OutfitEngine.recommend(
            wardrobe: wardrobe, occasion: .casual, weather: TestWeather.make(feelsLikeC: -2)
        )
        XCTAssertNotNil(result.outfits.first?.outerwear, "below freezing should bring a jacket")
    }

    func testRainPrefersSomethingWaterResistant() {
        let wet = TestWeather.make(feelsLikeC: 12, precipitationChance: 80, code: 63)
        let result = OutfitEngine.recommend(wardrobe: wardrobe, occasion: .casual, weather: wet)
        let outfit = result.outfits.first
        XCTAssertNotNil(outfit)
        XCTAssertTrue(outfit!.items.contains { $0.isWaterResistant },
                      "an 80% chance of rain should pull in something that sheds water")
    }

    func testRainNeverSuggestsSandals() {
        let wet = TestWeather.make(feelsLikeC: 24, precipitationChance: 90, code: 63)
        let withSandals = wardrobe + [Garment(kind: .sandals, name: "Sandals", colorHex: "#8B7355")]
        let result = OutfitEngine.recommend(wardrobe: withSandals, occasion: .casual, weather: wet)
        let kinds = result.outfits.first?.items.map(\.kind) ?? []
        XCTAssertFalse(kinds.contains(.sandals))
    }

    /// Regression: gym and running returned byte-identical outfits despite one
    /// being indoors. Sport targets a lower warmth than the thermometer implies,
    /// and running more so than the gym.
    func testRunningDressesLighterThanTheGym() {
        let cool = TestWeather.make(feelsLikeC: 11)
        let gym = OutfitEngine.recommend(wardrobe: wardrobe, occasion: .gym, weather: cool, limit: 1).outfits.first
        let run = OutfitEngine.recommend(wardrobe: wardrobe, occasion: .running, weather: cool, limit: 1).outfits.first
        XCTAssertNotNil(gym)
        XCTAssertNotNil(run)
        XCTAssertLessThanOrEqual(run!.totalWarmth, gym!.totalWarmth)
    }

    /// Regression: every hot-weather sport outfit warned "this runs warm",
    /// because the target warmth was below anything physically achievable —
    /// the lightest possible outfit still carries about four points.
    func testHotWeatherSportIsNotWronglyFlaggedAsTooWarm() {
        let hot = TestWeather.make(feelsLikeC: 31)
        for occasion in [Occasion.gym, .running] {
            let outfit = OutfitEngine.recommend(
                wardrobe: wardrobe, occasion: occasion, weather: hot, limit: 1
            ).outfits.first
            XCTAssertNotNil(outfit)
            let complained = outfit!.reasons.contains { $0.text.contains("runs warm") }
            XCTAssertFalse(complained, "\(occasion.title) wrongly warned about warmth at 31C")
        }
    }

    /// Dangerous heat deserves saying out loud, not just scoring.
    func testExtremeHeatIsCalledOut() {
        let austin = TestWeather.make(feelsLikeC: 41)
        let outfit = OutfitEngine.recommend(
            wardrobe: wardrobe, occasion: .casual, weather: austin, limit: 1
        ).outfits.first
        XCTAssertNotNil(outfit)
        XCTAssertTrue(
            outfit!.reasons.contains { $0.symbol.contains("trianglebadge") },
            "a 41C heat index should produce a warning"
        )
    }

    func testExplanationsMentionTheTemperature() {
        Units.stored = .imperial
        let austin = TestWeather.make(feelsLikeC: Units.celsius(fromFahrenheit: 106))
        let outfit = OutfitEngine.recommend(
            wardrobe: wardrobe, occasion: .casual, weather: austin, limit: 1
        ).outfits.first
        XCTAssertNotNil(outfit)
        XCTAssertTrue(
            outfit!.reasons.contains { $0.text.contains("106°F") },
            "the reasons should quote the temperature in the user's own units"
        )
    }

    // MARK: - Rotation

    func testRecentlyWornItemsScoreLowerThanNeglectedOnes() {
        let weather = TestWeather.make(feelsLikeC: 18)
        var wornToday = Garment(kind: .tShirt, name: "Worn tee", colorHex: "#FFFFFF")
        wornToday.lastWornAt = Date()
        let neglected = Garment(kind: .tShirt, name: "Neglected tee", colorHex: "#FFFFFF")

        let wornScore = OutfitEngine.garmentScore(wornToday, occasion: .casual, weather: weather)
        let neglectedScore = OutfitEngine.garmentScore(neglected, occasion: .casual, weather: weather)
        XCTAssertGreaterThan(neglectedScore, wornScore)
    }

    func testScoresStayInRange() {
        for occasion in Occasion.allCases {
            for temp in [-15.0, 0, 12, 22, 31, 42] {
                let result = OutfitEngine.recommend(
                    wardrobe: wardrobe, occasion: occasion, weather: TestWeather.make(feelsLikeC: temp)
                )
                for outfit in result.outfits {
                    XCTAssertTrue((0...1).contains(outfit.score),
                                  "\(occasion.title) at \(temp)C scored \(outfit.score)")
                }
            }
        }
    }
}
