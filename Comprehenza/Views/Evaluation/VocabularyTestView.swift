import SwiftUI

// MARK: - Vocabulary Test (Match-the-following, 1 min)
struct VocabularyTestView: View {
    let comprehensionScore: Int
    @EnvironmentObject var appState: AppState
    @State private var timeLeft  = 60
    @State private var timer: Timer? = nil
    @State private var selected: String? = nil
    @State private var matched: [String: String] = [:]   // word -> meaning
    @State private var wrongPair: String? = nil
    @State private var showNext = false
    @State private var shuffledMeanings: [String] = []

    let pairs: [VocabPair] = beginnerPassage.vocabularyPairs
    var score: Int {
        let correct = pairs.filter { matched[$0.word] == $0.meaning }.count
        return ScoreEngine.evaluationScore(correct: correct, total: pairs.count)
    }

    var body: some View {
        ZStack {
            Color(hex: "F0F9F8").ignoresSafeArea()

            VStack(spacing: 0) {
                evalHeader(title: "Vocabulary", icon: "textformat.abc", color: .brandTeal, step: 2, totalSteps: 4)

                // Timer bar
                timerSection

                ScrollView {
                    VStack(spacing: 24) {
                        Text("Tap a word, then tap its meaning to match them.")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)

                        HStack(alignment: .top, spacing: 16) {
                            // Words column
                            VStack(spacing: 10) {
                                Text("Words")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                ForEach(pairs) { pair in
                                    matchChip(
                                        text: pair.word,
                                        isSelected: selected == pair.word,
                                        isMatched: matched[pair.word] != nil,
                                        isWrong: wrongPair == pair.word,
                                        color: .brandTeal
                                    ) {
                                        handleWordTap(pair.word)
                                    }
                                }
                            }

                            // Meanings column
                            VStack(spacing: 10) {
                                Text("Meanings")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.secondary)
                                ForEach(shuffledMeanings, id: \.self) { meaning in
                                    matchChip(
                                        text: meaning,
                                        isSelected: false,
                                        isMatched: matched.values.contains(meaning),
                                        isWrong: false,
                                        color: .brandPrimary
                                    ) {
                                        handleMeaningTap(meaning)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 20)
                }

                // Score preview
                if matched.count == pairs.count {
                    doneButton
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showNext) {
            ReLearningTestView(comprehensionScore: comprehensionScore, vocabularyScore: score)
        }
        .onAppear {
            shuffledMeanings = pairs.map { $0.meaning }.shuffled()
            startTimer()
        }
        .onDisappear { timer?.invalidate() }
    }

    @ViewBuilder
    var timerSection: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(timeLeft < 15 ? .brandRed : .brandTeal)
            Text("\(timeLeft)s remaining")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(timeLeft < 15 ? .brandRed : .brandTeal)
            Spacer()
            Text("\(matched.count)/\(pairs.count) matched")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)

        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(Color.secondary.opacity(0.15)).frame(height: 4)
                Rectangle()
                    .fill(timeLeft < 15 ? Color.brandRed : Color.brandTeal)
                    .frame(width: geo.size.width * CGFloat(timeLeft) / 60, height: 4)
                    .animation(.linear(duration: 1), value: timeLeft)
            }
        }
        .frame(height: 4)
    }

    @ViewBuilder
    var doneButton: some View {
        Button("Continue →") {
            timer?.invalidate()
            showNext = true
        }
        .buttonStyle(PrimaryButtonStyle(color: .brandTeal))
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    func matchChip(text: String, isSelected: Bool, isMatched: Bool, isWrong: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(isMatched ? .white : isSelected ? .white : .primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isMatched ? color : isSelected ? color.opacity(0.8) : isWrong ? Color.brandRed.opacity(0.15) : Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isWrong ? Color.brandRed : isSelected ? color : Color.secondary.opacity(0.2), lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .animation(.spring(response: 0.3), value: isSelected)
        .animation(.spring(response: 0.3), value: isMatched)
    }

    private func handleWordTap(_ word: String) {
        HapticManager.impact(.light)
        if matched[word] != nil { return }
        selected = (selected == word) ? nil : word
    }

    private func handleMeaningTap(_ meaning: String) {
        guard let word = selected, matched[meaning] == nil else { return }
        HapticManager.impact(.medium)
        let correctMeaning = pairs.first(where: { $0.word == word })?.meaning
        if correctMeaning == meaning {
            withAnimation(.spring()) { matched[word] = meaning }
            selected = nil
            HapticManager.notification(.success)
        } else {
            wrongPair = word
            HapticManager.notification(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { wrongPair = nil }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeLeft > 0 {
                timeLeft -= 1
            } else {
                timer?.invalidate()
                showNext = true
            }
        }
    }
}
