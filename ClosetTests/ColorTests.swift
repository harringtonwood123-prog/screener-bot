import XCTest
@testable import Closet

/// Colour naming and pairing. Several of these encode bugs that were caught
/// before first build; they exist so the same mistakes can't come back.
final class ColorTests: XCTestCase {

    // MARK: - Naming

    func testEverydayColorNames() {
        let expectations: [(String, String)] = [
            ("#1A2B4C", "navy"),
            ("#000000", "black"),
            ("#FFFFFF", "white"),
            ("#808080", "grey"),
            ("#36454F", "charcoal"),
            ("#C3B091", "camel"),
            ("#556B2F", "olive"),
            ("#2E4B3C", "forest green"),
            ("#800020", "burgundy"),
            ("#B7410E", "rust"),
            ("#FF7F50", "coral"),
            ("#4A6FA5", "blue"),
            ("#D9534F", "red"),
            ("#FFD700", "yellow")
        ]
        for (hex, expected) in expectations {
            XCTAssertEqual(HSBColor(hex: hex).name, expected, "wrong name for \(hex)")
        }
    }

    /// Regression: a dark blue-grey was reported as "navy", and a deep maroon
    /// as "pink", because saturation wasn't part of those decisions.
    func testDarkDesaturatedIsCharcoalNotNavy() {
        XCTAssertEqual(HSBColor(hex: "#36454F").name, "charcoal")
    }

    func testDeepSaturatedRedIsBurgundyNotPink() {
        XCTAssertEqual(HSBColor(hex: "#800020").name, "burgundy")
    }

    // MARK: - Parsing

    func testHexRoundTrip() {
        for hex in ["#1A2B4C", "#FFFFFF", "#000000", "#D9534F"] {
            XCTAssertEqual(HSBColor(hex: hex).hex, hex)
        }
    }

    func testShorthandAndMalformedHex() {
        XCTAssertEqual(HSBColor(hex: "#FFF").hex, "#FFFFFF")
        XCTAssertEqual(HSBColor(hex: "fff").hex, "#FFFFFF")
        // Unparseable input must not crash; it falls back to mid grey.
        XCTAssertEqual(HSBColor(hex: "nonsense").name, "grey")
    }

    func testHueDistanceWrapsAroundTheWheel() {
        let red = HSBColor(hue: 10, saturation: 1, brightness: 1)
        let alsoRed = HSBColor(hue: 350, saturation: 1, brightness: 1)
        XCTAssertEqual(red.hueDistance(to: alsoRed), 20, accuracy: 0.001)
    }

    // MARK: - Neutrality

    func testMenswearNeutralsCountAsNeutral() {
        for hex in ["#1A2B4C", "#C3B091", "#556B2F", "#808080", "#000000", "#FFFFFF"] {
            XCTAssertTrue(HSBColor(hex: hex).isNeutral, "\(hex) should read as a neutral")
        }
    }

    func testStatementColoursAreNotNeutral() {
        for hex in ["#D9534F", "#FF7A1A", "#4B0082", "#A3E635"] {
            XCTAssertFalse(HSBColor(hex: hex).isNeutral, "\(hex) should not read as a neutral")
        }
    }

    // MARK: - Harmony

    /// Regression: classic opposites sit roughly 120-145 degrees apart in HSB,
    /// not the 180 an artist's wheel implies. Red with green was being
    /// classified as a weak match because the bands were set for the wrong wheel.
    func testRedAndGreenReadAsDeliberateContrast() {
        let harmony = ColorTheory.harmony(HSBColor(hex: "#D9534F"), HSBColor(hex: "#2E8B57"))
        XCTAssertEqual(harmony, .complementary)
    }

    /// Regression: all-black, and a white tee with white sneakers, were scoring
    /// worst of everything tested — flagged "flat" when both are classic looks.
    func testTwoNeutralsAreNeverFlat() {
        let pairs = [("#111111", "#141414"), ("#FFFFFF", "#F2F2F2"), ("#1A2B4C", "#808080")]
        for (a, b) in pairs {
            let harmony = ColorTheory.harmony(HSBColor(hex: a), HSBColor(hex: b))
            XCTAssertEqual(harmony, .neutralPair, "\(a) with \(b) should be a valid neutral pairing")
        }
    }

    func testAwkwardGapIsDiscord() {
        // Mid-orange against yellow-green: the genuinely difficult pairing.
        let harmony = ColorTheory.harmony(
            HSBColor(hue: 30, saturation: 0.9, brightness: 0.9),
            HSBColor(hue: 80, saturation: 0.9, brightness: 0.9)
        )
        XCTAssertEqual(harmony, .discord)
    }

    // MARK: - Whole-outfit scoring

    /// Regression: `neutralAnchor` scored 1.00, the maximum, so any
    /// neutral-plus-colour pairing outranked every carefully composed outfit.
    func testNoSinglePairingCanScoreTheMaximum() {
        for harmony in [ColorHarmony.neutralAnchor, .neutralPair, .complementary, .analogous] {
            XCTAssertLessThan(harmony.score, 1.0, "\(harmony) should leave headroom")
        }
    }

    func testWellComposedOutfitsOutrankClashes() {
        let good = ColorTheory.evaluate([
            ("top", HSBColor(hex: "#1A2B4C")),
            ("bottom", HSBColor(hex: "#C3B091")),
            ("shoes", HSBColor(hex: "#5C4033"))
        ]).score

        let loud = ColorTheory.evaluate([
            ("top", HSBColor(hex: "#FF7A1A")),
            ("bottom", HSBColor(hex: "#8E44AD")),
            ("shoes", HSBColor(hex: "#A3E635"))
        ]).score

        XCTAssertGreaterThan(good, loud)
        XCTAssertGreaterThan(good, 0.8, "navy, camel and brown is a safe combination")
        XCTAssertLessThan(loud, 0.6, "three loud colours at once should be marked down")
    }

    func testAllBlackIsAcceptable() {
        let score = ColorTheory.evaluate([
            ("top", HSBColor(hex: "#111111")),
            ("bottom", HSBColor(hex: "#141414")),
            ("shoes", HSBColor(hex: "#0E0E0E"))
        ]).score
        XCTAssertGreaterThan(score, 0.7, "all-black is a deliberate look, not a failed match")
    }

    func testEvaluateProducesAnExplanation() {
        let (_, notes) = ColorTheory.evaluate([
            ("top", HSBColor(hex: "#1A2B4C")),
            ("bottom", HSBColor(hex: "#B7410E"))
        ])
        XCTAssertFalse(notes.isEmpty)
        let headline = ColorTheory.headline(from: notes)
        XCTAssertNotNil(headline)
        XCTAssertFalse(headline?.isEmpty ?? true)
    }
}
