import SwiftUI

// MARK: - Comprehension Test (passage-first, then 15s timed MCQ)
struct ComprehensionTestView: View {
    @EnvironmentObject var appState: AppState

    // Phase: .passage → .mcq
    enum Phase { case passage, mcq }
    @State private var phase: Phase = .passage
    @State private var currentQ     = 0
    @State private var selected: Int? = nil
    @State private var timeLeft     = 15
    @State private var correctCount = 0
    @State private var showResult   = false
    @State private var answerLocked = false
    @State private var timer: Timer? = nil
    @State private var progressAnim: CGFloat = 1.0
    @State private var passageExpanded = false

    let passage = ContentLibrary.passages[0]
    var question: MCQQuestion { passage.mcqQuestions[currentQ] }
    var totalQ: Int { passage.mcqQuestions.count }

    var body: some View {
        ZStack {
            Color(hex: "F0EEFF").ignoresSafeArea()
            VStack(spacing: 0) {
                evalHeader(title: "Comprehension", icon: "brain.head.profile",
                           color: .brandPrimary, step: 1, totalSteps: 4)

                switch phase {
                case .passage: passagePhaseView
                case .mcq:     mcqPhaseView
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showResult) {
            VocabularyTestView(comprehensionScore: correctCount * 20)
        }
        .onDisappear { timer?.invalidate() }
    }

    // ────────────────────────────────────────────
    // MARK: Phase 1 — Read the passage
    // ────────────────────────────────────────────
    var passagePhaseView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero header
                VStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(height: 80)
                        HStack(spacing: 12) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(passage.title)
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Read carefully — questions follow")
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(.white.opacity(0.75))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 18)
                    }

                    // Tip badge
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "FDCB6E"))
                        Text("You will NOT see the passage during questions")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color(hex: "856404"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: "FDCB6E").opacity(0.15))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Passage text
                Text(passage.text)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.primary)
                    .lineSpacing(7)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
                    .padding(.horizontal, 20)

                // Next button
                Button {
                    withAnimation(.spring()) { phase = .mcq }
                    startTimer()
                    HapticManager.impact(.medium)
                } label: {
                    HStack(spacing: 10) {
                        Text("I've Read It — Start Questions")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    // ────────────────────────────────────────────
    // MARK: Phase 2 — MCQ (15s per question, passage hidden)
    // ────────────────────────────────────────────
    var mcqPhaseView: some View {
        VStack(spacing: 0) {
            // Progress + Timer
            VStack(spacing: 8) {
                HStack {
                    Text("Question \(currentQ + 1) of \(totalQ)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                        Text("\(timeLeft)s")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(timeLeft <= 5 ? .brandRed : .brandPrimary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill((timeLeft <= 5 ? Color.brandRed : Color.brandPrimary).opacity(0.12)))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Color.secondary.opacity(0.15)).frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(timeLeft <= 5 ? Color.brandRed : Color.brandPrimary)
                            .frame(width: geo.size.width * progressAnim, height: 6)
                            .animation(.linear(duration: 1), value: progressAnim)
                    }
                }
                .frame(height: 6)
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8)

            // Passage-hidden reminder
            HStack(spacing: 6) {
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("Passage hidden — answer from memory")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 20) {
                    // Question
                    Text(question.question)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Options
                    VStack(spacing: 12) {
                        ForEach(0..<question.options.count, id: \.self) { idx in
                            OptionButton(
                                text: question.options[idx],
                                index: idx,
                                selected: selected,
                                correct: answerLocked ? question.correctIndex : nil,
                                locked: answerLocked
                            ) {
                                if !answerLocked { selectAnswer(idx) }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
    }

    private func startTimer() {
        timeLeft = 15; progressAnim = 1.0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeLeft > 0 {
                timeLeft -= 1
                progressAnim = CGFloat(timeLeft) / 15.0
            } else {
                advanceQuestion()
            }
        }
    }

    private func selectAnswer(_ idx: Int) {
        HapticManager.impact(.light)
        selected = idx; answerLocked = true
        if idx == question.correctIndex { correctCount += 1 }
        timer?.invalidate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { advanceQuestion() }
    }

    private func advanceQuestion() {
        if currentQ + 1 < totalQ {
            currentQ += 1; selected = nil; answerLocked = false
            startTimer()
        } else {
            timer?.invalidate(); showResult = true
        }
    }
}

// MARK: - Option Button (unchanged)
struct OptionButton: View {
    let text: String
    let index: Int
    let selected: Int?
    let correct: Int?
    let locked: Bool
    let action: () -> Void

    private var bgColor: Color {
        guard let sel = selected else { return Color(.systemBackground) }
        if let cor = correct {
            if index == cor { return .brandGreen.opacity(0.15) }
            if index == sel && sel != cor { return .brandRed.opacity(0.12) }
        } else if index == sel { return Color.brandPrimary.opacity(0.12) }
        return Color(.systemBackground)
    }

    private var borderColor: Color {
        guard let sel = selected else { return Color.secondary.opacity(0.2) }
        if let cor = correct {
            if index == cor { return .brandGreen }
            if index == sel && sel != cor { return .brandRed }
        } else if index == sel { return .brandPrimary }
        return Color.secondary.opacity(0.2)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(["A","B","C","D"][index])
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(selected == index ? .white : .brandPrimary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(selected == index ? Color.brandPrimary : Color.brandPrimary.opacity(0.12)))

                Text(text)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if locked, let cor = correct {
                    if index == cor {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.brandGreen)
                    } else if index == selected && selected != cor {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.brandRed)
                    }
                }
            }
            .padding(16)
            .background(bgColor)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(borderColor, lineWidth: 1.5))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: selected)
    }
}

// MARK: - Shared Eval Header
func evalHeader(title: String, icon: String, color: Color, step: Int, totalSteps: Int) -> some View {
    HStack(spacing: 12) {
        Image(systemName: icon)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(color)
        Text(title)
            .font(.system(size: 20, weight: .bold, design: .rounded))
        Spacer()
        Text("\(step)/\(totalSteps)")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(color))
    }
    .padding(.horizontal, 20).padding(.vertical, 16)
    .background(Color(.systemBackground))
}
