import SwiftUI

// MARK: - Relearning Test (Fill-in-the-blanks)
struct ReLearningTestView: View {
    let comprehensionScore: Int
    let vocabularyScore: Int
    @EnvironmentObject var appState: AppState
    @State private var answers: [String]
    @State private var submitted = false
    @State private var showNext  = false
    @FocusState private var focusedIdx: Int?

    let blanks: [FillBlank] = beginnerPassage.fillBlanks

    init(comprehensionScore: Int, vocabularyScore: Int) {
        self.comprehensionScore = comprehensionScore
        self.vocabularyScore    = vocabularyScore
        _answers = State(initialValue: Array(repeating: "", count: beginnerPassage.fillBlanks.count))
    }

    var score: Int {
        let correct = blanks.enumerated().filter {
            answers[$0.offset].trimmingCharacters(in: .whitespaces).lowercased() == $0.element.answer.lowercased()
        }.count
        return ScoreEngine.evaluationScore(correct: correct, total: blanks.count)
    }

    var body: some View {
        ZStack {
            Color(hex: "FFFBF0").ignoresSafeArea()

            VStack(spacing: 0) {
                evalHeader(title: "Relearning", icon: "arrow.clockwise", color: .brandOrange, step: 3, totalSteps: 4)

                ScrollView {
                    VStack(spacing: 20) {
                        // Passage hint
                        Text(beginnerPassage.text)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(14)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .lineLimit(4)
                            .padding(.horizontal, 20)

                        Text("Fill in the blanks from the passage above.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)

                        ForEach(0..<blanks.count, id: \.self) { idx in
                            blankCard(idx: idx)
                        }

                        if !submitted {
                            Button("Submit Answers") {
                                submitted = true
                                HapticManager.notification(.success)
                            }
                            .buttonStyle(PrimaryButtonStyle(color: .brandOrange))
                            .padding(.horizontal, 20)
                        } else {
                            // Score display
                            VStack(spacing: 12) {
                                Text("Score: \(score)/100")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.brandOrange)

                                Button("Continue to Fluency →") {
                                    showNext = true
                                }
                                .buttonStyle(PrimaryButtonStyle(color: .brandOrange))
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showNext) {
            FluencyTestView(
                comprehensionScore: comprehensionScore,
                vocabularyScore:    vocabularyScore,
                reLearningScore:    score
            )
        }
    }

    @ViewBuilder
    func blankCard(idx: Int) -> some View {
        let blank = blanks[idx]
        let isCorrect = submitted && answers[idx].trimmingCharacters(in: .whitespaces).lowercased() == blank.answer.lowercased()
        let isWrong   = submitted && !isCorrect

        VStack(alignment: .leading, spacing: 10) {
            // Sentence with blank indicator
            Text(blank.sentence.replacingOccurrences(of: "___", with: "___________"))
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.primary)

            HStack(spacing: 10) {
                TextField(blank.hint, text: $answers[idx])
                    .font(.system(size: 15, design: .rounded))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isCorrect ? Color.brandGreen.opacity(0.1) :
                                  isWrong   ? Color.brandRed.opacity(0.1)   : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isCorrect ? Color.brandGreen : isWrong ? Color.brandRed : Color.clear, lineWidth: 1.5)
                    )
                    .disabled(submitted)
                    .focused($focusedIdx, equals: idx)

                if submitted {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isCorrect ? .brandGreen : .brandRed)
                        .font(.system(size: 22))
                }
            }

            if isWrong {
                Text("Answer: \(blank.answer)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.brandGreen)
            }
        }
        .padding(16)
        .cardStyle()
        .padding(.horizontal, 20)
    }
}
