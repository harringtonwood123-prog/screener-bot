import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(WardrobeStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var confirmingClear = false
    @State private var confirmingSignOut = false

    var body: some View {
        // `@Bindable` is what lets a Picker write back to an @Observable model
        // that arrived through the environment.
        @Bindable var store = store

        NavigationStack {
            Form {
                if let profile = store.profile {
                    Section {
                        HStack(spacing: Theme.Space.normal) {
                            LogoMark(size: 52)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(profile.name)
                                    .font(Theme.heading)
                                    .foregroundStyle(Theme.ink)
                                Text(profile.email)
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.inkSoft)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                    } footer: {
                        Text("Stored on this iPhone only. There is no server, so nothing has been uploaded.")
                    }
                }

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

                Section {
                    Button("Sign out", role: .destructive) {
                        confirmingSignOut = true
                    }
                } footer: {
                    Text("Signing out clears your name and email from this device. Your clothes stay put.")
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
            .confirmationDialog(
                "Sign out?",
                isPresented: $confirmingSignOut,
                titleVisibility: .visible
            ) {
                Button("Sign out", role: .destructive) {
                    store.signOut()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You'll be asked to sign up again next time you open the app.")
            }
        }
    }
}
