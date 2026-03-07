import SwiftUI

// MARK: - Journey View (top-to-bottom, app purple theme)
struct JourneyView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEval      = false
    @State private var selectedDay: JourneyDay? = nil
    @State private var shimmer: CGFloat = 0

    var user: UserAccount? { appState.currentUser }
    var evalDone: Bool    { user?.evaluationCompleted ?? false }
    var completedDays: Int { user?.journeyDayIndex ?? 0 }
    let totalDays = 30

    var body: some View {
        NavigationStack {
            ZStack {
                appThemeBackground
                if !evalDone { lockedOverlay } else { journeyMap }
            }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(
                LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "4834D4")],
                               startPoint: .leading, endPoint: .trailing),
                for: .navigationBar
            )
            .sheet(isPresented: $showEval) { EvaluationIntroView() }
            .sheet(item: $selectedDay) { day in
                DailyExerciseView(day: day)
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - App Theme Background (purple gradient matching the app)
    var appThemeBackground: some View {
        ZStack {
            // Primary gradient — matches the app's brandPrimary palette
            LinearGradient(
                colors: [
                    Color(hex: "4834D4"),
                    Color(hex: "6C5CE7"),
                    Color(hex: "8B74F5"),
                    Color(hex: "A29BFE").opacity(0.85)
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Soft nebula blobs for depth — same purple family
            RadialGradient(
                colors: [Color(hex: "FD79A8").opacity(0.18), Color.clear],
                center: .init(x: 0.85, y: 0.15),
                startRadius: 20, endRadius: 220
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: "00CEC9").opacity(0.12), Color.clear],
                center: .init(x: 0.15, y: 0.55),
                startRadius: 20, endRadius: 180
            )
            .ignoresSafeArea()

            // Subtle grid-like dots pattern (edtech feel)
            GeometryReader { geo in
                ForEach(0..<6) { col in
                    ForEach(0..<12) { row in
                        Circle()
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 3, height: 3)
                            .position(
                                x: CGFloat(col) * (geo.size.width / 5),
                                y: CGFloat(row) * (geo.size.height / 11)
                            )
                    }
                }
            }
            .ignoresSafeArea()

            // Bottom fade for readability
            LinearGradient(
                colors: [Color.clear, Color(hex: "2D1B69").opacity(0.5)],
                startPoint: .init(x: 0.5, y: 0.5),
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Locked Overlay
    var lockedOverlay: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1.5))
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(LinearGradient(
                        colors: [Color.white, Color(hex: "A29BFE")],
                        startPoint: .top, endPoint: .bottom
                    ))
            }
            .shadow(color: Color(hex: "6C5CE7").opacity(0.5), radius: 20)

            VStack(spacing: 10) {
                Text("Journey Locked")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Complete your Evaluation to unlock\nyour personalised 30-day learning path.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button("Begin Evaluation") { showEval = true }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "4834D4"))
                .frame(width: 220)
                .padding(.vertical, 16)
                .background(Capsule().fill(Color.white))
                .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
        }
        .padding(32)
    }

    // MARK: - Journey Map (top → bottom)
    var journeyMap: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Top stats banner
                statsBanner
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 10)

                // Nodes: index 0 at top, totalDays-1 at bottom
                ForEach(0..<totalDays, id: \.self) { dayIdx in
                    let isEven      = dayIdx % 2 == 0
                    let isCompleted = dayIdx < completedDays
                    let isCurrent   = dayIdx == completedDays
                    let isLocked    = dayIdx > completedDays

                    HStack {
                        if !isEven { Spacer(minLength: 60) }
                        JourneyNodeView(
                            dayNumber: dayIdx + 1,
                            isCompleted: isCompleted,
                            isCurrent: isCurrent,
                            isLocked: isLocked,
                            level: user?.currentLevel ?? .beginner
                        ) {
                            guard !isLocked else { return }
                            selectedDay = JourneyDay(
                                id: dayIdx,
                                dayNumber: dayIdx + 1,
                                isCompleted: isCompleted,
                                level: user?.currentLevel ?? .beginner
                            )
                            HapticManager.impact(.medium)
                        }
                        if isEven { Spacer(minLength: 60) }
                    }
                    .padding(.horizontal, 32)

                    if dayIdx < totalDays - 1 {
                        HStack {
                            if !isEven { Spacer(minLength: 80) }
                            pathConnector(isCompleted: dayIdx < completedDays)
                            if isEven { Spacer(minLength: 80) }
                        }
                        .padding(.horizontal, 32)
                    }
                }
                Spacer(minLength: 50)
            }
        }
    }

    var statsBanner: some View {
        HStack(spacing: 12) {
            // Level badge
            HStack(spacing: 6) {
                Image(systemName: user?.currentLevel.icon ?? "star.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "FDCB6E"))
                Text(user?.currentLevel.label ?? "Beginner")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.15))
            .cornerRadius(20)

            Spacer()

            // Progress
            VStack(alignment: .trailing, spacing: 3) {
                Text("Day \(min(completedDays + 1, totalDays)) of \(totalDays)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.18)).frame(height: 5)
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: "FDCB6E"), Color(hex: "FD79A8")],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(completedDays) / CGFloat(totalDays), height: 5)
                    }
                }
                .frame(width: 100, height: 5)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }

    func pathConnector(isCompleted: Bool) -> some View {
        VStack(spacing: 3) {
            ForEach(0..<4) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isCompleted
                        ? LinearGradient(colors: [Color.white.opacity(0.7), Color.white.opacity(0.5)],
                                         startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                         startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 3, height: 6)
            }
        }
        .frame(height: 30)
    }
}

