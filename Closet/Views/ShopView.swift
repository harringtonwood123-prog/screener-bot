import SwiftUI

/// Suggestions for what to buy next — driven by gaps the recommender actually hit,
/// not a generic product feed. This is where affiliate revenue would come from.
struct ShopView: View {
    @Environment(WardrobeStore.self) private var store
    @Environment(\.openURL) private var openURL

    private var gaps: [WardrobeGap] {
        WardrobeGaps.analyse(wardrobe: store.garments, weather: store.weather)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    let currentGaps = gaps

                    if store.garments.isEmpty {
                        placeholder(
                            icon: "bag",
                            title: "Add some clothes first",
                            message: "Once we know what you own, we can tell you what's missing."
                        )
                    } else if currentGaps.isEmpty {
                        placeholder(
                            icon: "checkmark.seal.fill",
                            title: "Your closet covers everything",
                            message: "We can dress you for every occasion in every forecast. Nothing to buy."
                        )
                    } else {
                        Text("Based on what you own, these would stretch your closet furthest.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(currentGaps) { gap in
                            GapSection(gap: gap) { product in
                                openURL(product.url)
                            }
                        }

                        AdSlotView()
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add to Closet")
        }
    }

    private func placeholder(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 46))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .card(padding: 28)
    }
}

struct GapSection: View {
    let gap: WardrobeGap
    var onTap: (PartnerProduct) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: gap.kind.slot.symbol)
                    .foregroundStyle(.tint)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text("A \(gap.kind.displayName.lowercased()) would help")
                        .font(.headline)
                    Text(gap.rationale)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            let products = PartnerCatalog.products(for: gap)
            if !products.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(products) { product in
                            Button { onTap(product) } label: {
                                ProductCard(product: product)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

struct ProductCard: View {
    let product: PartnerProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: product.colorHex))
                .frame(width: 128, height: 96)
                .overlay(
                    Image(systemName: product.kind.slot.symbol)
                        .font(.title2)
                        .foregroundStyle(HSBColor(hex: product.colorHex).contrastingForeground.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                )

            Text(product.brand)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            Text(product.title)
                .font(.caption)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(height: 30, alignment: .top)

            HStack(spacing: 6) {
                Text(product.priceText)
                    .font(.caption.bold())
                if product.isSponsored {
                    Text("Sponsored")
                        .font(.system(size: 8, weight: .semibold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 128, alignment: .leading)
    }
}
