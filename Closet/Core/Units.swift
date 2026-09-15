import Foundation

/// Which units to show. Weather is always stored and reasoned about in metric —
/// the temperature bands in `TemperatureBand` are Celsius — and converted only
/// for display, so switching this never changes a recommendation.
enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    /// Follow the device's region: Fahrenheit and mph in the US, Celsius elsewhere.
    case automatic
    case metric
    case imperial

    var id: String { rawValue }

    var title: String {
        switch self {
        case .automatic: return "Automatic"
        case .metric: return "Celsius"
        case .imperial: return "Fahrenheit"
        }
    }

    var detail: String {
        switch self {
        case .automatic: return "Match my region"
        case .metric: return "°C and km/h"
        case .imperial: return "°F and mph"
        }
    }
}

/// Formats weather values for display.
enum Units {

    private static let defaultsKey = "closet.unitSystem"

    /// The user's saved choice. Defaults to `.automatic`.
    static var stored: UnitSystem {
        get {
            guard let raw = UserDefaults.standard.string(forKey: defaultsKey),
                  let system = UnitSystem(rawValue: raw) else { return .automatic }
            return system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }

    /// Resolves `.automatic` against the device's region.
    ///
    /// Only a handful of countries use Fahrenheit for weather, and they're the
    /// ones Foundation reports as the US measurement system. The UK reports as
    /// `.uk` — it uses miles for distance but Celsius for temperature — so it
    /// correctly falls through to metric here.
    static func usesImperial(_ system: UnitSystem = stored) -> Bool {
        switch system {
        case .metric: return false
        case .imperial: return true
        case .automatic:
            if #available(iOS 16.0, *) {
                return Locale.current.measurementSystem == .us
            }
            return false
        }
    }

    // MARK: - Temperature

    static func fahrenheit(fromCelsius c: Double) -> Double { c * 9 / 5 + 32 }
    static func celsius(fromFahrenheit f: Double) -> Double { (f - 32) * 5 / 9 }

    /// The rounded number to show, in whichever unit applies.
    static func temperatureValue(_ celsius: Double, in system: UnitSystem = stored) -> Int {
        Int((usesImperial(system) ? fahrenheit(fromCelsius: celsius) : celsius).rounded())
    }

    /// "100°" — the degree sign without the letter, for when context is obvious.
    static func temperature(_ celsius: Double, in system: UnitSystem = stored) -> String {
        "\(temperatureValue(celsius, in: system))°"
    }

    /// "100°F" — spelled out, for the first mention in a sentence.
    static func temperatureWithSymbol(_ celsius: Double, in system: UnitSystem = stored) -> String {
        "\(temperatureValue(celsius, in: system))°\(usesImperial(system) ? "F" : "C")"
    }

    // MARK: - Wind

    static func mph(fromKph kph: Double) -> Double { kph * 0.621371 }

    /// "15 mph" or "24 km/h".
    static func wind(_ kph: Double, in system: UnitSystem = stored) -> String {
        usesImperial(system)
            ? "\(Int(mph(fromKph: kph).rounded())) mph"
            : "\(Int(kph.rounded())) km/h"
    }
}
