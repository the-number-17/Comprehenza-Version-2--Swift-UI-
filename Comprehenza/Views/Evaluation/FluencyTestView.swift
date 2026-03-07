import SwiftUI
import Speech
import AVFoundation

// MARK: - Fluency Test (passage reading with real-time color feedback + pause/next)
struct FluencyTestView: View {
    let comprehensionScore: Int
    let vocabularyScore:    Int
    let reLearningScore:    Int
    @EnvironmentObject var appState: AppState
    @StateObject private var speechRec = SpeechRecognizer()
    @State private var showResult  = false
    @State private var fluencyScore = 0
    @State private var isRecording  = false
    @State private var isPaused     = false
    @State private var hasPermission: Bool? = nil

    let passage = beginnerPassage
    var targetWords: [String] {
        passage.fluencyText
            .components(separatedBy: .whitespaces)
            .map { $0.lowercased().trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        ZStack {
            Color(hex: "FFF0F8").ignoresSafeArea()

            VStack(spacing: 0) {
                evalHeader(title: "Fluency", icon: "waveform.and.mic",
                           color: .brandAccent, step: 4, totalSteps: 4)

                ScrollView {
                    VStack(spacing: 22) {
                        // Instruction card
                        instructionCard
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                        // Passage with real-time color feedback
                        PassageReadingView(
                            passageText: passage.fluencyText,
                            targetWords: targetWords,
                            spokenWords: speechRec.spokenWords
                        )
                        .padding(.horizontal, 20)

                        // Permission warning
                        if hasPermission == false {
                            HStack(spacing: 10) {
                                Image(systemName: "mic.slash.fill").foregroundColor(.brandRed)
                                Text("Microphone access required. Please allow in Settings.")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(.brandRed)
                            }
                            .padding(14)
                            .background(Color.brandRed.opacity(0.08))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }

                        // Controls
                        controlsSection
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showResult) {
            EvaluationResultView(
                result: EvaluationResult(
                    comprehensionScore: comprehensionScore,
                    vocabularyScore:    vocabularyScore,
                    reLearningScore:    reLearningScore,
                    fluencyScore:       fluencyScore
                )
            )
        }
        .onAppear { checkPermission() }
        .onDisappear { speechRec.stopRecording() }
    }

    // MARK: Instruction Card
    var instructionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.brandAccent)
                Text("How it works")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.brandAccent)
            }
            VStack(alignment: .leading, spacing: 6) {
                instructionRow(icon: "play.circle.fill", text: "Tap the mic and read the passage aloud")
                instructionRow(icon: "circle.fill", color: .brandGreen, text: "Words turn green when read correctly")
                instructionRow(icon: "circle.fill", color: .brandRed,   text: "Words turn red when misread")
                instructionRow(icon: "pause.circle.fill", text: "Pause anytime — tap Next to submit")
            }
        }
        .padding(16)
        .background(Color.brandAccent.opacity(0.06))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.brandAccent.opacity(0.2), lineWidth: 1))
    }

    func instructionRow(icon: String, color: Color = .brandAccent, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 18)
            Text(text)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.secondary)
        }
    }

    // MARK: Controls Section
    var controlsSection: some View {
        VStack(spacing: 16) {
            // Mic button + state label
            VStack(spacing: 10) {
                Button { toggleRecording() } label: {
                    ZStack {
                        // Pulse ring when recording
                        if isRecording && !isPaused {
                            Circle()
                                .stroke(Color.brandRed.opacity(0.35), lineWidth: 4)
                                .frame(width: 90, height: 90)
                                .scaleEffect(1.2)
                                .opacity(0)
                                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false), value: isRecording)
                        }
                        Circle()
                            .fill(isRecording && !isPaused ? Color.brandRed : Color.brandAccent)
                            .frame(width: 76, height: 76)
                            .shadow(color: (isRecording && !isPaused ? Color.brandRed : Color.brandAccent).opacity(0.4),
                                    radius: 12)
                        Image(systemName: isRecording && !isPaused ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }

                Text(isRecording && !isPaused ? "Recording... Tap to pause" :
                     isPaused ? "Paused" : "Tap to start reading")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            // Pause / Resume (shown when actively recording)
            if isRecording {
                Button {
                    togglePause()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                        Text(isPaused ? "Resume Reading" : "Pause")
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.brandAccent)
                    .padding(.horizontal, 20).padding(.vertical, 11)
                    .background(Color.brandAccent.opacity(0.1))
                    .cornerRadius(10)
                }
            }

            // Next / Finish — shown once any words are recorded (even partially)
            if !speechRec.spokenWords.isEmpty {
                Button {
                    speechRec.stopRecording()
                    isRecording = false; isPaused = false
                    calculateFluencyScore()
                    showResult = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text(speechRec.spokenWords.count >= targetWords.count
                             ? "Finish & See Results"
                             : "Submit Partial Reading")
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(LinearGradient(
                        colors: [Color.brandAccent, Color(hex: "E17055")],
                        startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }

            // Skip
            Button("Skip Fluency Test") {
                fluencyScore = 0; showResult = true
            }
            .font(.system(size: 14, design: .rounded))
            .foregroundColor(.secondary)
        }
    }

    // MARK: Actions
    private func toggleRecording() {
        HapticManager.impact(.medium)
        if isRecording && !isPaused {
            speechRec.stopRecording()
            isRecording = false; isPaused = false
        } else {
            speechRec.startRecording()
            isRecording = true; isPaused = false
        }
    }

    private func togglePause() {
        HapticManager.impact(.light)
        if isPaused {
            speechRec.startRecording()
            isPaused = false
        } else {
            speechRec.stopRecording()
            isPaused = true
        }
    }

    private func calculateFluencyScore() {
        let spoken = speechRec.spokenWords
        guard !targetWords.isEmpty else { fluencyScore = 0; return }
        let correct = targetWords.prefix(max(spoken.count, targetWords.count))
            .enumerated()
            .filter { idx, word in idx < spoken.count && spoken[idx] == word }
            .count
        fluencyScore = ScoreEngine.evaluationScore(correct: correct, total: targetWords.count)
    }

    private func checkPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { hasPermission = status == .authorized }
        }
    }
}

