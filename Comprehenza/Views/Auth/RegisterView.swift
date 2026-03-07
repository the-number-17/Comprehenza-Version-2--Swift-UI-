import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name       = ""
    @State private var email      = ""
    @State private var age        = 12
    @State private var password   = ""
    @State private var confirmPwd = ""
    @State private var errorMsg   = ""
    @State private var isLoading  = false
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color(hex: "6C5CE7").opacity(0.12), Color(hex: "F8F7FF"), Color(hex: "FD79A8").opacity(0.08)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    // Header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 80, height: 80)
                            Text("✨").font(.system(size: 40))
                        }
                        .shadow(color: Color(hex: "6C5CE7").opacity(0.4), radius: 12, y: 6)

                        Text("Create Account")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "6C5CE7"))
                        Text("Your reading adventure starts here!")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 44)

                    // Form Card
                    VStack(spacing: 14) {
                        AuthTextField(icon: "person.fill", placeholder: "Your Name", text: $name)

                        AuthTextField(icon: "envelope.fill", placeholder: "Email Address", text: $email, type: .emailAddress)

                        // Age picker row
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "6C5CE7").opacity(0.1))
                                    .frame(width: 42, height: 42)
                                Image(systemName: "birthday.cake.fill")
                                    .foregroundColor(Color(hex: "6C5CE7"))
                                    .font(.system(size: 18))
                            }
                            Text("Age")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.primary)
                            Spacer()
                            HStack(spacing: 0) {
                                Button { if age > 9 { age -= 1 } } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(age > 9 ? Color(hex: "6C5CE7") : .secondary.opacity(0.4))
                                }
                                Text("\(age)")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                    .frame(width: 44)
                                Button { if age < 16 { age += 1 } } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(age < 16 ? Color(hex: "6C5CE7") : .secondary.opacity(0.4))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 6)
                        )

                        AuthTextField(icon: "lock.fill", placeholder: "Password (min 6 chars)", text: $password, isSecure: true)
                        AuthTextField(icon: "lock.rotation", placeholder: "Confirm Password", text: $confirmPwd, isSecure: true)

                        if !errorMsg.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(errorMsg)
                            }
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.brandRed)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.brandRed.opacity(0.08))
                            .cornerRadius(10)
                        }

                        Button {
                            attemptRegister()
                        } label: {
                            HStack(spacing: 10) {
                                if isLoading { ProgressView().tint(.white) }
                                Text("Create Account")
                                    .fontWeight(.bold)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isLoading)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.systemBackground).opacity(0.95))
                            .shadow(color: .black.opacity(0.08), radius: 16)
                    )
                    .padding(.horizontal, 20)

                    Text("By creating an account you agree to our educational use terms.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }

    private func attemptRegister() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMsg = "Please enter your name."
            HapticManager.notification(.error)
            return
        }
        guard password == confirmPwd else {
            errorMsg = "Passwords don't match."
            HapticManager.notification(.error)
            return
        }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isLoading = false
            if let err = appState.register(email: email, password: password, name: name, age: age) {
                errorMsg = err
                HapticManager.notification(.error)
            } else {
                HapticManager.notification(.success)
                showOnboarding = true
            }
        }
    }
}
