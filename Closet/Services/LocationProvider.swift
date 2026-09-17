import Foundation
import CoreLocation

/// Location access, wrapped in async/await.
///
/// Two separate awaits are supported — asking for permission, and asking for a
/// fix — and each keeps its own continuation. `CLLocationManager` can call a
/// delegate method more than once per request, so every continuation is cleared
/// before it is resumed; resuming twice traps.
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
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var permissionContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }

    var hasBeenAsked: Bool { manager.authorizationStatus != .notDetermined }

    var isAuthorized: Bool {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return true
        default: return false
        }
    }

    /// Shows the system permission prompt and waits for the answer.
    /// Returns immediately if the user has already been asked once — iOS will
    /// not show the prompt a second time.
    func requestPermission() async -> CLAuthorizationStatus {
        guard manager.authorizationStatus == .notDetermined else {
            return manager.authorizationStatus
        }
        return await withCheckedContinuation { continuation in
            self.permissionContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func requestLocation() async throws -> CLLocation {
        if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            throw LocationError.denied
        }
        if manager.authorizationStatus == .notDetermined {
            let status = await requestPermission()
            guard status == .authorizedWhenInUse || status == .authorizedAlways else {
                throw LocationError.denied
            }
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            manager.requestLocation()
        }
    }

    /// Reverse-geocode to something short enough for a header, e.g. "Austin".
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
        let status = manager.authorizationStatus
        guard status != .notDetermined else { return }

        // Answer whoever is waiting on the prompt.
        if let continuation = permissionContinuation {
            permissionContinuation = nil
            continuation.resume(returning: status)
        }

        // A refusal also ends any in-flight location request.
        if status == .denied || status == .restricted {
            finishLocation(.failure(LocationError.denied))
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            finishLocation(.failure(LocationError.unavailable))
            return
        }
        finishLocation(.success(location))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        finishLocation(.failure(error))
    }

    private func finishLocation(_ result: Result<CLLocation, Error>) {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil
        continuation.resume(with: result)
    }
}
