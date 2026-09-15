import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(WardrobeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var confirmingClear = false

    var body: some View {
        // `@Bindable` is what lets a Picker write back to an @Observable model
        // that arrived through the environment.
        @Bindable var store = store

        NavigationStack {
            Form {
                Section {
                    Picker("Units", selection: $store.unitSystem) {
                        ForEach(UnitSystem.allCases) { system in
                            VStack(alignment: .leading) {
                                Text(system.title)
                                Text(system.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(system)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Temperature")
                } footer: {
                    Text("Only changes what you see. Recommendations are worked out the same way either way.")
                }

                Section {
                    LabeledContent("Location", value: store.weather.locationName)
                    LabeledContent(
                        "Now",
                        value: Units.temperatureWithSymbol(store.weather.temperatureC, in: store.unitSystem)
                    )
                    LabeledContent(
                        "Feels like",
                        value: Units.temperatureWithSymbol(store.weather.feelsLikeC, in: store.unitSystem)
                    )
                    LabeledContent("Conditions", value: store.weather.summary)

                    Button("Refresh now") {
                        Task { await store.refreshWeather() }
                    }

                    if case .failed = store.weatherState {
                        Button("Open iOS Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                    }
                } header: {
                    Text("Weather")
                } footer: {
                    Text("Conditions come from Open-Meteo, using your location. Nothing about your location is stored or sent anywhere else.")
                }

                Section {
                    LabeledContent("Items in closet", value: "\(store.garments.count)")
                    Button("Load sample closet") {
                        store.loadSampleWardrobe()
                    }
                    Button("Remove everything", role: .destructive) {
                        confirmingClear = true
                    }
                } header: {
                    Text("Closet")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Remove all \(store.garments.count) items?",
                isPresented: $confirmingClear,
                titleVisibility: .visible
            ) {
                Button("Remove everything", role: .destructive) { store.clearAll() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This can't be undone.")
            }
        }
    }
}