// MARK: - Journey Node (unchanged from previous, kept for reference)
struct JourneyNodeView: View {
    let dayNumber:   Int
    let isCompleted: Bool
    let isCurrent:   Bool
    let isLocked:    Bool
    let level: DifficultyLevel
    let onTap: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isCurrent {
                    Circle()
                        .fill(RadialGradient(
                            colors: [Color.white.opacity(0.35), Color.clear],
                            center: .center, startRadius: 30, endRadius: 60
                        ))
                        .frame(width: 110, height: 110)
                        .scaleEffect(pulse ? 1.25 : 1.0)
                        .opacity(pulse ? 0 : 0.9)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: pulse)
                }

                Circle()
                    .fill(nodeGradient)
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(Color.white.opacity(isLocked ? 0.1 : 0.5), lineWidth: 2))
                    .shadow(color: nodeShadow, radius: isLocked ? 0 : 14, y: 4)

                nodeContent

                VStack {
                    Spacer()
                    Text("Day \(dayNumber)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(isLocked ? 0.3 : 0.9))
                        .padding(.top, 80)
                }
            }
            .frame(width: 110, height: 110)
        }
        .buttonStyle(.plain)
        .onAppear { if isCurrent { pulse = true } }
    }

    var nodeGradient: LinearGradient {
        if isCompleted {
            return LinearGradient(colors: [Color(hex: "00B894"), Color(hex: "00CEC9")],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        } else if isCurrent {
            return LinearGradient(colors: [Color(hex: "FDCB6E"), Color(hex: "E17055")],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var nodeShadow: Color {
        if isCompleted { return Color(hex: "00B894").opacity(0.55) }
        if isCurrent   { return Color(hex: "FDCB6E").opacity(0.6) }
        return .clear
    }

    @ViewBuilder var nodeContent: some View {
        if isCompleted {
            Image(systemName: "checkmark")
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.white)
        } else if isLocked {
            Image(systemName: "lock.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.25))
        } else {
            VStack(spacing: 2) {
                Image(systemName: level.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text("\(dayNumber)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
        }
    }
}

// MARK: - Journey Day Model
struct JourneyDay: Identifiable {
    let id: Int
    let dayNumber: Int
    let isCompleted: Bool
    let level: DifficultyLevel
}

// MARK: - Daily Exercise View
struct DailyExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    let day: JourneyDay

    @State private var completedCategories: Set<ExerciseCategory> = []
    @State private var activeCategory: ExerciseCategory? = nil
    @State private var showExercise = false

    var allDone: Bool { completedCategories.count == ExerciseCategory.allCases.count }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "4834D4"), Color(hex: "6C5CE7"), Color(hex: "A29BFE").opacity(0.8)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        dayHeaderCard
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in dailyCategoryCard(cat) }
                        if allDone { allDoneCard }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Day \(day.dayNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(.white.opacity(0.9))
                }
            }
            .sheet(isPresented: $showExercise) {
                if let cat = activeCategory {
                    ExerciseFlowView(category: cat, onFinish: { _, _ in
                        withAnimation(.spring()) { completedCategories.insert(cat) }
                        if allDone { appState.incrementJourneyDay() }
                    })
                    .environmentObject(appState)
                }
            }
        }
    }

    var dayHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 54, height: 54)
                Image(systemName: day.level.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Day \(day.dayNumber) · \(day.level.label)")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Complete all 4 categories to advance")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.12))
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.18), lineWidth: 1))
    }

    func dailyCategoryCard(_ category: ExerciseCategory) -> some View {
        let done = completedCategories.contains(category)
        return Button {
            guard !done else { return }
            activeCategory = category; showExercise = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(done ? AnyShapeStyle(Color.white.opacity(0.1)) : AnyShapeStyle(category.gradient))
                        .frame(width: 50, height: 50)
                    Image(systemName: done ? "checkmark.seal.fill" : category.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(category.rawValue)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(done ? "Completed" : "Tap to begin")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(done ? Color(hex: "00B894") : .white.opacity(0.55))
                }
                Spacer()
                Image(systemName: done ? "checkmark.circle.fill" : "chevron.right.circle")
                    .font(.system(size: 20))
                    .foregroundColor(done ? Color(hex: "00B894") : .white.opacity(0.35))
            }
            .padding(14)
            .background(done ? Color.white.opacity(0.06) : Color.white.opacity(0.12))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(
                done ? Color(hex: "00B894").opacity(0.5) : Color.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(done)
    }

    var allDoneCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "FDCB6E"), Color(hex: "E17055")],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 65, height: 65)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 30)).foregroundColor(.white)
            }
            .shadow(color: Color(hex: "FDCB6E").opacity(0.5), radius: 14)

            Text("Day Complete!")
                .font(.system(size: 22, weight: .black, design: .rounded)).foregroundColor(.white)
            Text("Outstanding! Come back tomorrow to continue.")
                .font(.system(size: 13, design: .rounded)).foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button("Finish Day") { dismiss() }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(Color(hex: "4834D4"))
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(Color.white).cornerRadius(12)
        }
        .padding(22)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "FDCB6E").opacity(0.35), lineWidth: 1))
    }
}
