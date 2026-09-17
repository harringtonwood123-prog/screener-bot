import Foundation

/// A starter wardrobe so a new install has something to recommend from
/// before the user has scanned anything. Offered on first launch, easy to clear.
enum SampleData {
    static var wardrobe: [Garment] {
        [
            Garment(kind: .oxfordShirt, name: "Navy oxford", colorHex: "#1A2B4C"),
            Garment(kind: .tShirt, name: "White tee", colorHex: "#FFFFFF"),
            Garment(kind: .tShirt, name: "Forest green tee", colorHex: "#2E4B3C"),
            Garment(kind: .sweater, name: "Grey sweater", colorHex: "#9AA0A6"),
            Garment(kind: .hoodie, name: "Black hoodie", colorHex: "#111111"),
            Garment(kind: .athleticTee, name: "Red training tee", colorHex: "#D9534F"),
            Garment(kind: .dressShirt, name: "White dress shirt", colorHex: "#F5F5F5"),
            Garment(kind: .flannelShirt, name: "Rust flannel", colorHex: "#B7410E"),

            Garment(kind: .chinos, name: "Khaki chinos", colorHex: "#C3B091"),
            Garment(kind: .jeans, name: "Blue jeans", colorHex: "#3B5E8C"),
            Garment(kind: .dressTrousers, name: "Black trousers", colorHex: "#1C1C1C"),
            Garment(kind: .shorts, name: "Olive shorts", colorHex: "#556B2F"),
            Garment(kind: .athleticShorts, name: "Black gym shorts", colorHex: "#111111"),
            Garment(kind: .joggers, name: "Charcoal joggers", colorHex: "#36454F"),

            Garment(kind: .sneakers, name: "White sneakers", colorHex: "#F2F2F2"),
            Garment(kind: .runningShoes, name: "Blue runners", colorHex: "#1E90FF"),
            Garment(kind: .dressShoes, name: "Brown dress shoes", colorHex: "#3B2314"),
            Garment(kind: .boots, name: "Brown boots", colorHex: "#5C4033"),

            Garment(kind: .rainJacket, name: "Navy rain jacket", colorHex: "#1F3A5F"),
            Garment(kind: .pufferJacket, name: "Black puffer", colorHex: "#111111"),
            Garment(kind: .blazer, name: "Navy blazer", colorHex: "#1A2B4C"),
            Garment(kind: .denimJacket, name: "Denim jacket", colorHex: "#4A6FA5")
        ]
    }
}
