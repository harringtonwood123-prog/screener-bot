import Foundation
import CoreLocation

/// One-shot location lookup wrapped in async/await.
///
/// `CLLocationManager` can call its delegate more than once for a single request,
/// so the continuation is cleared before it is resumed — resuming twice traps.
final class LocationProvider: NSObject, CLLocationManagerDelegate {

    enum LocationError: LocalizedError {
        case denied
        case unavailable

        var errorDescription: String? {
            switch self {
            case .denied:
                return "Location is off, so we can't check your weather. You can turn it on in Settings."
            case .unavailable:
                return "Couldn't work out where you are."
            }
        }
    }

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }

    func requestLocation() async throws -> CLLocation {
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            throw LocationError.denied
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            if manager.authorizationStatus == .notDetermined {
                manager.requestWhenInUseAuthorization()
            } else {
                manager.requestLocation()
            }
        }
    }

    /// Reverse-geocode to something short enough for the header, e.g. "Manchester".
    func placeName(for location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else {
            return "Your area"
        }
        return placemark.locality
            ?? placemark.subAdministrativeArea
            ?? placemark.administrativeArea
            ?? "Your area"
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            finish(.failure(LocationError.denied))
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finish(.failure(LocationError.unavailable))
            return
        }
        finish(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finish(.failure(error))
    }

    private func finish(_ result: Result<CLLocation, Error>) {
        guard let continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }
}
