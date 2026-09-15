import SwiftUI

struct RootView: View {
    @Environment(WardrobeStore.self) private var store
    @State private var showingWelcome = false

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            ClosetView()
                .tabItem { Label("My Closet", systemImage: "square.grid.2x2.fill") }

            ShopView()
                .tabItem { Label("Add to Closet", systemImage: "bag.fill") }
        }
        .task {
            if store.weatherState == .idle {
                await store.refreshWeather()
            }
        }
        .onAppear {
            if !store.hasOnboarded && store.garments.isEmpty {
                showingWelcome = true
            }
        }
        .sheet(isPresented: $showingWelcome) {
            WelcomeView()
        }
    }
}

/// First-run screen. Offers a sample wardrobe so the app can demonstrate itself
/// before the user has photographed anything.
struct WelcomeView: View {
    @Environment(WardrobeStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "tshirt.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(spacing: 10) {
                Text("Stop deciding what to wear")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Add your clothes once. Then just tap what you're doing today, and we'll pick an outfit that suits the weather and actually goes together.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    store.loadSampleWardrobe()
                    store.hasOnboarded = true
                    store.save()
                    dismiss()
                } label: {
                    Text("Try it with a sample closet")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    store.hasOnboarded = true
                    store.save()
                    dismiss()
                } label: {
                    Text("Start empty — I'll add my own")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .interactiveDismissDisabled()
    }
}
