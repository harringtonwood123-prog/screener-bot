import Foundation

/// One item of clothing the user owns.
struct Garment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var kind: GarmentKind
    /// Free text the user can edit, e.g. "Navy oxford". Defaults to the kind name.
    var name: String
    /// Dominant colour sampled from the photo, as "#RRGGBB".
    var colorHex: String
    /// Secondary colour for patterned items. Nil for solids.
    var secondaryColorHex: String?
    /// Filename inside the app's images directory. Nil if the user skipped the photo.
    var imageFilename: String?
    /// User overrides — default to the kind's values but can be tuned per item.
    var warmthOverride: Int?
    var isWaterResistant: Bool
    var isFavourite: Bool = false
    var lastWornAt: Date?
    var addedAt: Date = Date()

    init(
        id: UUID = UUID(),
        kind: GarmentKind,
        name: String? = nil,
        colorHex: String,
        secondaryColorHex: String? = nil,
        imageFilename: String? = nil,
        warmthOverride: Int? = nil,
        isWaterResistant: Bool? = nil,
        isFavourite: Bool = false,
        lastWornAt: Date? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.name = name ?? kind.displayName
        self.colorHex = colorHex
        self.secondaryColorHex = secondaryColorHex
        self.imageFilename = imageFilename
        self.warmthOverride = warmthOverride
        self.isWaterResistant = isWaterResistant ?? kind.isWaterResistantByDefault
        self.isFavourite = isFavourite
        self.lastWornAt = lastWornAt
        self.addedAt = addedAt
    }

    var slot: GarmentSlot { kind.slot }
    var warmth: Int { warmthOverride ?? kind.warmth }
    var formality: Int { kind.formality }
    var breathability: Int { kind.breathability }
    var color: HSBColor { HSBColor(hex: colorHex) }

    /// Days since this was last worn. Large (or nil-backed 99) when it has been a while,
    /// which nudges the recommender toward clothes that are sitting unused.
    var daysSinceWorn: Int {
        guard let lastWornAt else { return 99 }
        let seconds = Date().timeIntervalSince(lastWornAt)
        return max(0, Int(seconds / 86_400))
    }
}
