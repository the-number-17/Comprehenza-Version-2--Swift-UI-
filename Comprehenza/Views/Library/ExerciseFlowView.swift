import SwiftUI
import Speech
import AVFoundation

// MARK: - Unified Exercise Flow View
// Routes each category to its dedicated exercise type:
//   Comprehension → passage + MCQ
//   Vocabulary    → match the following
//   Relearning    → fill in the blanks
//   Fluency       → passage + read aloud

struct ExerciseFlowView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    let category: ExerciseCategory
    let onFinish: ((Int, Int) -> Void)?

    var passage: Passage {
        ContentLibrary.passage(for: appState.currentUser?.currentLevel ?? .beginner)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                category.gradient.opacity(0.95).ignoresSafeArea()
                Color.black.opacity(0.08).ignoresSafeArea()

                VStack(spacing: 0) {
                    switch category {
                    case .comprehension:
                        ComprehensionExercise(passage: passage, category: category, onFinish: finish)
                    case .vocabulary:
                        VocabularyExercise(passage: passage, category: category, onFinish: finish)
                    case .relearning:
                        RelearningExercise(passage: passage, category: category, onFinish: finish)
                    case .fluency:
                        FluencyExercise(passage: passage, category: category, onFinish: finish)
                    }
                }
            }
            .navigationTitle(category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Close")
                        }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }

    private func finish(correct: Int, total: Int) {
        for _ in 0..<correct { appState.applyExerciseMark(category: category, isCorrect: true, isSkipped: false) }
        for _ in 0..<(total - correct) { appState.applyExerciseMark(category: category, isCorrect: false, isSkipped: false) }
        onFinish?(correct, total)
    }
}

// ╔══════════════════════════════════════════════════════════════╗
// ║  1. COMPREHENSION — Passage → MCQ (passage hidden)         ║
// ╚══════════════════════════════════════════════════════════════╝
struct ComprehensionExercise: View {
    let passage: Passage
    let category: ExerciseCategory
    let onFinish: (Int, Int) -> Void

    enum Phase { case reading, mcq, result }
    @State private var phase: Phase = .reading
    @State private var qIndex = 0
    @State private var selected: Int? = nil
    @State private var locked  = false
    @State private var score   = 0
    @State private var timeLeft = 15
    @State private var timer: Timer? = nil
    @State private var progressAnim: CGFloat = 1.0

    var questions: [MCQQuestion] { passage.mcqQuestions }
    var q: MCQQuestion { questions[min(qIndex, questions.count - 1)] }

    var body: some View {
        switch phase {
        case .reading: passageView
        case .mcq:     mcqView
        case .result:  resultView(score: score, total: questions.count, category: category, onFinish: onFinish)
        }
    }

    // MARK: Passage Phase
    var passageView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroHeader(title: passage.title, icon: "brain.head.profile", category: category)

