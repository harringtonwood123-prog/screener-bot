import SwiftUI

/// First run. Three steps, in this order:
/// welcome and sign-up -> location permission -> starting wardrobe.
///
/// Sign-up is required before the app can be used, which is what was asked for.
/// Note that App Store guideline 5.1.1(v) restricts requiring an account for
/// features that don't need one, and everything here runs on-device. To make
/// the step skippable, add a button that calls `store.signUp(name: "", email: "")`
/// — or better, see README for what a real account would involve.
struct OnboardingView: View {
    @Environment(WardrobeStore.self) private var store

    enum Step {
        case welcome
        case signUp
        case location
        case wardrobe
    }

    @State private var step: Step = .welcome

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()

            switch step {
            case .welcome:
                WelcomeStep { step = .signUp }
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .signUp:
                SignUpStep { name, email in
                    store.signUp(name: name, email: email)
                    step = .location
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            case .location:
                LocationStep { step = .wardrobe }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .wardrobe:
                WardrobeStep()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.35), value: step)
        .interactiveDismissDisabled()
    }
}

// MARK: - Step 1: Welcome

struct WelcomeStep: View {
    var onContinue: () -> Void

    private let points: [(String, String, String)] = [
        ("camera.viewfinder", "Scan your clothes", "Point the camera at an item and we work out what it is and what colour it is."),
        ("sun.max.fill", "We check your weather", "Recommendations match the conditions where you actually are."),
        ("paintpalette.fill", "And what goes together", "Every pick comes with a plain reason, not a score.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            LogoMark(size: 104)
                .shadow(color: .black.opacity(0.18), radius: 22, y: 10)

            Text("Closet")
                .font(Theme.display(40))
                .foregroundStyle(Theme.ink)
                .padding(.top, Theme.Space.loose)

            Text("Stop deciding what to wear")
                .font(Theme.body)
                .foregroundStyle(Theme.inkSoft)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: Theme.Space.loose) {
                ForEach(points, id: \.0) { symbol, title, detail in
                    HStack(alignment: .top, spacing: Theme.Space.normal) {
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.accent)
                            .frame(width: 32, height: 32)
                            .background(Theme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(title)
                                .font(Theme.heading)
                                .foregroundStyle(Theme.ink)
                            Text(detail)
                                .font(Theme.caption)
                                .foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.top, Theme.Space.section)
            .padding(.horizontal, Theme.Space.tight)

            Spacer()

            Button(action: onContinue) {
                Text("Get started").primaryAction()
            }
        }
        .padding(.horizontal, Theme.Space.loose)
        .padding(.bottom, Theme.Space.section)
    }
}

// MARK: - Step 3: Location

struct LocationStep: View {
    @Environment(WardrobeStore.self) private var store
    var onDone: () -> Void

    @State private var asking = false
    @State private var wasDenied = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 128, height: 128)
                Image(systemName: "location.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(Theme.accent)
            }

            Text("Where are you?")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
                .padding(.top, Theme.Space.loose)

            Text("We use your location once a session to look up the forecast, so the outfit suits the actual weather rather than a guess.")
                .font(Theme.body)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.top, Theme.Space.snug)
                .padding(.horizontal, Theme.Space.snug)

            VStack(alignment: .leading, spacing: Theme.Space.snug) {
                assurance("lock.fill", "Your location never leaves the app except as coordinates sent to the weather service.")
                assurance("eye.slash.fill", "It isn't stored, logged or linked to you.")
            }
            .padding(.top, Theme.Space.loose)
            .surfaceCard()
            .padding(.top, Theme.Space.loose)

            if wasDenied {
                Text("No problem — we'll assume mild conditions. You can turn location on later in Settings.")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.caution)
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.Space.normal)
            }

            Spacer()

            VStack(spacing: Theme.Space.snug) {
                Button {
                    Task {
                        asking = true
                        let granted = await store.requestLocationPermission()
                        asking = false
                        if granted {
                            Task { await store.refreshWeather() }
                            onDone()
                        } else {
                            wasDenied = true
                        }
                    }
                } label: {
                    Group {
                        if asking {
                            ProgressView().tint(.white)
                        } else {
                            Text(wasDenied ? "Try again" : "Use my location")
                        }
                    }
                    .primaryAction()
                }
                .disabled(asking)

                Button(action: onDone) {
                    Text("Not now").secondaryAction()
                }
            }
        }
        .padding(.horizontal, Theme.Space.loose)
        .padding(.bottom, Theme.Space.section)
    }

    private func assurance(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.snug) {
            Image(systemName: symbol)
                .font(.caption)
                .foregroundStyle(Theme.positive)
                .frame(width: 18)
            Text(text)
                .font(Theme.caption)
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Step 4: Starting wardrobe

struct WardrobeStep: View {
    @Environment(WardrobeStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.teal.opacity(0.14))
                    .frame(width: 128, height: 128)
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(Theme.teal)
            }

            Text(store.profile.map { "You're set, \($0.firstName)" } ?? "You're set")
                .font(Theme.display(30))
                .foregroundStyle(Theme.ink)
                .padding(.top, Theme.Space.loose)

            Text("Start with a sample closet to see how it works, or go straight to adding your own clothes.")
                .font(Theme.body)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.top, Theme.Space.snug)

            Spacer()

            VStack(spacing: Theme.Space.snug) {
                Button {
                    store.loadSampleWardrobe()
                    store.hasOnboarded = true
                    store.save()
                } label: {
                    Text("Try a sample closet").primaryAction()
                }

                Button {
                    store.hasOnboarded = true
                    store.save()
                } label: {
                    Text("I'll add my own").secondaryAction()
                }
            }
        }
        .padding(.horizontal, Theme.Space.loose)
        .padding(.bottom, Theme.Space.section)
    }
}
