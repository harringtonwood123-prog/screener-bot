import Foundation

/// Where a garment sits on the body. An outfit needs one of each required slot.
enum GarmentSlot: String, Codable, CaseIterable, Identifiable {
    case top
    case bottom
    case outerwear
    case shoes
    case accessory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .top: return "Tops"
        case .bottom: return "Bottoms"
        case .outerwear: return "Outerwear"
        case .shoes: return "Shoes"
        case .accessory: return "Accessories"
        }
    }

    var symbol: String {
        switch self {
        case .top: return "tshirt"
        case .bottom: return "rectangle.portrait"
        case .outerwear: return "wind"
        case .shoes: return "shoeprints.fill"
        case .accessory: return "eyeglasses"
        }
    }

    /// Every outfit must contain these slots.
    static let required: [GarmentSlot] = [.top, .bottom, .shoes]
}

/// A specific type of clothing. Each kind carries sensible defaults so that
/// scanning a photo can fill in warmth / formality without the user typing anything.
enum GarmentKind: String, Codable, CaseIterable, Identifiable {
    // Tops
    case tShirt, longSleeveTee, tankTop, athleticTee, poloShirt
    case dressShirt, oxfordShirt, flannelShirt
    case sweater, hoodie, sweatshirt

    // Bottoms
    case jeans, chinos, dressTrousers, cargoPants
    case shorts, athleticShorts, joggers, leggings

    // Outerwear
    case denimJacket, bomberJacket, blazer, windbreaker
    case rainJacket, fleece, pufferJacket, overcoat

    // Shoes
    case sneakers, runningShoes, trainers, dressShoes
    case loafers, boots, sandals

    // Accessories
    case cap, beanie, scarf, belt, watch, sunglasses

    var id: String { rawValue }

    var slot: GarmentSlot {
        switch self {
        case .tShirt, .longSleeveTee, .tankTop, .athleticTee, .poloShirt,
             .dressShirt, .oxfordShirt, .flannelShirt,
             .sweater, .hoodie, .sweatshirt:
            return .top
        case .jeans, .chinos, .dressTrousers, .cargoPants,
             .shorts, .athleticShorts, .joggers, .leggings:
            return .bottom
        case .denimJacket, .bomberJacket, .blazer, .windbreaker,
             .rainJacket, .fleece, .pufferJacket, .overcoat:
            return .outerwear
        case .sneakers, .runningShoes, .trainers, .dressShoes,
             .loafers, .boots, .sandals:
            return .shoes
        case .cap, .beanie, .scarf, .belt, .watch, .sunglasses:
            return .accessory
        }
    }

    var displayName: String {
        switch self {
        case .tShirt: return "T-Shirt"
        case .longSleeveTee: return "Long Sleeve Tee"
        case .tankTop: return "Tank Top"
        case .athleticTee: return "Athletic Tee"
        case .poloShirt: return "Polo Shirt"
        case .dressShirt: return "Dress Shirt"
        case .oxfordShirt: return "Oxford Shirt"
        case .flannelShirt: return "Flannel Shirt"
        case .sweater: return "Sweater"
        case .hoodie: return "Hoodie"
        case .sweatshirt: return "Sweatshirt"
        case .jeans: return "Jeans"
        case .chinos: return "Chinos"
        case .dressTrousers: return "Dress Trousers"
        case .cargoPants: return "Cargo Pants"
        case .shorts: return "Shorts"
        case .athleticShorts: return "Athletic Shorts"
        case .joggers: return "Joggers"
        case .leggings: return "Leggings"
        case .denimJacket: return "Denim Jacket"
        case .bomberJacket: return "Bomber Jacket"
        case .blazer: return "Blazer"
        case .windbreaker: return "Windbreaker"
        case .rainJacket: return "Rain Jacket"
        case .fleece: return "Fleece"
        case .pufferJacket: return "Puffer Jacket"
        case .overcoat: return "Overcoat"
        case .sneakers: return "Sneakers"
        case .runningShoes: return "Running Shoes"
        case .trainers: return "Gym Trainers"
        case .dressShoes: return "Dress Shoes"
        case .loafers: return "Loafers"
        case .boots: return "Boots"
        case .sandals: return "Sandals"
        case .cap: return "Cap"
        case .beanie: return "Beanie"
        case .scarf: return "Scarf"
        case .belt: return "Belt"
        case .watch: return "Watch"
        case .sunglasses: return "Sunglasses"
        }
    }