                // Tip
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill").font(.system(size: 13)).foregroundColor(Color(hex: "FDCB6E"))
                    Text("You will NOT see the passage during questions")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "856404"))
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(hex: "FDCB6E").opacity(0.15)).cornerRadius(10)

                // Passage
                Text(passage.text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .lineSpacing(6)
                    .padding(18)
                    .background(Color.black.opacity(0.2)).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.15), lineWidth: 1))

                pillButton(title: "I've Read It — Start Quiz", icon: "arrow.right.circle.fill", color: category.color) {
                    withAnimation(.spring()) { phase = .mcq }
                    startTimer()
                    HapticManager.impact(.medium)
                }
            }
            .padding(20)
        }
    }

    // MARK: MCQ Phase (passage hidden, 15s timer)
    var mcqView: some View {
        VStack(spacing: 0) {
            // Timer bar
            timerBar(timeLeft: timeLeft, total: 15, progress: progressAnim,
                     label: "Question \(qIndex + 1) of \(questions.count)")

            // Hidden reminder
            HStack(spacing: 6) {
                Image(systemName: "eye.slash.fill").font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                Text("Passage hidden — answer from memory")
                    .font(.system(size: 12, design: .rounded)).foregroundColor(.white.opacity(0.5))
                Spacer()
            }
            .padding(.horizontal, 20).padding(.bottom, 10)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(q.question)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.2)).cornerRadius(14)

                    ForEach(0..<q.options.count, id: \.self) { idx in
                        mcqOptionButton(
                            index: idx, text: q.options[idx],
                            selected: selected, correctIndex: locked ? q.correctIndex : nil,
                            locked: locked, category: category
                        ) {
                            guard !locked else { return }
                            locked = true; selected = idx
                            if idx == q.correctIndex { score += 1 }
                            timer?.invalidate()
                            HapticManager.impact(idx == q.correctIndex ? .medium : .light)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { advance() }
                        }
                    }
                }
                .padding(20)
            }
        }
        .onDisappear { timer?.invalidate() }
    }

    private func startTimer() {
        timeLeft = 15; progressAnim = 1.0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeLeft > 0 { timeLeft -= 1; progressAnim = CGFloat(timeLeft) / 15.0 }
            else { advance() }
        }
    }

    private func advance() {
        if qIndex + 1 < questions.count {
            qIndex += 1; selected = nil; locked = false; startTimer()
        } else {
            timer?.invalidate()
            withAnimation { phase = .result }
            onFinish(score, questions.count)
        }
    }
}


// ╔══════════════════════════════════════════════════════════════╗
// ║  2. VOCABULARY — Match the Following (6 attempts max)      ║
// ╚══════════════════════════════════════════════════════════════╝
struct VocabularyExercise: View {
    let passage: Passage
    let category: ExerciseCategory
    let onFinish: (Int, Int) -> Void

    @State private var leftWords:     [String] = []
    @State private var rightMeanings: [String] = []
    @State private var selectedWord:  String?  = nil
    @State private var matched:       Set<String> = []
    @State private var attempts       = 0
    @State private var flashLeft:     String? = nil
    @State private var flashRight:    String? = nil
    @State private var showResult     = false

    let maxAttempts = 6  // 4 correct + 2 wrong allowed

    var pairs: [VocabPair] { Array(passage.vocabularyPairs.prefix(4)) }
    var allMatched: Bool { matched.count == pairs.count }
    var exhausted:  Bool { attempts >= maxAttempts }

    var body: some View {
        if showResult {
            resultView(score: matched.count, total: pairs.count, category: category, onFinish: onFinish)
        } else {
            matchView
        }
    }

    var matchView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroHeader(title: "Match the Following", icon: "arrow.left.arrow.right.circle.fill", category: category)

