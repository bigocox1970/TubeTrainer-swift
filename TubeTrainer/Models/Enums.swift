import SwiftUI

// MARK: - Muscle / body categories

enum MuscleCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case core = "Core"
    case fullBody = "Full Body"
    case cardio = "Cardio"
    case mobility = "Mobility / Warm-up"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .mobility: return "Mobility"
        case .fullBody: return "Full Body"
        default: return rawValue
        }
    }

    var symbol: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .shoulders: return "figure.arms.open"
        case .biceps, .triceps: return "dumbbell.fill"
        case .quadriceps, .hamstrings, .glutes, .calves: return "figure.strengthtraining.functional"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.mixed.cardio"
        case .cardio: return "figure.run"
        case .mobility: return "figure.flexibility"
        }
    }
}

// MARK: - Equipment

enum Equipment: String, Codable, CaseIterable, Identifiable, Hashable {
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case cable = "Cable"
    case bodyweight = "Bodyweight"
    case kettlebell = "Kettlebell"
    case band = "Band"
    case other = "Other"

    var id: String { rawValue }
}

// MARK: - Coaching content

enum VideoProvider: String, Codable {
    case youtube
}

enum VideoContentType: String, Codable {
    case video
    case short

    var label: String {
        switch self {
        case .video: return "Video"
        case .short: return "Short"
        }
    }
}

// MARK: - Set type

enum SetType: String, Codable, CaseIterable {
    case working = "Working"
    case warmup = "Warm-up"

    var abbrev: String {
        switch self {
        case .working: return "W"
        case .warmup: return "•"
        }
    }
}

// MARK: - Units

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case kg
    case lb

    var id: String { rawValue }
    var label: String { rawValue }

    /// Sensible increment for +/- steppers.
    var step: Double { self == .kg ? 2.5 : 5 }
    var smallStep: Double { self == .kg ? 1.25 : 2.5 }
}

// MARK: - Appearance preference

enum AppearancePreference: String, Codable, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .dark: return "Dark"
        case .light: return "Light"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark: return .dark
        case .light: return .light
        }
    }
}

// MARK: - Experience level

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case new
    case some
    case experienced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: return "New to training"
        case .some: return "Some experience"
        case .experienced: return "Experienced"
        }
    }

    var blurb: String {
        switch self {
        case .new: return "We'll keep set targets simple."
        case .some: return "A balanced starting point."
        case .experienced: return "You know your way around."
        }
    }
}

// MARK: - Training structure templates

enum TrainingStructure: String, Codable, CaseIterable, Identifiable {
    case fullBody
    case upperLower
    case pushPullLegs
    case bodyPart
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fullBody: return "Full Body"
        case .upperLower: return "Upper / Lower"
        case .pushPullLegs: return "Push / Pull / Legs"
        case .bodyPart: return "Body Part Split"
        case .custom: return "Build My Own"
        }
    }

    var blurb: String {
        switch self {
        case .fullBody: return "One session hits everything. Great 2–3× per week."
        case .upperLower: return "Alternate upper- and lower-body days."
        case .pushPullLegs: return "The classic 3-day strength split."
        case .bodyPart: return "A focused day per muscle group."
        case .custom: return "Start empty and build it your way."
        }
    }

    var symbol: String {
        switch self {
        case .fullBody: return "figure.mixed.cardio"
        case .upperLower: return "arrow.up.arrow.down"
        case .pushPullLegs: return "figure.strengthtraining.traditional"
        case .bodyPart: return "square.grid.2x2"
        case .custom: return "slider.horizontal.3"
        }
    }
}
