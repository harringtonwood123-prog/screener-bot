import SwiftUI

/// Home. Today's conditions, then one card per occasion.
/// Two taps from opening the app to a recommendation.
struct TodayView: View {
    @Environment(WardrobeStore.self) private var store
    @State private var selected: Occasion?
    @State private var showingSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Space.snug),
        GridItem(.flexible(), spacing: Theme.Space.snug)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Space.loose) {
                    WeatherHeader()

                    VStack(alignment: .leading, spacing: Theme.Space.snug) {
                        Text("What are you doing?")
                            .font(Theme.title(20))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: columns, spacing: Theme.Space.snug) {
                            ForEach(Occasion.allCases) { occasion in
                                Button { selected = occasion } label: {
                                    OccasionTile(occasion: occasion)
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                    }

                    if store.garments.isEmpty {
                        EmptyClosetPrompt()
                    }
                }
                .padding(Theme.Space.normal)
            }
            .background(Theme.canvas)
            .navigationTitle(greeting)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Theme.inkSoft)
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

    private var greeting: String {
        guard let name = store.profile?.firstName, !name.isEmpty else { return "Today" }
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning, \(name)"
        case 12..<18: return "Afternoon, \(name)"
        default: return "Evening, \(name)"
        }
    }
}

/// Gives cards a slight press-down, which makes the grid feel like buttons.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct OccasionTile: View {
    let occasion: Occasion

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.snug) {
            Image(systemName: occasion.symbol)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(
                    LinearGradient(
                        colors: [Color(hex: occasion.tintHex), Color(hex: occasion.tintHex).opacity(0.72)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))

            Spacer(minLength: 0)

            Text(occasion.title)
                .font(Theme.heading)
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(occasion.subtitle)
                .font(Theme.caption)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 152, alignment: .topLeading)
        .surfaceCard()
    }
}

/// Conditions strip. On a brand gradient so the top of the app has some colour.
struct WeatherHeader: View {
    @Environment(WardrobeStore.self) private var store

    var body: some View {
        VStack(spacing: Theme.Space.snug) {
            switch store.weatherState {
            case .loading, .idle:
                HStack(spacing: Theme.Space.snug) {
                    ProgressView().tint(.white)
                    Text("Checking your weather…")
                        .font(Theme.body)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                }

            case .failed(let message):
                HStack(alignment: .top, spacing: Theme.Space.snug) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message)
                            .font(Theme.body)
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Using mild conditions for now — recommendations still work.")
                            .font(Theme.caption)
                            .foregroundStyle(.white.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }

            case .loaded:
                HStack(spacing: Theme.Space.normal) {
                    Image(systemName: store.weather.symbol)
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 46)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(Units.temperature(store.weather.temperatureC, in: store.unitSystem))
                            .font(Theme.display(30))
                            .foregroundStyle(.white)
                        Text(store.weather.locationName)
                            .font(Theme.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(store.weather.summary)
                            .font(Theme.body.weight(.medium))
                            .foregroundStyle(.white)
                        Text("Feels \(Units.temperature(store.weather.feelsLikeC, in: store.unitSystem))")
                            .font(Theme.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("H \(Units.temperature(store.weather.highC, in: store.unitSystem))  L \(Units.temperature(store.weather.lowC, in: store.unitSystem))")
                            .font(Theme.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                if store.weather.expectsPrecipitation || store.weather.isWindy {
                    HStack(spacing: Theme.Space.normal) {
                        if store.weather.expectsPrecipitation {
                            chip("umbrella.fill", "\(store.weather.precipitationChance)% rain")
                        }
                        if store.weather.isWindy {
                            chip("wind", Units.wind(store.weather.windKph, in: store.unitSystem))
                        }
                        Spacer()
                    }
                }
            }
        }
        .padding(Theme.Space.normal)
        .frame(maxWidth: .infinity)
        .background(Theme.brandGradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .shadow(color: Theme.indigo.opacity(0.25), radius: 14, y: 6)
    }

    private func chip(_ symbol: String, _ text: String) -> some View {
        Label(text, systemImage: symbol)
            .font(Theme.caption.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.white.opacity(0.18))
            .clipShape(Capsule())
    }
}

struct EmptyClosetPrompt: View {
    var body: some View {
        VStack(spacing: Theme.Space.snug) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 32))
                .foregroundStyle(Theme.accent)
            Text("Your closet is empty")
                .font(Theme.heading)
                .foregroundStyle(Theme.ink)
            Text("Add a few clothes in My Closet and we can start recommending outfits.")
                .font(Theme.caption)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .surfaceCard(padding: Theme.Space.loose)
    }
}