                Text("Tap a word on the left, then its meaning on the right.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                // Attempts / score counters
                HStack(spacing: 14) {
                    Label("\(matched.count) correct", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color(hex: "00B894"))
                    Label("\(attempts - matched.count) wrong", systemImage: "xmark.circle.fill")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(Color(hex: "E17055"))
                    Spacer()
                    Text("Attempts: \(attempts)/\(maxAttempts)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Two columns
                HStack(alignment: .top, spacing: 10) {
                    VStack(spacing: 8) {
                        ForEach(leftWords, id: \.self) { word in
                            let isMatched  = matched.contains(word)
                            let isSelected = selectedWord == word
                            let isFlash    = flashLeft == word
                            Button {
                                if !isMatched && !exhausted { selectedWord = word }
                            } label: {
                                Text(word)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(isMatched ? .white.opacity(0.35) : isSelected ? category.color : .white)
                                    .frame(maxWidth: .infinity).padding(12)
                                    .background(
                                        isMatched ? Color.white.opacity(0.06) :
                                        isFlash   ? Color(hex: "E17055").opacity(0.3) :
                                        isSelected ? Color.white : Color.white.opacity(0.18)
                                    )
                                    .cornerRadius(10)
                                    .strikethrough(isMatched, color: .white.opacity(0.4))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                                        isFlash ? Color(hex: "E17055") : Color.clear, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                            .disabled(isMatched || exhausted)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 8) {
                        ForEach(rightMeanings, id: \.self) { meaning in
                            let pair      = pairs.first(where: { $0.meaning == meaning })
                            let isMatched = pair != nil && matched.contains(pair!.word)
                            let isFlash   = flashRight == meaning
                            Button { handleMeaningTap(meaning) } label: {
                                Text(meaning)
                                    .font(.system(size: 12, design: .rounded))
                                    .foregroundColor(isMatched ? .white.opacity(0.35) : isFlash ? Color(hex: "E17055") : .white)
                                    .frame(maxWidth: .infinity).padding(12)
                                    .background(
                                        isMatched ? Color.white.opacity(0.06) :
                                        isFlash   ? Color(hex: "E17055").opacity(0.2) : Color.white.opacity(0.15)
                                    )
                                    .cornerRadius(10)
                                    .strikethrough(isMatched, color: .white.opacity(0.4))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(
                                        isFlash ? Color(hex: "E17055") : Color.clear, lineWidth: 1.5))
                            }
                            .buttonStyle(.plain)
                            .disabled(isMatched || exhausted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // Auto-finish or manual
                if allMatched || exhausted {
                    pillButton(title: "See Results", icon: "chart.bar.fill", color: category.color) {
                        onFinish(matched.count, pairs.count)
                        showResult = true
                    }
                }
            }
            .padding(20)
            .onAppear {
                leftWords     = pairs.map(\.word).shuffled()
                rightMeanings = pairs.map(\.meaning).shuffled()
            }
        }
    }

    private func handleMeaningTap(_ meaning: String) {
        guard let word = selectedWord, !exhausted else { return }
        attempts += 1

        if let pair = pairs.first(where: { $0.word == word && $0.meaning == meaning }) {
            withAnimation { matched.insert(pair.word) }
            HapticManager.notification(.success)
            selectedWord = nil
            if allMatched || exhausted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onFinish(matched.count, pairs.count)
                    showResult = true
                }
            }
        } else {
            flashLeft = word; flashRight = meaning
            HapticManager.notification(.error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                flashLeft = nil; flashRight = nil; selectedWord = nil
                if exhausted {
                    // Out of attempts — show result
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onFinish(matched.count, pairs.count)
                        showResult = true
                    }
                }
            }
        }
    }
}


// ╔══════════════════════════════════════════════════════════════╗
// ║  3. RELEARNING — Fill in the Blanks (with hints)           ║
// ╚══════════════════════════════════════════════════════════════╝
struct RelearningExercise: View {
    let passage: Passage
    let category: ExerciseCategory
    let onFinish: (Int, Int) -> Void

    @State private var answers:       [String] = []
    @State private var submitted      = false
    @State private var hintRevealed:  Set<Int> = []
    @State private var showResult     = false

    var blanks: [FillBlank] { Array(passage.fillBlanks.prefix(5)) }

    var body: some View {
        if showResult {
            resultView(score: correctCount, total: blanks.count, category: category, onFinish: onFinish)
        } else {
            fillView
        }
    }

    var correctCount: Int {
        blanks.indices.filter { i in
            (answers[safe: i] ?? "").lowercased().trimmingCharacters(in: .whitespaces) == blanks[i].answer.lowercased()
        }.count
    }

    var fillView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroHeader(title: "Fill in the Blanks", icon: "pencil.circle.fill", category: category)

                // Hint counter
                if !submitted {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill").font(.system(size: 12))
                            .foregroundColor(Color(hex: "FDCB6E"))
                        Text("\(hintRevealed.count) hint\(hintRevealed.count==1 ? "" : "s") used")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Text("Complete each sentence from the passage.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                ForEach(blanks.indices, id: \.self) { i in
                    fillCard(index: i)
                }

                pillButton(
                    title: submitted ? "See Results" : "Check Answers",
                    icon: submitted ? "chart.bar.fill" : "checkmark.circle.fill",
                    color: category.color
                ) {
                    if !submitted {
                        submitted = true; HapticManager.impact(.medium)
                    } else {
                        onFinish(correctCount, blanks.count)
                        showResult = true
                    }
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    func fillCard(index i: Int) -> some View {
        let blank = blanks[i]
        let hasHint = hintRevealed.contains(i)

        VStack(alignment: .leading, spacing: 8) {
            Text(blank.sentence.replacingOccurrences(of: "____", with: "  ___  ")
                               .replacingOccurrences(of: "___", with: "  ___  "))
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.2)).cornerRadius(10)

            if submitted {
                let ok = (answers[safe: i] ?? "").lowercased().trimmingCharacters(in: .whitespaces) == blank.answer.lowercased()
                HStack(spacing: 6) {
                    Image(systemName: ok ? "checkmark.circle.fill" : "info.circle.fill")
                    Text(ok ? "Correct!" : "Answer: \(blank.answer)")
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(ok ? Color(hex: "00B894") : Color(hex: "FDCB6E"))
            } else {
                HStack(spacing: 8) {
                    TextField("Type your answer...", text: Binding(
                        get: { answers[safe: i] ?? "" },
                        set: { val in
                            while answers.count <= i { answers.append("") }
                            answers[i] = val
                        }
                    ))
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.18)).cornerRadius(10)

                    Button {
                        hintRevealed.insert(i); HapticManager.impact(.light)
                    } label: {
                        Image(systemName: hasHint ? "lightbulb.fill" : "lightbulb")
                            .font(.system(size: 16))
                            .foregroundColor(hasHint ? Color(hex: "FDCB6E") : .white.opacity(0.5))
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(hasHint ? 0.2 : 0.1))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain).disabled(hasHint)
                }

                if hasHint {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill").font(.system(size: 12))
                            .foregroundColor(Color(hex: "FDCB6E"))
                        Text("Hint: starts with \"\(String(blank.answer.prefix(1)).uppercased())\"")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(hex: "FDCB6E"))
                    }
                }
            }
        }
    }
}


