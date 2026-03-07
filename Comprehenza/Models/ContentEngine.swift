import Foundation

// MARK: - Age Group
enum AgeGroup: Int, CaseIterable, Codable {
    case age5to6  = 1
    case age7to8  = 2
    case age9to10 = 3
    case age11to12 = 4
    case age13to14 = 5
    case age15to16 = 6
    case age17to18 = 7
    case age19to21 = 8
    case age22plus = 9

    var label: String {
        switch self {
        case .age5to6:   return "5–6 yrs"
        case .age7to8:   return "7–8 yrs"
        case .age9to10:  return "9–10 yrs"
        case .age11to12: return "11–12 yrs"
        case .age13to14: return "13–14 yrs"
        case .age15to16: return "15–16 yrs"
        case .age17to18: return "17–18 yrs"
        case .age19to21: return "19–21 yrs"
        case .age22plus: return "22+ yrs"
        }
    }

    static func from(age: Int) -> AgeGroup {
        switch age {
        case ...6:    return .age5to6
        case 7...8:   return .age7to8
        case 9...10:  return .age9to10
        case 11...12: return .age11to12
        case 13...14: return .age13to14
        case 15...16: return .age15to16
        case 17...18: return .age17to18
        case 19...21: return .age19to21
        default:      return .age22plus
        }
    }
}

// MARK: - Content Engine
struct ContentEngine {

    /// Returns a unique passage for a given day (1–30), difficulty level, and age group.
    /// No repetition within a 30-day cycle for the same level.
    static func passage(day: Int, level: DifficultyLevel, ageGroup: AgeGroup = .age9to10) -> Passage {
        let idx = ((day - 1) % 30)  // 0-based index, wraps for safety
        let bank: [Passage]
        switch level {
        case .beginner:     bank = PassageBank.beginner
        case .intermediate: bank = PassageBank.intermediate
        case .advanced:     bank = PassageBank.advanced
        case .pro:          bank = PassageBank.pro
        }
        guard idx < bank.count else {
            return bank[idx % bank.count]
        }
        return bank[idx]
    }

    /// Returns a passage for the Library browsing (random from level pool)
    static func libraryPassage(level: DifficultyLevel, category: ExerciseCategory) -> Passage {
        let bank: [Passage]
        switch level {
        case .beginner:     bank = PassageBank.beginner
        case .intermediate: bank = PassageBank.intermediate
        case .advanced:     bank = PassageBank.advanced
        case .pro:          bank = PassageBank.pro
        }
        // Rotate through bank by hashing the category to avoid always getting day-1
        let offset = category.hashValue % max(bank.count, 1)
        return bank[abs(offset) % bank.count]
    }

    /// Evaluation passage — always uses index 0 of the appropriate level
    static func evaluationPassage(level: DifficultyLevel) -> Passage {
        passage(day: 1, level: level)
    }
}

// MARK: - Passage Bank Container
struct PassageBank {
    static let beginner:     [Passage] = beginnerPassages
    static let intermediate: [Passage] = intermediatePassages
    static let advanced:     [Passage] = advancedPassages
    static let pro:          [Passage] = proPassages
}
