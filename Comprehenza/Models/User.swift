import Foundation

struct UserAccount: Codable, Identifiable {
    var id: String = UUID().uuidString
    var email: String
    var password: String  // stored as plain text for local demo
    var name: String
    var age: Int
    var avatar: Avatar
    var evaluationCompleted: Bool = false
    var evaluationResult: EvaluationResult?
    var categoryScores: CategoryScores = CategoryScores()
    var sessionHistory: [ProgressSession] = []
    var journeyDayIndex: Int = 0

    var overallCQ: Int {
        evaluationResult?.overallCQ ?? 0
    }

    var currentLevel: DifficultyLevel {
        DifficultyLevel.level(for: overallCQ)
    }
}

struct CategoryScores: Codable {
    var comprehension: Double = 0
    var vocabulary:    Double = 0
    var relearning:    Double = 0
    var fluency:       Double = 0

    var overall: Int {
        Int((comprehension + vocabulary + relearning + fluency).clamped(to: 0...400))
    }

    mutating func addMarks(for category: ExerciseCategory, delta: Double) {
        switch category {
        case .comprehension: comprehension = (comprehension + delta).clamped(to: 0...100)
        case .vocabulary:    vocabulary    = (vocabulary    + delta).clamped(to: 0...100)
        case .relearning:    relearning    = (relearning    + delta).clamped(to: 0...100)
        case .fluency:       fluency       = (fluency       + delta).clamped(to: 0...100)
        }
    }

    func score(for category: ExerciseCategory) -> Double {
        switch category {
        case .comprehension: return comprehension
        case .vocabulary:    return vocabulary
        case .relearning:    return relearning
        case .fluency:       return fluency
        }
    }
}

struct EvaluationResult: Codable {
    var comprehensionScore: Int  // 0-100
    var vocabularyScore:    Int  // 0-100
    var reLearningScore:    Int  // 0-100
    var fluencyScore:       Int  // 0-100
    var date: Date = Date()

    var overallCQ: Int {
        comprehensionScore + vocabularyScore + reLearningScore + fluencyScore
    }

    var level: DifficultyLevel {
        DifficultyLevel.level(for: overallCQ)
    }
}

struct ProgressSession: Codable, Identifiable {
    var id: String = UUID().uuidString
    var date: Date
    var comprehensionScore: Double
    var vocabularyScore: Double
    var reLearningScore: Double
    var fluencyScore: Double
    var overallCQ: Int
    var level: DifficultyLevel
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