// ╔══════════════════════════════════════════════════════════════╗
// ║  4. FLUENCY — Passage Read-Aloud with Real-Time Color      ║
// ╚══════════════════════════════════════════════════════════════╝
struct FluencyExercise: View {
    let passage: Passage
    let category: ExerciseCategory
    let onFinish: (Int, Int) -> Void

    @StateObject private var speechRec = SpeechRecognizer()
    @State private var isRecording  = false
    @State private var isPaused     = false
    @State private var hasPermission: Bool? = nil
    @State private var showResult   = false

    var targetWords: [String] {
        passage.fluencyText
            .components(separatedBy: .whitespaces)
            .map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
    }

    var fluencyScore: Int {
        let spoken = speechRec.spokenWords
        guard !targetWords.isEmpty else { return 0 }
        let correct = targetWords.prefix(max(spoken.count, targetWords.count))
            .enumerated()
            .filter { idx, word in idx < spoken.count && spoken[idx] == word }
            .count
        return correct
    }

    var body: some View {
        if showResult {
            resultView(score: fluencyScore, total: targetWords.count, category: category, onFinish: onFinish)
        } else {
            readAloudView
                .onAppear { checkPermission() }
                .onDisappear { speechRec.stopRecording() }
        }
    }

    var readAloudView: some View {
        ScrollView {
            VStack(spacing: 20) {
                heroHeader(title: "Read Aloud", icon: "waveform.and.mic", category: category)

                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    instructionRow(icon: "play.circle.fill", text: "Tap the mic and read aloud")
                    instructionRow(icon: "circle.fill", color: Color(hex: "00B894"), text: "Words turn green when correct")
                    instructionRow(icon: "circle.fill", color: Color(hex: "E17055"), text: "Words turn red when misread")
                    instructionRow(icon: "pause.circle.fill", text: "Pause anytime — tap Next to submit")
                }
                .padding(14)
                .background(Color.white.opacity(0.08)).cornerRadius(14)

                // Passage with color
                passageColorView
                    .padding(18)
                    .background(Color.black.opacity(0.15)).cornerRadius(16)

                // Permission warning
                if hasPermission == false {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.slash.fill").foregroundColor(Color(hex: "E17055"))
                        Text("Microphone access needed. Enable in Settings.")
                            .font(.system(size: 13, design: .rounded)).foregroundColor(Color(hex: "E17055"))
                    }
                    .padding(14).background(Color(hex: "E17055").opacity(0.1)).cornerRadius(12)
                }

                // Controls
                controlsSection
            }
            .padding(20)
        }
    }

    var passageColorView: some View {
        let original = passage.fluencyText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let spoken   = speechRec.spokenWords

        return Group {
            original.indices.reduce(Text("")) { result, idx in
                let word  = original[idx]
                let clean = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
                let color: Color
                if idx < spoken.count {
                    color = spoken[idx] == clean ? Color(hex: "00B894") : Color(hex: "E17055")
                } else if idx == spoken.count {
                    color = Color(hex: "A29BFE") // next word — purple
                } else {
                    color = .white.opacity(0.8)
                }
                let space = idx < original.count - 1 ? " " : ""
                return result + Text(word + space)
                    .foregroundColor(color)
                    .font(.system(size: 17, weight: idx == spoken.count ? .bold : .regular, design: .rounded))
            }
        }
    }

    var controlsSection: some View {
        VStack(spacing: 14) {
            // Mic button
            Button { toggleRecording() } label: {
                ZStack {
                    Circle()
                        .fill(isRecording && !isPaused ? Color(hex: "E17055") : category.color)
                        .frame(width: 72, height: 72)
                        .shadow(color: (isRecording && !isPaused ? Color(hex: "E17055") : category.color).opacity(0.4), radius: 12)
                    Image(systemName: isRecording && !isPaused ? "stop.fill" : "mic.fill")
                        .font(.system(size: 26)).foregroundColor(.white)
                }
            }
            Text(isRecording && !isPaused ? "Reading... Tap to pause" : isPaused ? "Paused" : "Tap to start reading")
                .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.6))

            if isRecording {
                Button { togglePause() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                        Text(isPaused ? "Resume" : "Pause")
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white).padding(.horizontal, 18).padding(.vertical, 10)
                    .background(Color.white.opacity(0.15)).cornerRadius(10)
                }
            }

            if !speechRec.spokenWords.isEmpty {
                pillButton(
                    title: speechRec.spokenWords.count >= targetWords.count ? "Finish & See Results" : "Submit Partial Reading",
                    icon: "checkmark.circle.fill",
                    color: category.color
                ) {
                    speechRec.stopRecording(); isRecording = false; isPaused = false
                    onFinish(fluencyScore, targetWords.count)
                    showResult = true
                }
            }
        }
    }

    func instructionRow(icon: String, color: Color = .white.opacity(0.6), text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(color).frame(width: 18)
            Text(text).font(.system(size: 13, design: .rounded)).foregroundColor(.white.opacity(0.7))
        }
    }

    private func toggleRecording() {
        HapticManager.impact(.medium)
        if isRecording && !isPaused {
            speechRec.stopRecording(); isRecording = false; isPaused = false
        } else {
            speechRec.startRecording(); isRecording = true; isPaused = false
        }
    }

    private func togglePause() {
        HapticManager.impact(.light)
        if isPaused { speechRec.startRecording(); isPaused = false }
        else { speechRec.stopRecording(); isPaused = true }
    }

    private func checkPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { hasPermission = status == .authorized }
        }
    }
}


