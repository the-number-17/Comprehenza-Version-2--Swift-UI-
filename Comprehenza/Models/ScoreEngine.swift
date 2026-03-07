import Foundation

// MARK: - Score Engine
/// Handles all mark calculations for evaluation + daily exercises
struct ScoreEngine {

    // MARK: Evaluation Scoring (0-100 per category)
    static func evaluationScore(correct: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int(Double(correct) / Double(total) * 100).clamped(to: 0...100)
    }

    // MARK: Daily Exercise Mark Delta
    /// Returns the positive delta for a correct answer from a given current score.
    /// Goal: 500 consecutive correct answers from currentScore → 400 (max)
    /// Formula: delta = (maxScore - currentScore) / 500
    static func markDelta(currentScore: Double, maxScore: Double = 100) -> Double {
        let remaining = maxScore - currentScore
        return remaining / 500.0
    }

    /// Returns the score change for a question attempt
    static func scoreChange(
        currentScore: Double,
        isCorrect: Bool,
        isSkipped: Bool,
        maxScore: Double = 100
    ) -> Double {
        if isSkipped { return 0 }
        let delta = markDelta(currentScore: currentScore, maxScore: maxScore)
        return isCorrect ? delta : -delta / 2
    }

    // MARK: CQ level check
    static func levelChanged(oldCQ: Int, newCQ: Int) -> Bool {
        DifficultyLevel.level(for: oldCQ) != DifficultyLevel.level(for: newCQ)
    }
}
