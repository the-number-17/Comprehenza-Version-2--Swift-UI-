import SwiftUI

// MARK: - Evaluation Intro
struct EvaluationIntroView: View {
    @Environment(\.dismiss) var dismiss
    @State private var startEval = false
    @State private var appear = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "EEE9FF"), Color.white],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Hero
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.brandPrimary.opacity(0.1))
                                    .frame(width: 120, height: 120)
                                Text("🎯")
                                    .font(.system(size: 60))
                            }
                            Text("Evaluation Test")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(.brandPrimary)
                            Text("Let's find your reading level!")
                                .font(.system(size: 17, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 32)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)

                        // Info cards
                        VStack(spacing: 14) {
                            EvalInfoCard(icon: "brain.head.profile", color: .brandPrimary,
                                         title: "Comprehension", subtitle: "5 MCQs · 15 seconds each")
                            EvalInfoCard(icon: "textformat.abc", color: .brandTeal,
                                         title: "Vocabulary", subtitle: "Word-meaning match · 1 minute")
                            EvalInfoCard(icon: "arrow.clockwise", color: .brandOrange,
                                         title: "Relearning", subtitle: "Fill in the blanks · 5 questions")
                            EvalInfoCard(icon: "waveform.and.mic", color: .brandAccent,
                                         title: "Fluency", subtitle: "Read aloud · Real-time feedback")
                        }
                        .padding(.horizontal, 20)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 30)

                        // Total score note
                        HStack(spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.brandPrimary)
                            Text("Each section is scored out of 100. Your total **Comprehenza Quotient** is out of 400.")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(Color.brandPrimary.opacity(0.07))
                        .cornerRadius(14)
                        .padding(.horizontal, 20)

                        // Buttons
                        VStack(spacing: 12) {
                            NavigationLink(destination: ComprehensionTestView()) {
                                Label("Start Evaluation", systemImage: "play.fill")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.brandPrimary))
                            }

                            Button("Maybe Later") { dismiss() }
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) { appear = true }
        }
    }
}

struct EvalInfoCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary.opacity(0.5))
                .font(.system(size: 14))
        }
        .padding(16)
        .cardStyle()
    }
}