// ╔══════════════════════════════════════════════════════════════╗
// ║  SHARED COMPONENTS                                          ║
// ╚══════════════════════════════════════════════════════════════╝

// Hero header card
func heroHeader(title: String, icon: String, category: ExerciseCategory) -> some View {
    ZStack {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.black.opacity(0.2))
            .frame(height: 80)
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .bold)).foregroundColor(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .black, design: .rounded)).foregroundColor(.white)
                Text(category.rawValue)
                    .font(.system(size: 12, design: .rounded)).foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(.horizontal, 18)
    }
}

// Pill-shaped CTA button
func pillButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 10) {
            Text(title).font(.system(size: 16, weight: .bold, design: .rounded))
            Image(systemName: icon).font(.system(size: 17))
        }
        .foregroundColor(color)
        .frame(maxWidth: .infinity).padding(.vertical, 15)
        .background(Color.white).cornerRadius(14)
    }
    .buttonStyle(.plain)
}

// Timer bar
func timerBar(timeLeft: Int, total: Int, progress: CGFloat, label: String) -> some View {
    VStack(spacing: 6) {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .rounded)).foregroundColor(.white.opacity(0.7))
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "timer")
                Text("\(timeLeft)s")
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(timeLeft <= 5 ? Color(hex: "E17055") : .white)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill((timeLeft <= 5 ? Color(hex: "E17055") : Color.white).opacity(0.2)))
        }
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.15)).frame(height: 5)
                RoundedRectangle(cornerRadius: 3)
                    .fill(timeLeft <= 5 ? Color(hex: "E17055") : Color.white)
                    .frame(width: geo.size.width * progress, height: 5)
                    .animation(.linear(duration: 1), value: progress)
            }
        }
        .frame(height: 5)
    }
    .padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 6)
}

