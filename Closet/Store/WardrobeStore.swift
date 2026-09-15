import Foundation
import Observation

/// The app's single source of truth: the wardrobe, the weather, and the
/// recommendation currently on screen. Persists to a JSON file in Application Support.
@Observable
final class WardrobeStore {

    private(set) var garments: [Garment] = []
    private(set) var weather: WeatherSnapshot = .placeholder
    var weatherState: LoadState = .idle
    /// Set once the user has seen the sample wardrobe and either kept or cleared it.
    var hasOnboarded: Bool = false

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let locationProvider = LocationProvider()
    private let fileURL: URL

    init(fileURL: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.fileURL = fileURL ?? base.appendingPathComponent("wardrobe.json")
        load()
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
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(Persisted.self, from: data) else { return }
        garments = decoded.garments
        hasOnboarded = decoded.hasOnboarded
    }

    func save() {
        let payload = Persisted(garments: garments, hasOnboarded: hasOnboarded)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
