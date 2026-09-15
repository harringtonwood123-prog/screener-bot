import Foundation

/// Current conditions plus the day's range, always in metric internally —
/// `TemperatureBand` reasons in Celsius. `Units` converts for display only, so
/// switching to Fahrenheit never changes which outfit is recommended.
struct WeatherSnapshot: Codable, Equatable {
    var temperatureC: Double
    /// What it actually feels like with wind and humidity — this is what drives layering.
    var feelsLikeC: Double
    var highC: Double
    var lowC: Double
    /// 0...100
    var precipitationChance: Int
    var windKph: Double
    var code: Int
    var locationName: String
    var fetchedAt: Date

    /// Rain, sleet, snow or thunder likely enough to dress for.
    var expectsPrecipitation: Bool { precipitationChance >= 40 }
    var isWindy: Bool { windKph >= 25 }
    /// The day swings enough that a layer you can remove is worth it.
    var hasBigSwing: Bool { (highC - lowC) >= 9 }

    var summary: String {
        switch code {
        case 0: return "Clear"
        case 1, 2: return "Partly cloudy"
        case 3: return "Overcast"
        case 45, 48: return "Foggy"
        case 51, 53, 55, 56, 57: return "Drizzle"
        case 61, 63, 65, 66, 67: return "Rain"
        case 71, 73, 75, 77: return "Snow"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95, 96, 99: return "Thunderstorms"
        default: return "Mixed"
        }
    }

    var symbol: String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82: return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.sun.fill"
        }
    }

    /// Bucket the feels-like temperature into a layering band.
    var band: TemperatureBand { TemperatureBand(feelsLikeC: feelsLikeC) }

    /// A neutral placeholder used before the first fetch resolves.
    static let placeholder = WeatherSnapshot(
        temperatureC: 18, feelsLikeC: 18, highC: 21, lowC: 14,
        precipitationChance: 0, windKph: 8, code: 1,
        locationName: "—", fetchedAt: .distantPast
    )
}

/// The layering bands the recommender targets.
enum TemperatureBand: Int, Comparable, CaseIterable {
    case freezing   // below 0
    case cold       // 0...9
    case cool       // 10...16
    case mild       // 17...22
    case warm       // 23...28
    case hot        // 29+

    init(feelsLikeC t: Double) {
        switch t {
        case ..<0: self = .freezing
        case 0..<10: self = .cold
        case 10..<17: self = .cool
        case 17..<23: self = .mild
        case 23..<29: self = .warm
        default: self = .hot
        }
    }

    static func < (lhs: TemperatureBand, rhs: TemperatureBand) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Total warmth points an outfit should carry in this band.
    var targetWarmth: Int {
        switch self {
        case .freezing: return 13
        case .cold: return 11
        case .cool: return 8
        case .mild: return 6
        case .warm: return 4
        case .hot: return 3
        }
    }

    /// Below this band a jacket is effectively mandatory.
    var needsOuterwear: Bool {
        switch self {
        case .freezing, .cold, .cool: return true
        case .mild, .warm, .hot: return false
        }
    }

    var label: String {
        switch self {
        case .freezing: return "Freezing"
        case .cold: return "Cold"
        case .cool: return "Cool"
        case .mild: return "Mild"
        case .warm: return "Warm"
        case .hot: return "Hot"
        }
    }
}
