import Foundation
import Combine
import SwiftUI

// MARK: - App State (root environment object)
class AppState: ObservableObject {
    @Published var isShowingSplash: Bool = true
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: UserAccount?

    // Persistence key
    private let usersKey    = "com.comprehenza.users"
    private let sessionKey  = "com.comprehenza.session"

    init() {
        // Show splash for 2.5 seconds then check session
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { self.isShowingSplash = false }
            self.restoreSession()
        }
    }

    // MARK: - Persistence helpers
    var allUsers: [UserAccount] {
        get {
            guard let data = UserDefaults.standard.data(forKey: usersKey),
                  let users = try? JSONDecoder().decode([UserAccount].self, from: data)
            else { return [] }
            return users
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: usersKey)
            }
        }
    }

    func saveUser(_ user: UserAccount) {
        var users = allUsers
        if let idx = users.firstIndex(where: { $0.id == user.id }) {
            users[idx] = user
        } else {
            users.append(user)
        }
        allUsers = users

        // If this is the current user, refresh
        if currentUser?.id == user.id {
            DispatchQueue.main.async { self.currentUser = user }
        }
    }

    private func restoreSession() {
        guard let id = UserDefaults.standard.string(forKey: sessionKey),
              let user = allUsers.first(where: { $0.id == id })
        else { return }
        currentUser = user
        isLoggedIn  = true
    }

    // MARK: - Auth Actions
    func login(email: String, password: String) -> String? {
        guard let user = allUsers.first(where: {
            $0.email.lowercased() == email.lowercased() && $0.password == password
        }) else {
            return "Invalid email or password."
        }
        currentUser = user
        isLoggedIn  = true
        UserDefaults.standard.set(user.id, forKey: sessionKey)
        return nil
    }

    /// Returns nil on success, error string on failure
    func register(email: String, password: String, name: String = "", age: Int = 12) -> String? {
        guard !email.isEmpty, !password.isEmpty else { return "Please fill in all fields." }
        guard email.contains("@") else { return "Invalid email address." }
        guard password.count >= 6 else { return "Password must be at least 6 characters." }
        guard allUsers.first(where: { $0.email.lowercased() == email.lowercased() }) == nil else {
            return "An account with this email already exists."
        }
        let newUser = UserAccount(email: email, password: password, name: name, age: age, avatar: .owl)
        saveUser(newUser)
        currentUser = newUser
        isLoggedIn  = true
        UserDefaults.standard.set(newUser.id, forKey: sessionKey)
        return nil
    }

    func forgotPassword(email: String) -> Bool {
        allUsers.contains(where: { $0.email.lowercased() == email.lowercased() })
    }

    func changePassword(current: String, new: String) -> String? {
        guard var user = currentUser else { return "Not logged in." }
        guard user.password == current else { return "Current password is incorrect." }
        guard new.count >= 6 else { return "New password must be at least 6 characters." }
        user.password = new
        saveUser(user)
        return nil
    }

    func logout() {
        currentUser = nil
        isLoggedIn  = false
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    // MARK: - Profile Update
    func updateProfile(name: String, age: Int, avatar: Avatar) {
        guard var user = currentUser else { return }
        user.name   = name
        user.age    = age
        user.avatar = avatar
        saveUser(user)
    }

    // MARK: - Evaluation
    func saveEvaluationResult(_ result: EvaluationResult) {
        guard var user = currentUser else { return }
        user.evaluationCompleted = true
        user.evaluationResult    = result
        // Seed category scores from evaluation
        user.categoryScores.comprehension = Double(result.comprehensionScore)
        user.categoryScores.vocabulary    = Double(result.vocabularyScore)
        user.categoryScores.relearning    = Double(result.reLearningScore)
        user.categoryScores.fluency       = Double(result.fluencyScore)
        // Save session to history
        let session = ProgressSession(
            date: Date(),
            comprehensionScore: Double(result.comprehensionScore),
            vocabularyScore:    Double(result.vocabularyScore),
            reLearningScore:    Double(result.reLearningScore),
            fluencyScore:       Double(result.fluencyScore),
            overallCQ:          result.overallCQ,
            level:              result.level
        )
        user.sessionHistory.append(session)
        saveUser(user)
    }

    // MARK: - Apply exercise score
    func applyExerciseMark(category: ExerciseCategory, isCorrect: Bool, isSkipped: Bool) {
        guard var user = currentUser else { return }
        let currentCQ   = user.overallCQ
        let current     = user.categoryScores.score(for: category)
        let delta       = ScoreEngine.scoreChange(currentScore: current, isCorrect: isCorrect, isSkipped: isSkipped)
        user.categoryScores.addMarks(for: category, delta: delta)

        // Record session snapshot
        let session = ProgressSession(
            date: Date(),
            comprehensionScore: user.categoryScores.comprehension,
            vocabularyScore:    user.categoryScores.vocabulary,
            reLearningScore:    user.categoryScores.relearning,
            fluencyScore:       user.categoryScores.fluency,
            overallCQ:          user.categoryScores.overall,
            level:              DifficultyLevel.level(for: user.categoryScores.overall)
        )
        user.sessionHistory.append(session)
        saveUser(user)

        // Notify if level changed
        if ScoreEngine.levelChanged(oldCQ: currentCQ, newCQ: user.categoryScores.overall) {
            HapticManager.notification(.success)
        }
    }

    func incrementJourneyDay() {
        guard var user = currentUser else { return }
        user.journeyDayIndex += 1
        saveUser(user)
    }
}
