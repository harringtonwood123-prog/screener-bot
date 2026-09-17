import XCTest
@testable import Closet

/// Gap analysis, the domain tables, and persistence.
final class WardrobeTests: XCTestCase {

    // MARK: - Gaps

    func testWardrobeWithNoRainwearIsToldSo() {
        let dry = SampleData.wardrobe.filter { !$0.isWaterResistant }
        let gaps = WardrobeGaps.analyse(wardrobe: dry, weather: TestWeather.make(feelsLikeC: 14))
        XCTAssertTrue(
            gaps.contains { $0.kind == .rainJacket },
            "a closet that sheds no water should be told to fix that"
        )
    }

    func testAWellStockedWardrobeHasNoUrgentGaps() {
        let gaps = WardrobeGaps.analyse(
            wardrobe: SampleData.wardrobe, weather: TestWeather.make(feelsLikeC: 18)
        )
        XCTAssertFalse(
            gaps.contains { $0.priority >= 90 },
            "the sample closet should not be missing anything critical: \(gaps.map(\.rationale))"
        )
    }

    func testMissingSlotsProduceHighPriorityGaps() {
        let topsOnly = SampleData.wardrobe.filter { $0.slot == .top }
        let gaps = WardrobeGaps.analyse(wardrobe: topsOnly, weather: TestWeather.make(feelsLikeC: 18))
        XCTAssertFalse(gaps.isEmpty)
        XCTAssertTrue(gaps.contains { $0.priority >= 90 })
    }

    func testEveryGapExplainsItself() {
        let gaps = WardrobeGaps.analyse(wardrobe: [], weather: TestWeather.make(feelsLikeC: 18))
        for gap in gaps {
            XCTAssertFalse(gap.rationale.isEmpty, "a suggestion without a reason is just an advert")
        }
    }

    func testEveryGapCanBeShopped() {
        let gaps = WardrobeGaps.analyse(wardrobe: [], weather: TestWeather.make(feelsLikeC: 18))
        for gap in gaps {
            XCTAssertFalse(
                PartnerCatalog.products(for: gap).isEmpty,
                "no products offered for a \(gap.kind.displayName) gap"
            )
        }
    }

    // MARK: - Domain tables

    func testEveryGarmentKindIsSelfConsistent() {
        for kind in GarmentKind.allCases {
            XCTAssertFalse(kind.displayName.isEmpty, "\(kind.rawValue) has no display name")
            XCTAssertTrue((0...5).contains(kind.warmth), "\(kind.rawValue) warmth out of range")
            XCTAssertTrue((0...5).contains(kind.formality), "\(kind.rawValue) formality out of range")
            XCTAssertTrue((0...5).contains(kind.breathability), "\(kind.rawValue) breathability out of range")
        }
    }

    func testAthleticKitIsAlwaysSportAppropriate() {
        for kind in GarmentKind.allCases where kind.isAthletic {
            XCTAssertTrue(kind.suitsSport, "\(kind.rawValue) is athletic but not marked sport-appropriate")
        }
    }

    func testEveryOccasionCanBeDressedForBySomeGarment() {
        let weather = TestWeather.make(feelsLikeC: 18)
        for occasion in Occasion.allCases {
            for slot in GarmentSlot.required {
                let candidates = GarmentKind.allCases
                    .filter { $0.slot == slot }
                    .map { Garment(kind: $0, colorHex: "#808080") }
                    .filter { OutfitEngine.garmentScore($0, occasion: occasion, weather: weather) > 0 }
                XCTAssertFalse(
                    candidates.isEmpty,
                    "no \(slot.title.lowercased()) in the whole catalogue suits \(occasion.title)"
                )
            }
        }
    }

    // MARK: - Temperature bands

    func testTemperatureBandsAreOrdered() {
        let samples: [(Double, TemperatureBand)] = [
            (-5, .freezing), (4, .cold), (13, .cool), (20, .mild), (26, .warm), (35, .hot)
        ]
        for (temp, expected) in samples {
            XCTAssertEqual(TemperatureBand(feelsLikeC: temp), expected, "\(temp)C banded wrongly")
        }
        XCTAssertLessThan(TemperatureBand.freezing, TemperatureBand.hot)
    }

    func testColderBandsWantMoreWarmth() {
        let ordered = TemperatureBand.allCases.sorted()
        for (colder, warmer) in zip(ordered, ordered.dropFirst()) {
            XCTAssertGreaterThanOrEqual(
                colder.targetWarmth, warmer.targetWarmth,
                "\(colder.label) should want at least as much warmth as \(warmer.label)"
            )
        }
    }

    // MARK: - Persistence

    func testWardrobeSurvivesARestart() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("wardrobe-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let store = WardrobeStore(fileURL: url)
        store.add(Garment(kind: .tShirt, name: "Test tee", colorHex: "#FFFFFF"))
        store.add(Garment(kind: .jeans, name: "Test jeans", colorHex: "#3B5E8C"))
        XCTAssertEqual(store.garments.count, 2)

        let reopened = WardrobeStore(fileURL: url)
        XCTAssertEqual(reopened.garments.count, 2)
        XCTAssertEqual(Set(reopened.garments.map(\.name)), ["Test tee", "Test jeans"])
    }

    func testMarkingAnOutfitWornUpdatesTheWardrobe() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("wardrobe-worn-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }

        let store = WardrobeStore(fileURL: url)
        for garment in SampleData.wardrobe { store.add(garment) }

        let result = store.recommend(for: .casual)
        guard let outfit = result.outfits.first else {
            XCTFail("the sample closet should produce a casual outfit")
            return
        }
        store.markWorn(outfit)

        for item in outfit.items {
            let stored = store.garments.first { $0.id == item.id }
            XCTAssertNotNil(stored?.lastWornAt, "\(item.name) should have been marked worn")
            XCTAssertEqual(stored?.daysSinceWorn, 0)
        }
    }

    func testGarmentEncodesAndDecodes() throws {
        let original = Garment(
            kind: .rainJacket, name: "Test shell", colorHex: "#1F3A5F", warmthOverride: 2
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Garment.self, from: data)
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.kind, original.kind)
        XCTAssertEqual(decoded.warmth, 2)
        XCTAssertTrue(decoded.isWaterResistant)
    }
}
