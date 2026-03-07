import SwiftUI
import Charts

// MARK: - Progress Report View
struct ProgressView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: ExerciseCategory? = nil

    var user: UserAccount? { appState.currentUser }
    var sessions: [ProgressSession] { user?.sessionHistory ?? [] }
    var evalDone: Bool { user?.evaluationCompleted ?? false }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F7FF").ignoresSafeArea()

                if sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // CQ Summary Card
                            cqSummaryCard

                            // CQ Line Chart
                            cqLineChart

                            // Per-Category Bars
                            categoryScoresCard

                            // Session History
                            sessionHistoryCard

                            Spacer(minLength: 20)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: Empty
    var emptyState: some View {
        VStack(spacing: 20) {
            Text("📊").font(.system(size: 70))
            Text("No Data Yet")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.brandPrimary)
            Text("Complete the Evaluation Test or some Journey exercises to see your progress here.")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: CQ Summary
    var cqSummaryCard: some View {
        let scores = user?.categoryScores ?? CategoryScores()
        let overall = scores.overall
        let level   = DifficultyLevel.level(for: overall)

        return HStack(spacing: 20) {
            // Circular gauge
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 10)
                    .frame(width: 90, height: 90)
                Circle()
                    .trim(from: 0, to: CGFloat(overall) / 400)
                    .stroke(level.color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 2) {
                    Text("\(overall)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text("/400")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Comprehenza Quotient")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    Image(systemName: level.icon)
                    Text(level.label)
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(level.color)

                Text("\(sessions.count) sessions completed")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .cardStyle()
        .padding(.horizontal, 20)
    }

    // MARK: CQ Line Chart
    var cqLineChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CQ Over Time")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            if #available(iOS 16, *) {
                Chart(sessions.suffix(20).enumerated().map { i, s in (i, s) }, id: \.0) { idx, session in
                    LineMark(
                        x: .value("Session", idx + 1),
                        y: .value("CQ", session.overallCQ)
                    )
                    .foregroundStyle(Color.brandPrimary.gradient)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Session", idx + 1),
                        y: .value("CQ", session.overallCQ)
                    )
                    .foregroundStyle(Color.brandPrimary.opacity(0.1).gradient)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Session", idx + 1),
                        y: .value("CQ", session.overallCQ)
                    )
                    .foregroundStyle(Color.brandPrimary)
                    .symbolSize(30)
                }
                .chartYScale(domain: 0...400)
                .chartYAxis {
                    AxisMarks(values: [0, 100, 200, 300, 400]) { val in
                        AxisGridLine().foregroundStyle(Color.secondary.opacity(0.2))
                        AxisValueLabel()
                            .font(.system(size: 11, design: .rounded))
                    }
                }
                .frame(height: 200)
            } else {
                Text("Charts require iOS 16+")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .cardStyle()
        .padding(.horizontal, 20)
    }

    // MARK: Category Scores
    var categoryScoresCard: some View {
        let scores = user?.categoryScores ?? CategoryScores()

        return VStack(alignment: .leading, spacing: 16) {
            Text("Category Progress")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                let val = scores.score(for: cat)
                HStack(spacing: 14) {
                    Image(systemName: cat.icon)
                        .font(.system(size: 16))
                        .foregroundColor(cat.color)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(cat.rawValue)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Spacer()
                            Text(String(format: "%.1f", val))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(cat.color)
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.12))
                                    .frame(height: 8)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(cat.color)
                                    .frame(width: geo.size.width * CGFloat(val / 100), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }

            // Radar-style category chart using iOS 16 Charts
            if #available(iOS 16, *) {
                let data: [(String, Double)] = ExerciseCategory.allCases.map {
                    ($0.rawValue, (scores.score(for: $0) / 100) * 100)
                }

                Chart(data, id: \.0) { name, val in
                    BarMark(
                        x: .value("Category", name),
                        y: .value("Score", val)
                    )
                    .foregroundStyle(
                        ExerciseCategory.allCases.first(where: { $0.rawValue == name })?.color ?? .brandPrimary
                    )
                    .cornerRadius(8)
                }
                .chartYScale(domain: 0...100)
                .frame(height: 160)
                .padding(.top, 8)
            }
        }
        .padding(20)
        .cardStyle()
        .padding(.horizontal, 20)
    }

    // MARK: Session History
    var sessionHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Session History")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            ForEach(sessions.suffix(10).reversed()) { session in
                HStack(spacing: 14) {
                    // Date
                    VStack(spacing: 2) {
                        Text(session.date, format: .dateTime.day().month())
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Text(session.date, format: .dateTime.hour().minute())
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 50)

                    // CQ Score
                    ZStack {
                        Capsule()
                            .fill(session.level.color.opacity(0.15))
                        Text("\(session.overallCQ) CQ")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(session.level.color)
                    }
                    .frame(width: 70, height: 32)

                    // Mini bars
                    HStack(spacing: 4) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                            let val = cat == .comprehension ? session.comprehensionScore :
                                      cat == .vocabulary    ? session.vocabularyScore    :
                                      cat == .relearning    ? session.reLearningScore    :
                                                              session.fluencyScore
                            RoundedRectangle(cornerRadius: 2)
                                .fill(cat.color)
                                .frame(width: 6, height: max(4, CGFloat(val / 100) * 28))
                        }
                    }
                    .frame(height: 32, alignment: .bottom)

                    Spacer()

                    // Level
                    HStack(spacing: 4) {
                        Image(systemName: session.level.icon)
                            .font(.system(size: 10))
                        Text(session.level.label)
                            .font(.system(size: 11, design: .rounded))
                    }
                    .foregroundColor(session.level.color)
                }
                .padding(.vertical, 4)

                if session.id != sessions.last?.id {
                    Divider()
                }
            }
        }
        .padding(20)
        .cardStyle()
        .padding(.horizontal, 20)
    }
}