    /// How much heat this traps, 0 (barely anything) to 5 (arctic).
    /// Used against the "feels like" temperature to build a warm-enough outfit.
    var warmth: Int {
        switch self {
        case .tankTop, .sandals, .sunglasses, .watch, .belt: return 0
        case .tShirt, .athleticTee, .poloShirt, .shorts, .athleticShorts,
             .dressShirt, .oxfordShirt, .cap, .leggings: return 1
        case .longSleeveTee, .chinos, .jeans, .dressTrousers, .cargoPants,
             .joggers, .sneakers, .runningShoes, .trainers, .dressShoes,
             .loafers, .windbreaker: return 2
        case .flannelShirt, .sweatshirt, .hoodie, .denimJacket, .bomberJacket,
             .blazer, .rainJacket, .boots, .scarf, .beanie: return 3
        case .sweater, .fleece: return 4
        case .pufferJacket, .overcoat: return 5
        }
    }

    /// 0 = gym floor, 5 = black tie. Outfits keep a tight spread on this.
    var formality: Int {
        switch self {
        case .athleticTee, .athleticShorts, .leggings, .trainers, .runningShoes: return 0
        case .tankTop, .hoodie, .sweatshirt, .joggers, .shorts, .sandals, .cap, .beanie: return 1
        case .tShirt, .longSleeveTee, .jeans, .cargoPants, .sneakers,
             .denimJacket, .windbreaker, .fleece: return 2
        case .poloShirt, .flannelShirt, .sweater, .chinos, .boots, .bomberJacket,
             .rainJacket, .pufferJacket, .scarf, .sunglasses, .watch: return 3
        case .oxfordShirt, .loafers, .belt: return 4
        case .dressShirt, .dressTrousers, .dressShoes, .blazer, .overcoat: return 5
        }
    }

    /// How well it sheds heat. High values win on hot days.
    var breathability: Int {
        switch self {
        case .tankTop, .athleticTee, .athleticShorts, .shorts, .sandals: return 5
        case .tShirt, .poloShirt, .runningShoes, .leggings, .sunglasses, .cap: return 4
        case .longSleeveTee, .oxfordShirt, .dressShirt, .chinos, .trainers, .sneakers: return 3
        case .jeans, .flannelShirt, .cargoPants, .joggers, .dressTrousers,
             .loafers, .dressShoes, .sweater, .blazer, .denimJacket, .watch, .belt: return 2
        case .hoodie, .sweatshirt, .fleece, .boots, .bomberJacket, .beanie, .scarf: return 1
        case .pufferJacket, .overcoat, .rainJacket, .windbreaker: return 0
        }
    }

    /// Shrugs off rain without help.
    var isWaterResistantByDefault: Bool {
        switch self {
        case .rainJacket, .windbreaker, .pufferJacket, .boots: return true
        default: return false
        }
    }

    /// Cuts wind. Matters more than raw warmth on gusty days.
    var blocksWind: Bool {
        switch self {
        case .windbreaker, .rainJacket, .pufferJacket, .overcoat, .bomberJacket, .denimJacket:
            return true
        default: return false
        }
    }

    /// Kinds you'd actually train in. The inverse of `isAthletic`: that keeps gym
    /// kit out of the office, this keeps a denim jacket off a 5k.
    var suitsSport: Bool {
        switch self {
        case .tShirt, .longSleeveTee, .tankTop, .athleticTee,
             .hoodie, .sweatshirt,
             .shorts, .athleticShorts, .joggers, .leggings,
             .windbreaker, .rainJacket, .fleece,
             .sneakers, .runningShoes, .trainers,
             .cap, .beanie, .watch, .sunglasses:
            return true
        default: return false
        }
    }

    /// Kinds that only make sense for sport. Keeps gym gear out of the office.
    var isAthletic: Bool {
        switch self {
        case .athleticTee, .athleticShorts, .leggings, .runningShoes, .trainers, .joggers:
            return true
        default: return false
        }
    }
}

