import Foundation

/// The "what am I doing today" buttons on the home screen.
/// Each case carries the rules the recommender scores against.
enum Occasion: String, Codable, CaseIterable, Identifiable {
    case casual
    case businessCasual
    case formal
    case gym
    case running
    case dateNight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .casual: return "Casual"
        case .businessCasual: return "Business Casual"
        case .formal: return "Formal"
        case .gym: return "Gym"
        case .running: return "Running"
        case .dateNight: return "Date Night"
        }
    }

    var subtitle: String {
        switch self {
        case .casual: return "Errands, friends, weekend"
        case .businessCasual: return "Office, meetings, campus"
        case .formal: return "Interview, wedding, dinner"
        case .gym: return "Lifting, classes, training"
        case .running: return "Runs, cardio, outdoors"
        case .dateNight: return "Drinks, dinner, going out"
        }
    }

    var symbol: String {
        switch self {
        case .casual: return "figure.wave"
        case .businessCasual: return "briefcase.fill"
        case .formal: return "suit.heart.fill"
        case .gym: return "dumbbell.fill"
        case .running: return "figure.run"
        case .dateNight: return "wineglass.fill"
        }
    }

    /// Accent colour as an RGB hex, used for the tile on the home screen.
    var tintHex: String {
        switch self {
        case .casual: return "#3B82F6"
        case .businessCasual: return "#0F766E"
        case .formal: return "#1E293B"
        case .gym: return "#EA580C"
        case .running: return "#16A34A"
        case .dateNight: return "#9333EA"
        }
    }

    /// Acceptable formality band for garments in this outfit.
    var formalityRange: ClosedRange<Int> {
        switch self {
        case .casual: return 1...3
        case .businessCasual: return 3...5
        case .formal: return 4...5
        case .gym: return 0...1
        case .running: return 0...1
        case .dateNight: return 2...5
        }
    }

    /// The formality we aim for; garments closest to this score best.
    var idealFormality: Int {
        switch self {
        case .casual: return 2
        case .businessCasual: return 4
        case .formal: return 5
        case .gym: return 0
        case .running: return 0
        case .dateNight: return 3
        }
    }

    /// Sport occasions want athletic kit; everything else actively does not.
    var wantsAthletic: Bool {
        switch self {
        case .gym, .running: return true
        case .casual, .businessCasual, .formal, .dateNight: return false
        }
    }

    /// Outerwear is worth suggesting even in mild weather for these.
    var layersWell: Bool {
        switch self {
        case .businessCasual, .formal, .dateNight, .casual: return true
        case .gym, .running: return false
        }
    }

    /// Points to subtract from the target warmth, because you generate your own
    /// heat while training. Dressing for 12C on a run means dressing like it's 20C.
    var warmthAdjustment: Int {
        switch self {
        case .running: return -3
        case .gym: return -2
        case .casual, .businessCasual, .formal, .dateNight: return 0
        }
    }

    /// How much the weather should drive the pick, 0...1.
    /// Running outdoors is dominated by conditions; a formal dinner indoors much less so.
    var weatherWeight: Double {
        switch self {
        case .running: return 1.0
        case .casual: return 0.9
        case .gym: return 0.5
        case .businessCasual: return 0.7
        case .dateNight: return 0.6
        case .formal: return 0.5
        }
    }
}
