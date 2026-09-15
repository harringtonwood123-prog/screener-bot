import Foundation

/// A product a partner brand pays to place against a matching wardrobe gap.
struct PartnerProduct: Identifiable, Hashable {
    let id: String
    let brand: String
    let title: String
    let kind: GarmentKind
    let colorHex: String
    let priceText: String
    /// Where tapping the card sends the user. In production this carries the
    /// affiliate tracking parameters supplied by the partner network.
    let url: URL
    /// Disclosed in the UI. Required by the FTC and by App Store review.
    let isSponsored: Bool
}

/// Supplies products to show against wardrobe gaps.
///
/// The catalogue below is PLACEHOLDER SAMPLE DATA — the brands are real names but
/// the products, prices and links are invented, and the URLs are plain homepages
/// with no affiliate tracking. Nothing here earns revenue as written.
///
/// To make this a real revenue channel, replace `sample` with a feed from an
/// affiliate network (Rakuten, Awin, Skimlinks, Amazon Associates) and keep the
/// `matches(gap:)` logic, which is what makes a placement relevant rather than random.
/// See MONETIZATION.md for the integration steps.
enum PartnerCatalog {

    static func products(for gap: WardrobeGap) -> [PartnerProduct] {
        let exact = sample.filter { $0.kind == gap.kind }
        if !exact.isEmpty { return exact }
        // Fall back to anything in the same slot so a gap is never left empty.
        return sample.filter { $0.kind.slot == gap.kind.slot }
    }

    static let sample: [PartnerProduct] = [
        PartnerProduct(
            id: "rain-01", brand: "Uniqlo", title: "Packable Rain Shell",
            kind: .rainJacket, colorHex: "#1F3A5F", priceText: "£49.90",
            url: URL(string: "https://www.uniqlo.com")!, isSponsored: true
        ),
        PartnerProduct(
            id: "rain-02", brand: "Decathlon", title: "Waterproof Hiking Jacket",
            kind: .rainJacket, colorHex: "#2F4F4F", priceText: "£39.99",
            url: URL(string: "https://www.decathlon.co.uk")!, isSponsored: false
        ),
        PartnerProduct(
            id: "ox-01", brand: "Charles Tyrwhitt", title: "Non-Iron Oxford Shirt",
            kind: .oxfordShirt, colorHex: "#C9DCEB", priceText: "£39.95",
            url: URL(string: "https://www.charlestyrwhitt.com")!, isSponsored: true
        ),
        PartnerProduct(
            id: "chino-01", brand: "Uniqlo", title: "Slim-Fit Chino",
            kind: .chinos, colorHex: "#C3B091", priceText: "£34.90",
            url: URL(string: "https://www.uniqlo.com")!, isSponsored: false
        ),
        PartnerProduct(
            id: "knit-01", brand: "COS", title: "Merino Crew Knit",
            kind: .sweater, colorHex: "#6B705C", priceText: "£69.00",
            url: URL(string: "https://www.cos.com")!, isSponsored: true
        ),
        PartnerProduct(
            id: "loaf-01", brand: "Clarks", title: "Leather Penny Loafer",
            kind: .loafers, colorHex: "#3B2314", priceText: "£80.00",
            url: URL(string: "https://www.clarks.co.uk")!, isSponsored: false
        ),
        PartnerProduct(
            id: "run-01", brand: "ASICS", title: "Neutral Road Running Shoe",
            kind: .runningShoes, colorHex: "#1E90FF", priceText: "£95.00",
            url: URL(string: "https://www.asics.com")!, isSponsored: true
        ),
        PartnerProduct(
            id: "tee-01", brand: "Everlane", title: "Organic Cotton Crew Tee",
            kind: .tShirt, colorHex: "#FFFFFF", priceText: "£28.00",
            url: URL(string: "https://www.everlane.com")!, isSponsored: false
        ),
        PartnerProduct(
            id: "atee-01", brand: "Decathlon", title: "Breathable Training Tee",
            kind: .athleticTee, colorHex: "#D9534F", priceText: "£12.99",
            url: URL(string: "https://www.decathlon.co.uk")!, isSponsored: false
        ),
        PartnerProduct(
            id: "jean-01", brand: "Levi's", title: "511 Slim Jean",
            kind: .jeans, colorHex: "#3B5E8C", priceText: "£95.00",
            url: URL(string: "https://www.levi.com")!, isSponsored: true
        ),
        PartnerProduct(
            id: "sneak-01", brand: "Veja", title: "Low-Top Leather Sneaker",
            kind: .sneakers, colorHex: "#F2F2F2", priceText: "£110.00",
            url: URL(string: "https://www.veja-store.com")!, isSponsored: false
        ),
        PartnerProduct(
            id: "trou-01", brand: "SUITSUPPLY", title: "Wool Dress Trouser",
            kind: .dressTrousers, colorHex: "#1C1C1C", priceText: "£139.00",
            url: URL(string: "https://suitsupply.com")!, isSponsored: true
        ),
        PartnerProduct(
            id: "blaz-01", brand: "Reiss", title: "Slim Wool Blazer",
            kind: .blazer, colorHex: "#1A2B4C", priceText: "£248.00",
            url: URL(string: "https://www.reiss.com")!, isSponsored: true
        ),
        PartnerProduct(
            id: "shorts-01", brand: "Gymshark", title: "Training Short 7\"",
            kind: .athleticShorts, colorHex: "#111111", priceText: "£28.00",
            url: URL(string: "https://www.gymshark.com")!, isSponsored: false
        ),
        PartnerProduct(
            id: "belt-01", brand: "Anderson's", title: "Woven Leather Belt",
            kind: .belt, colorHex: "#3B2314", priceText: "£95.00",
            url: URL(string: "https://www.andersonsbelts.com")!, isSponsored: false
        )
    ]
}
