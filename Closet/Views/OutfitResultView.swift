import SwiftUI

/// Shows the recommendation for an occasion, and — the point of the app —
/// explains why it works.
struct OutfitResultView: View {
    @Environment(WardrobeStore.self) private var store
    let occasion: Occasion

    @State private var index = 0
    @State private var result: OutfitEngine.Result?
    @State private var wornConfirmation = false

    private var outfit: Outfit? {
        guard let result, result.outfits.indices.contains(index) else { return nil }
        return result.outfits[index]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let result, !result.shortfall.isEmpty {
                    ShortfallCard(shortfall: result.shortfall, occasion: occasion)
                } else if let outfit {
                    OutfitCard(outfit: outfit)
                    WhyCard(outfit: outfit)
                    actions(for: outfit)
                    AdSlotView()
                } else {
                    ProgressView().padding(40)
                }
            }
            .padding(16)
        }
        .background(Theme.canvas)
        .navigationTitle(occasion.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: recompute)
        .alert("Logged", isPresented: $wornConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We'll rotate these pieces down the list for a while so you don't wear the same thing twice.")
        }
    }

    @ViewBuilder
    private func actions(for outfit: Outfit) -> some View {
        VStack(spacing: 12) {
            Button {
                store.markWorn(outfit)
                wornConfirmation = true
            } label: {
                Label("I'm wearing this", systemImage: "checkmark.circle.fill")
                    .primaryAction()
            }

            if let result, result.outfits.count > 1 {
                Button {
                    withAnimation { index = (index + 1) % result.outfits.count }
                } label: {
                    Label("Show me another", systemImage: "arrow.triangle.2.circlepath")
                        .secondaryAction()
                }

                Text("Option \(index + 1) of \(result.outfits.count)")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private func recompute() {
        index = 0
        result = store.recommend(for: occasion)
    }
}

/// The clothes themselves.
struct OutfitCard: View {
    let outfit: Outfit

    private var ordered: [Garment] {
        let order: [GarmentSlot] = [.outerwear, .top, .bottom, .shoes, .accessory]
        return order.compactMap { slot in outfit.items.first { $0.slot == slot } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(outfit.verdict)
                    .font(Theme.display(24))
                    .foregroundStyle(Theme.ink)
                Spacer()
                ScorePill(score: outfit.score)
            }

            HStack(spacing: 10) {
                ForEach(ordered) { garment in
                    VStack(spacing: 6) {
                        GarmentThumb(garment: garment, size: 74)
                        Text(garment.name)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.inkSoft)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .surfaceCard()
    }
}

struct ScorePill: View {
    let score: Double

    private var tint: Color {
        switch score {
        case 0.82...: return Theme.positive
        case 0.62..<0.82: return Theme.teal
        default: return Theme.caution
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(tint)
                .frame(width: 7, height: 7)
            Text("\(Int((score * 100).rounded()))")
                .font(Theme.caption.weight(.bold).monospacedDigit())
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(tint.opacity(0.14))
        .foregroundStyle(tint)
        .clipShape(Capsule())
    }
}

/// The explanation. This is what the user actually came for.
struct WhyCard: View {
    let outfit: Outfit

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Why this works")
                .font(Theme.heading)

            ForEach(outfit.reasons) { reason in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: reason.symbol)
                        .foregroundStyle(reason.tone.color)
                        .frame(width: 22)
                    Text(reason.text)
                        .font(Theme.body)
                        .foregroundStyle(reason.tone == .info ? .secondary : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .surfaceCard()
    }
}

/// Shown when the wardrobe can't produce a complete outfit for this occasion.
struct ShortfallCard: View {
    let shortfall: [GarmentSlot]
    let occasion: Occasion

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "questionmark.square.dashed")
                .font(.system(size: 44))
                .foregroundStyle(Theme.inkSoft)

            Text("Not enough for \(occasion.title.lowercased()) yet")
                .font(Theme.heading)
                .multilineTextAlignment(.center)

            Text("You'll need \(shortfall.map { $0.title.lowercased() }.joined(separator: " and ")) that suit this. Add some in My Closet, or see suggestions in Add to Closet.")
                .font(Theme.body)
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .surfaceCard(padding: Theme.Space.loose)
    }
}
