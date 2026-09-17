import Foundation
import Observation

/// The app's single source of truth: the wardrobe, the weather, and the
/// recommendation currently on screen. Persists to a JSON file in Application Support.
@Observable
final class WardrobeStore {

    private(set) var garments: [Garment] = []
    /// Nil until the user signs up. Drives whether onboarding is shown.
    private(set) var profile: UserProfile?
    private(set) var weather: WeatherSnapshot = .placeholder
    var weatherState: LoadState = .idle
    /// Set once the user has seen the sample wardrobe and either kept or cleared it.
    var hasOnboarded: Bool = false

    /// Which units to display weather in. Views read this so that changing it
    /// re-renders them; `Units` reads the same value back out of UserDefaults
    /// for the engine's explanation strings, which have no view to observe.
    var unitSystem: UnitSystem = Units.stored {
        didSet { Units.stored = unitSystem }
    }

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    let locationProvider = LocationProvider()
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.fileURL = fileURL ?? base.appendingPathComponent("wardrobe.json")
        load()
    }

    /// Onboarding runs until the user has signed up *and* chosen a starting
    /// closet, so a half-finished first run resumes rather than being skipped.
    var needsOnboarding: Bool { profile == nil || !hasOnboarded }

    // MARK: - Account

    func signUp(name: String, email: String) {
        profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            signedUpAt: Date()
        )
        save()
    }

    func signOut() {
        profile = nil
        hasOnboarded = false
        save()
    }

    /// Shows the system location prompt. Returns whether we ended up with access.
    @MainActor
    func requestLocationPermission() async -> Bool {
        _ = await locationProvider.requestPermission()
        return locationProvider.isAuthorized
    }

    // MARK: - Wardrobe

    func add(_ garment: Garment) {
        garments.append(garment)
        save()
    }

    func update(_ garment: Garment) {
        guard let index = garments.firstIndex(where: { $0.id == garment.id }) else { return }
        garments[index] = garment
        save()
    }

    func delete(_ garment: Garment) {
        ImageStore.delete(garment.imageFilename)
        garments.removeAll { $0.id == garment.id }
        save()
    }

    func toggleFavourite(_ garment: Garment) {
        guard let index = garments.firstIndex(where: { $0.id == garment.id }) else { return }
        garments[index].isFavourite.toggle()
        save()
    }

    /// Records that an outfit was actually worn, so those pieces drop down the
    /// ranking for a while and something else gets a turn.
    func markWorn(_ outfit: Outfit) {
        let now = Date()
        for item in outfit.items {
            if let index = garments.firstIndex(where: { $0.id == item.id }) {
                garments[index].lastWornAt = now
            }
        }
        save()
    }

    func garments(in slot: GarmentSlot) -> [Garment] {
        garments.filter { $0.slot == slot }.sorted { $0.addedAt > $1.addedAt }
    }

    func loadSampleWardrobe() {
        garments = SampleData.wardrobe
        save()
    }

    func clearAll() {
        for garment in garments { ImageStore.delete(garment.imageFilename) }
        garments = []
        save()
    }

    // MARK: - Recommendations

    func recommend(for occasion: Occasion) -> OutfitEngine.Result {
        OutfitEngine.recommend(wardrobe: garments, occasion: occasion, weather: weather)
    }

    // MARK: - Weather

    @MainActor
    func refreshWeather() async {
        weatherState = .loading
        do {
            let location = try await locationProvider.requestLocation()
            let name = await locationProvider.placeName(for: location)
            weather = try await WeatherService.fetch(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                locationName: name
            )
            weatherState = .loaded
        } catch {
            weatherState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Persistence

    private struct Persisted: Codable {
        var garments: [Garment]
        var hasOnboarded: Bool
        /// Optional so that a file written before sign-up existed still decodes.
        var profile: UserProfile?
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(Persisted.self, from: data) else { return }
        garments = decoded.garments
        hasOnboarded = decoded.hasOnboarded
        profile = decoded.profile
    }

    func save() {
        let payload = Persisted(garments: garments, hasOnboarded: hasOnboarded, profile: profile)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
