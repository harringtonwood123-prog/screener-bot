import SwiftUI

struct RootView: View {
    @Environment(WardrobeStore.self) private var store

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            ClosetView()
                .tabItem { Label("My Closet", systemImage: "square.grid.2x2.fill") }

            ShopView()
                .tabItem { Label("Add to Closet", systemImage: "bag.fill") }
        }
        .tint(Theme.accent)
        .fullScreenCover(isPresented: .constant(store.needsOnboarding)) {
            OnboardingView()
        }
        .task {
            // Only reach for the weather once the user is through onboarding,
            // so the system prompt appears on the screen that explains it.
            if !store.needsOnboarding && store.weatherState == .idle {
                await store.refreshWeather()
            }
        }
    }
}
