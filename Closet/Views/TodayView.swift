import SwiftUI

/// The home screen: today's weather, then one big button per occasion.
/// Two taps from opening the app to a recommendation.
struct TodayView: View {
    @Environment(WardrobeStore.self) private var store
    @State private var selected: Occasion?
    @State private var showingSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    WeatherHeader()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("What are you doing?")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(Occasion.allCases) { occasion in
                                Button {
                                    selected = occasion
                                } label: {
                                    OccasionTile(occasion: occasion)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if store.garments.isEmpty {
                        EmptyClosetPrompt()
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .refreshable { await store.refreshWeather() }
            .navigationDestination(item: $selected) { occasion in
                OutfitResultView(occasion: occasion)
            }
        }
    }
}

struct OccasionTile: View {
    let occasion: Occasion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: occasion.symbol)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color(hex: occasion.tintHex).opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(occasion.title)
                .font(.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(occasion.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
        .card()
    }
}

/// Weather strip at the top of the home screen.
struct WeatherHeader: View {
    @Environment(WardrobeStore.self) private var store

    var body: some View {
        VStack(spacing: 12) {
            switch store.weatherState {
            case .loading, .idle:
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Checking your weather…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            case .failed(let message):
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message)
                            .font(.subheadline)
                        Text("Using mild conditions for now — recommendations will still work.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

            case .loaded:
                HStack(spacing: 14) {
                    Image(systemName: store.weather.symbol)
                        .font(.system(size: 34))
                        .foregroundStyle(.tint)
                        .frame(width: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Units.temperature(store.weather.temperatureC, in: store.unitSystem)) in \(store.weather.locationName)")
                            .font(.headline)
                        Text("\(store.weather.summary) · feels like \(Units.temperature(store.weather.feelsLikeC, in: store.unitSystem))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("H \(Units.temperature(store.weather.highC, in: store.unitSystem))")
                            .font(.caption)
                        Text("L \(Units.temperature(store.weather.lowC, in: store.unitSystem))")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                if store.weather.expectsPrecipitation || store.weather.isWindy {
                    HStack(spacing: 14) {
                        if store.weather.expectsPrecipitation {
                            Label("\(store.weather.precipitationChance)% rain", systemImage: "umbrella.fill")
                        }
                        if store.weather.isWindy {
                            Label("\(Units.wind(store.weather.windKph, in: store.unitSystem)) wind", systemImage: "wind")
                        }
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .card()
    }
}

struct EmptyClosetPrompt: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.viewfinder")
                .font(.title)
                .foregroundStyle(.secondary)
            Text("Your closet is empty")
                .font(.headline)
            Text("Add a few clothes in the My Closet tab and we can start recommending outfits.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 24)
    }
}
