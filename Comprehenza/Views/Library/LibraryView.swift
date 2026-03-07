import SwiftUI

// MARK: - Library View (vibrant redesign)
struct LibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEvaluation   = false
    @State private var selectedCategory: ExerciseCategory? = nil

    var user: UserAccount? { appState.currentUser }
    var evalDone: Bool { user?.evaluationCompleted ?? false }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F2F0FF").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        greetingHero
                        evaluationOrCQBanner
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                            categorySection(cat)
                        }
                        Spacer(minLength: 24)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showEvaluation) {
                EvaluationIntroView()
            }
        }
    }

    // MARK: - Greeting Hero
    var greetingHero: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        let av = user?.avatar ?? .owl

        return ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient(
                    colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE"), Color(hex: "FD79A8").opacity(0.7)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))

            // Decorative circles
            GeometryReader { geo in
                Circle().fill(Color.white.opacity(0.08)).frame(width: 100, height: 100)
                    .offset(x: geo.size.width - 50, y: -30)
                Circle().fill(Color.white.opacity(0.06)).frame(width: 60, height: 60)
                    .offset(x: -20, y: geo.size.height - 30)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greeting + ",")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    Text(user?.name.isEmpty == false ? user!.name : "Reader")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    if evalDone {
                        HStack(spacing: 6) {
                            Image(systemName: user?.currentLevel.icon ?? "star.fill")
                            Text("\(user?.currentLevel.label ?? "") · CQ \(user?.overallCQ ?? 0)")
                        }
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.2)))
                    }
                }
                Spacer()
                ZStack {
                    Circle().fill(Color.white.opacity(0.2)).frame(width: 64, height: 64)
                    Text(av.emoji).font(.system(size: 36))
                }
            }
            .padding(22)
        }
        .frame(height: 140)
        .padding(.horizontal, 18)
        .shadow(color: Color(hex: "6C5CE7").opacity(0.4), radius: 18, y: 8)
    }

    // MARK: - Evaluation / CQ Banner
    @ViewBuilder var evaluationOrCQBanner: some View {
        if !evalDone {
            Button { showEvaluation = true } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 52, height: 52)
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Take Your Evaluation")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Unlock all exercises & your Journey!")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 14, weight: .semibold))
                }
                .padding(16)
                .background(LinearGradient(colors: [Color(hex: "FDCB6E"), Color(hex: "E17055")],
                                           startPoint: .leading, endPoint: .trailing))
                .cornerRadius(18)
                .shadow(color: Color(hex: "E17055").opacity(0.4), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
        } else {
            // Quick stats row
            HStack(spacing: 12) {
                ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                    let val = user?.categoryScores.score(for: cat) ?? 0
                    VStack(spacing: 6) {
                        ZStack {
                            Circle().stroke(cat.color.opacity(0.2), lineWidth: 5)
                            Circle().trim(from: 0, to: CGFloat(val/100))
                                .stroke(cat.color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                        }
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text("\(Int(val))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(cat.color)
                        )
                        Text(cat.shortName)
                            .font(.system(size: 10, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(cat.color.opacity(0.08))
                    .cornerRadius(14)
                }
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Category Section
    func categorySection(_ category: ExerciseCategory) -> some View {
        let level      = user?.currentLevel ?? .beginner
        let exercises  = ContentLibraryData.exercises(for: level, category: category)
        let maxUnlocked = evalDone ? exercises.count : 1

        return VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(category.color.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: category.icon)
                            .font(.system(size: 15))
                            .foregroundColor(category.color)
                    }
                    Text(category.rawValue)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                Spacer()
                Text(evalDone ? "\(exercises.count) exercises" : "🔒 Unlock more")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(exercises.indices, id: \.self) { idx in
                        LibraryExerciseCard(
                            exercise: exercises[idx],
                            category: category,
                            isLocked: idx >= maxUnlocked,
                            index: idx
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Library Exercise Card
struct LibraryExerciseCard: View {
    let exercise: ExerciseItem
    let category: ExerciseCategory
    let isLocked: Bool
    let index: Int

    @State private var showExercise = false
    @State private var showLockAlert = false

    // Vibrant gradient sets per index
    var cardGradient: LinearGradient {
        let colorSets: [[Color]] = [
            [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
            [Color(hex: "00B894"), Color(hex: "00CEC9")],
            [Color(hex: "FD79A8"), Color(hex: "FDCB6E")],
            [Color(hex: "E17055"), Color(hex: "FDCB6E")],
            [Color(hex: "0984E3"), Color(hex: "74B9FF")],
            [Color(hex: "6C5CE7"), Color(hex: "FD79A8")]
        ]
        return LinearGradient(
            colors: colorSets[index % colorSets.count],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    var body: some View {
        Button {
            HapticManager.impact(.light)
            if isLocked { showLockAlert = true } else { showExercise = true }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    // Top icon area
                    ZStack {
                        cardGradient
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: categoryIcon)
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.2), radius: 4)
                                Spacer()
                                if isLocked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 12)
                        }
                    }
                    .frame(height: 100)

                    // Bottom info area
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        HStack(spacing: 8) {
                            Label("\(exercise.durationMinutes) min", systemImage: "clock.fill")
                            Label("Level \(exercise.difficulty)", systemImage: "speedometer")
                        }
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .frame(width: 160, alignment: .leading)
                    .background(Color(.systemBackground))
                }
                .frame(width: 160)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: isLocked ? .clear : category.color.opacity(0.35), radius: 10, y: 5)
                .opacity(isLocked ? 0.6 : 1)

                if isLocked {
                    Color.black.opacity(0.15).cornerRadius(18)
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showExercise) {
            ExerciseFlowView(category: category, onFinish: nil)
        }
        .alert("🔒 Locked", isPresented: $showLockAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Complete the Evaluation Test first to unlock all exercises!")
        }
    }

    var categoryIcon: String {
        switch category {
        case .comprehension: return "brain.head.profile"
        case .vocabulary:    return "character.book.closed.fill"
        case .relearning:    return "arrow.triangle.2.circlepath"
        case .fluency:       return "waveform.and.mic"
        }
    }
}

