import SwiftUI

@main
struct ClosetApp: App {
    @State private var store = WardrobeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
