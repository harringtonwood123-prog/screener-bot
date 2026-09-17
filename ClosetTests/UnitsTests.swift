import XCTest
@testable import Closet

final class UnitsTests: XCTestCase {

    override func tearDown() {
        Units.stored = .automatic
        super.tearDown()
    }

    func testCelsiusToFahrenheit() {
        XCTAssertEqual(Units.fahrenheit(fromCelsius: 0), 32, accuracy: 0.001)
        XCTAssertEqual(Units.fahrenheit(fromCelsius: 100), 212, accuracy: 0.001)
        XCTAssertEqual(Units.fahrenheit(fromCelsius: -40), -40, accuracy: 0.001)
    }

    func testConversionRoundTrips() {
        for f in [0.0, 32, 72, 100, 106] {
            XCTAssertEqual(Units.fahrenheit(fromCelsius: Units.celsius(fromFahrenheit: f)), f, accuracy: 0.001)
        }
    }

    /// The case this was built for: someone in Austin on a 100F afternoon.
    /// Open-Meteo answers in Celsius; the screen has to say 100.
    func testAustinAfternoonReadsAsOneHundred() {
        let airTemp = Units.celsius(fromFahrenheit: 100)
        XCTAssertEqual(airTemp, 37.78, accuracy: 0.01)

        XCTAssertEqual(Units.temperature(airTemp, in: .imperial), "100°")
        XCTAssertEqual(Units.temperatureWithSymbol(airTemp, in: .imperial), "100°F")
        XCTAssertEqual(Units.temperatureWithSymbol(airTemp, in: .metric), "38°C")
    }

    func testWindConversion() {
        XCTAssertEqual(Units.wind(25, in: .metric), "25 km/h")
        XCTAssertEqual(Units.wind(25, in: .imperial), "16 mph")
    }

    func testExplicitPreferenceOverridesRegion() {
        XCTAssertTrue(Units.usesImperial(.imperial))
        XCTAssertFalse(Units.usesImperial(.metric))
    }

    func testPreferenceIsPersisted() {
        Units.stored = .imperial
        XCTAssertEqual(Units.stored, .imperial)
        Units.stored = .metric
        XCTAssertEqual(Units.stored, .metric)
    }

    /// Units are presentation only. The same conditions must produce the same
    /// recommendation whichever way the preference is set.
    func testUnitChoiceDoesNotChangeRecommendations() {
        let weather = TestWeather.make(feelsLikeC: 37.8)
        // One wardrobe, not two: SampleData mints fresh identifiers each time
        // it's read, so two reads could never compare equal.
        let closet = SampleData.wardrobe

        Units.stored = .metric
        let metric = OutfitEngine.recommend(
            wardrobe: closet, occasion: .casual, weather: weather, limit: 1
        )
        Units.stored = .imperial
        let imperial = OutfitEngine.recommend(
            wardrobe: closet, occasion: .casual, weather: weather, limit: 1
        )

        XCTAssertEqual(
            metric.outfits.first?.items.map(\.id),
            imperial.outfits.first?.items.map(\.id),
            "switching units must not change which clothes are picked"
        )
        XCTAssertEqual(metric.outfits.first?.score, imperial.outfits.first?.score)
    }
}

/// Shared helper for building conditions in tests.
enum TestWeather {
    static func make(
        feelsLikeC: Double,
        precipitationChance: Int = 0,
        windKph: Double = 8,
        highC: Double? = nil,
        lowC: Double? = nil,
        code: Int = 1
    ) -> WeatherSnapshot {
        WeatherSnapshot(
            temperatureC: feelsLikeC,
            feelsLikeC: feelsLikeC,
            highC: highC ?? feelsLikeC + 2,
            lowC: lowC ?? feelsLikeC - 2,
            precipitationChance: precipitationChance,
            windKph: windKph,
            code: code,
            locationName: "Testville",
            fetchedAt: Date()
        )
    }
}
