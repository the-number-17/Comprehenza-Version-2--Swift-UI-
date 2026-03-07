import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @State private var email    = ""
    @State private var password = ""
    @State private var errorMsg = ""
    @State private var showRegister     = false
    @State private var showForgotPwd    = false
    @State private var isLoading        = false
    @State private var showOnboarding   = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "F0EEFF"), Color(hex: "FFFFFF")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            // App logo
                            ZStack {
                                Circle()
                                    .fill(Color.brandPrimary.opacity(0.08))
                                    .frame(width: 106, height: 106)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 92, height: 92)
                                    .shadow(color: Color.brandPrimary.opacity(0.2), radius: 10, y: 4)
                                Image("comprehenza_logo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 68, height: 68)
                            }
                            Text("Comprehenza")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.brandPrimary)
                            Text("Welcome back! Ready to read?")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 48)

                        // Form
                        VStack(spacing: 16) {
                            AuthTextField(icon: "envelope.fill", placeholder: "Email", text: $email, type: .emailAddress)
                            AuthTextField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)

                            if !errorMsg.isEmpty {
                                Text(errorMsg)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(.brandRed)
                                    .padding(.horizontal, 8)
                                    .offset(x: shakeOffset)
                            }

                            // Forgot Password
                            HStack {
                                Spacer()
                                Button("Forgot Password?") { showForgotPwd = true }
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.brandPrimary)
                            }

                            // Login Button
                            Button {
                                attemptLogin()
                            } label: {
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView().tint(.white)
                                    }
                                    Text("Log In")
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(isLoading)

                            // Divider
                            HStack {
                                Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                                Text("or").font(.system(size: 14, design: .rounded)).foregroundColor(.secondary)
                                Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
                            }

                            // Register
                            Button {
                                showRegister = true
                            } label: {
                                Text("Create New Account")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(.brandPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.brandPrimary, lineWidth: 2)
                                    )
                            }
                        }
                        .padding(.horizontal, 28)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
            .sheet(isPresented: $showForgotPwd) {
                ForgotPasswordView()
            }
        }
    }

    private func attemptLogin() {
        HapticManager.impact(.light)
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isLoading = false
            if let err = appState.login(email: email, password: password) {
                errorMsg = err
                withAnimation(.interpolatingSpring(stiffness: 600, damping: 8)) {
                    shakeOffset = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    shakeOffset = 0
                }
                HapticManager.notification(.error)
            } else {
                HapticManager.notification(.success)
                // Check if onboarding needed
                if appState.currentUser?.name.isEmpty == true {
                    showOnboarding = true
                }
            }
        }
    }
}

// MARK: - Auth Text Field Component
struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var type: UITextContentType? = nil
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.brandPrimary)
                .frame(width: 22)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(.system(size: 16, design: .rounded))
            } else {
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, design: .rounded))
                    .textContentType(type)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(text.isEmpty ? Color.clear : Color.brandPrimary.opacity(0.5), lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}
