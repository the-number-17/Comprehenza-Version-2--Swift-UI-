import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var name   = ""
    @State private var age    = 12
    @State private var avatar: Avatar = .owl
    @State private var step   = 0
    @State private var slideOffset: CGFloat = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "EEE9FF"), Color(hex: "FFFFFF")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i == step ? Color.brandPrimary : Color.brandSecondary.opacity(0.4))
                            .frame(width: i == step ? 28 : 10, height: 8)
                            .animation(.spring(response: 0.4), value: step)
                    }
                }
                .padding(.top, 56)

                Spacer()

                // Step content
                Group {
                    if step == 0 { nameStep }
                    else if step == 1 { ageStep }
                    else { avatarStep }
                }
                .offset(x: slideOffset)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .id(step)

                Spacer()

                // Action button
                Button(step < 2 ? "Continue →" : "Let's Go! 🚀") {
                    HapticManager.impact(.medium)
                    advance()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(step == 0 && name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 28)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: Steps
    var nameStep: some View {
        VStack(spacing: 28) {
            Text("👋").font(.system(size: 70))
            Text("What's your name?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.brandPrimary)
            Text("Tell us your first name so we can personalise your experience.")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            TextField("Your name", text: $name)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                .padding(.horizontal, 40)
        }
    }

    var ageStep: some View {
        VStack(spacing: 28) {
            Text("🎂").font(.system(size: 70))
            Text("How old are you?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.brandPrimary)
            Text("This helps us set the right exercises for you.")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.secondary)

            // Age Picker
            VStack(spacing: 12) {
                Text("\(age) years old")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(.brandPrimary)

                HStack(spacing: 24) {
                    Button {
                        if age > 9 { age -= 1; HapticManager.impact(.light) }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 38))
                            .foregroundColor(age > 9 ? .brandPrimary : .secondary)
                    }

                    Button {
                        if age < 16 { age += 1; HapticManager.impact(.light) }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 38))
                            .foregroundColor(age < 16 ? .brandPrimary : .secondary)
                    }
                }
            }
            .padding(32)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemGray6)))
            .padding(.horizontal, 40)
        }
    }

    var avatarStep: some View {
        VStack(spacing: 28) {
            Text("Choose your buddy!")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.brandPrimary)
            Text("This avatar will represent you in the app. (Optional)")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(Avatar.allCases, id: \.self) { av in
                    Button {
                        withAnimation(.spring(response: 0.3)) { avatar = av }
                        HapticManager.impact(.light)
                    } label: {
                        VStack(spacing: 8) {
                            Text(av.emoji)
                                .font(.system(size: 44))
                            Text(av.rawValue.capitalized)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(avatar == av ? av.color.opacity(0.18) : Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(avatar == av ? av.color : Color.clear, lineWidth: 3)
                        )
                        .scaleEffect(avatar == av ? 1.05 : 1)
                    }
                }
            }
            .padding(.horizontal, 28)
        }
    }

    private func advance() {
        if step < 2 {
            withAnimation(.spring(response: 0.4)) { step += 1 }
        } else {
            appState.updateProfile(name: name.trimmingCharacters(in: .whitespaces), age: age, avatar: avatar)
        }
    }
}