// MCQ option button
func mcqOptionButton(index: Int, text: String, selected: Int?, correctIndex: Int?,
                     locked: Bool, category: ExerciseCategory, action: @escaping () -> Void) -> some View {
    let isSelected = selected == index
    let isCorrect  = index == correctIndex
    let bg: Color = {
        guard locked else { return isSelected ? .white : Color.white.opacity(0.18) }
        if isCorrect == true { return Color(hex: "00B894") }
        if isSelected && !(isCorrect ?? false) { return Color(hex: "E17055") }
        return Color.white.opacity(0.1)
    }()
    let textColor: Color = {
        guard locked else { return isSelected ? category.color : .white }
        if isCorrect == true || (isSelected && correctIndex != nil) { return .white }
        return .white.opacity(0.4)
    }()

    return Button(action: action) {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(isSelected && !locked ? category.color : Color.white.opacity(0.15))
                    .frame(width: 28, height: 28)
                Text(["A","B","C","D"][index])
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected && !locked ? .white : .white.opacity(0.6))
            }
            Text(text).font(.system(size: 15, design: .rounded)).foregroundColor(textColor)
            Spacer()
            if locked, let cor = correctIndex {
                if index == cor {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                } else if isSelected {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.white)
                }
            }
        }
        .padding(14).background(bg).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(
            isSelected && !locked ? Color.white : Color.white.opacity(0.1), lineWidth: 1))
    }
    .buttonStyle(.plain)
    .animation(.easeInOut(duration: 0.2), value: locked)
}

// Result view
func resultView(score: Int, total: Int, category: ExerciseCategory, onFinish: (Int, Int) -> Void) -> some View {
    let pct = total > 0 ? Double(score) / Double(total) : 0
    let grade: (String, String, Color) = {
        if pct >= 0.8 { return ("Excellent!", "Outstanding mastery!", Color(hex: "00B894")) }
        if pct >= 0.5 { return ("Well Done!", "Great effort!", Color(hex: "FDCB6E")) }
        return ("Keep Going!", "Practice makes perfect!", Color(hex: "E17055"))
    }()

    return ScrollView {
        VStack(spacing: 24) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.15), lineWidth: 14).frame(width: 130, height: 130)
                Circle().trim(from: 0, to: pct)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .frame(width: 130, height: 130).rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.2), value: pct)
                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 36, weight: .black, design: .rounded)).foregroundColor(.white)
                    Text("of \(total)")
                        .font(.system(size: 13, design: .rounded)).foregroundColor(.white.opacity(0.6))
                }
            }
            VStack(spacing: 8) {
                Text(grade.0)
                    .font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(.white)
                Text(grade.1)
                    .font(.system(size: 15, design: .rounded)).foregroundColor(.white.opacity(0.75))
                HStack(spacing: 6) {
                    Image(systemName: "percent").font(.system(size: 12, weight: .semibold))
                    Text("\(Int(pct * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(grade.2)
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(grade.2.opacity(0.2)).cornerRadius(20)
            }
        }
        .padding(.vertical, 40)
    }
}

// Safe subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
