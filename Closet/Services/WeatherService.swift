import Foundation

/// Fetches conditions from Open-Meteo.
///
/// Deliberately keyless: Open-Meteo needs no API key, no account and no billing
/// setup for non-commercial use, so the app works the moment it's installed.
enum WeatherService {

    enum WeatherError: LocalizedError {
        case badResponse
        case decoding

        var errorDescription: String? {
            switch self {
            case .badResponse: return "Couldn't reach the weather service."
            case .decoding: return "The weather service sent something unexpected."
            }
        }
    }

    private struct Response: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let apparent_temperature: Double
            let weather_code: Int
            let wind_speed_10m: Double
        }
        struct Daily: Decodable {
            let temperature_2m_max: [Double]
            let temperature_2m_min: [Double]
            let precipitation_probability_max: [Int?]
        }
        let current: Current
        let daily: Daily
    }

    static func fetch(
        latitude: Double,
        longitude: Double,
        locationName: String,
        session: URLSession = .shared
    ) async throws -> WeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            .init(name: "latitude", value: String(format: "%.4f", latitude)),
            .init(name: "longitude", value: String(format: "%.4f", longitude)),
            .init(name: "current", value: "temperature_2m,apparent_temperature,weather_code,wind_speed_10m"),
            .init(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
            .init(name: "timezone", value: "auto"),
            .init(name: "forecast_days", value: "1")
        ]
        guard let url = components.url else { throw WeatherError.badResponse }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw WeatherError.badResponse
        }

        guard let decoded = try? JSONDecoder().decode(Response.self, from: data) else {
            throw WeatherError.decoding
        }

        return WeatherSnapshot(
            temperatureC: decoded.current.temperature_2m,
            feelsLikeC: decoded.current.apparent_temperature,
            highC: decoded.daily.temperature_2m_max.first ?? decoded.current.temperature_2m,
            lowC: decoded.daily.temperature_2m_min.first ?? decoded.current.temperature_2m,
            precipitationChance: decoded.daily.precipitation_probability_max.first.flatMap { $0 } ?? 0,
            windKph: decoded.current.wind_speed_10m,
            code: decoded.current.weather_code,
            locationName: locationName,
            fetchedAt: Date()
        )
    }
}