// MARK: - Passage Reading View (continuous text with real-time color)
struct PassageReadingView: View {
    let passageText: String
    let targetWords: [String]
    let spokenWords: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Text("Read this passage aloud")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                // Live word count
                if !spokenWords.isEmpty {
                    Text("\(spokenWords.count)/\(targetWords.count) words")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.brandAccent)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color.brandAccent.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // Passage rendered as colored inline text
            coloredPassageText
                .padding(18)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        }
        .padding(16)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(18)
    }

    var coloredPassageText: some View {
        // Build attributedString-style text by combining colored Text views
        // We split by spaces and color each word based on spoken status
        let originalWords = passageText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

        // Map: original word index → spoken word index (punctuation-cleaned)
        return Group {
            originalWords.indices.reduce(Text("")) { result, idx in
                let original = originalWords[idx]
                let clean    = original.lowercased().trimmingCharacters(in: .punctuationCharacters)
                let color: Color
                if idx < spokenWords.count {
                    color = spokenWords[idx] == clean ? Color(hex: "00B894") : Color(hex: "E17055")
                } else if idx == spokenWords.count {
                    // next word to speak — highlight in blue
                    color = Color(hex: "6C5CE7")
                } else {
                    color = .primary.opacity(0.8)
                }
                let space = idx < originalWords.count - 1 ? " " : ""
                return result + Text(original + space)
                    .foregroundColor(color)
                    .font(.system(size: 17, weight: idx == spokenWords.count ? .bold : .regular, design: .rounded))
            }
        }
    }
}

// Kept for backward-compat (FlowLayout used elsewhere)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                                  proposal: ProposedViewSize(frame.size))
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
            for subview in subviews {
                let sz = subview.sizeThatFits(.unspecified)
                if x + sz.width > maxWidth && x > 0 { y += rowH + spacing; x = 0; rowH = 0 }
                frames.append(CGRect(origin: CGPoint(x: x, y: y), size: sz))
                rowH = max(rowH, sz.height)
                x += sz.width + spacing
            }
            size = CGSize(width: maxWidth, height: y + rowH)
        }
    }
}
