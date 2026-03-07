import SwiftUI
import Charts

// MARK: - Evaluation Result View
struct EvaluationResultView: View {
    @EnvironmentObject var appState: AppState
    @State private var animateValues = false
    @State private var goHome        = false
    let result: EvaluationResult

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "F0EEFF"), Color.white],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Celebration header
                    VStack(spacing: 16) {
                        Text("🎉")
                            .font(.system(size: 70))
                            .scaleEffect(animateValues ? 1 : 0.3)
                            .animation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.2), value: animateValues)

                        Text("Evaluation Complete!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.brandPrimary)

                        // CQ score big display
                        ZStack {
                            Circle()
                                .stroke(Color.brandSecondary.opacity(0.3), lineWidth: 12)
                                .frame(width: 160, height: 160)

                            Circle()
                                .trim(from: 0, to: animateValues ? CGFloat(result.overallCQ) / 400 : 0)
                                .stroke(Color.brandPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeOut(duration: 1.2).delay(0.4), value: animateValues)

                            VStack(spacing: 4) {
                                Text("\(result.overallCQ)")
                                    .font(.system(size: 48, weight: .black, design: .rounded))
                                    .foregroundColor(.brandPrimary)
                                Text("/ 400 CQ")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Level badge
                        HStack(spacing: 8) {
                            Image(systemName: result.level.icon)
                            Text(result.level.label)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(result.level.color))
                    }
                    .padding(.top, 40)

                    // Per-category scores
                    VStack(spacing: 14) {
                        Text("Category Breakdown")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)

                        categoryRow(category: .comprehension, score: result.comprehensionScore)
                        categoryRow(category: .vocabulary,    score: result.vocabularyScore)
                        categoryRow(category: .relearning,    score: result.reLearningScore)
                        categoryRow(category: .fluency,       score: result.fluencyScore)
                    }

                    // CTA
                    VStack(spacing: 14) {
                        Button("Start My Journey! 🚀") {
                            appState.saveEvaluationResult(result)
                            goHome = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 20)

                        Text("Results saved to your progress report.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { animateValues = true }
        .fullScreenCover(isPresented: $goHome) {
            MainTabView()
        }
    }

    func categoryRow(category: ExerciseCategory, score: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.15))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(category.color)
                            .frame(width: geo.size.width * (animateValues ? CGFloat(score) / 100 : 0), height: 6)
                            .animation(.easeOut(duration: 1).delay(0.6), value: animateValues)
                    }
                }
                .frame(height: 6)
            }

            Text("\(score)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(category.color)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(16)
        .cardStyle()
        .padding(.horizontal, 20)
    }
}
