import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var sent  = false
    @State private var notFound = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F0EEFF").ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Text(sent ? "📬" : "🔑")
                            .font(.system(size: 64))
                            .animation(.spring(), value: sent)

                        Text(sent ? "Reset Link Sent!" : "Forgot Password?")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.brandPrimary)

                        Text(sent
                             ? "If an account with \(email) exists, a reset link has been sent to your email."
                             : "Enter your email address and we'll help you reset your password.")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)

                    if !sent {
                        VStack(spacing: 16) {
                            AuthTextField(icon: "envelope.fill", placeholder: "Email Address", text: $email, type: .emailAddress)

                            if notFound {
                                Text("No account found with this email.")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(.brandRed)
                            }

                            Button("Send Reset Link") {
                                HapticManager.impact(.light)
                                let found = appState.forgotPassword(email: email)
                                withAnimation(.spring()) { sent = true }
                                HapticManager.notification(found ? .success : .warning)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(email.isEmpty)
                        }
                        .padding(.horizontal, 28)
                    } else {
                        Button("Back to Login") {
                            dismiss()
                        }
                        .buttonStyle(PrimaryButtonStyle(color: .brandGreen))
                        .padding(.horizontal, 28)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.brandPrimary)
                }
            }
        }
    }
}
