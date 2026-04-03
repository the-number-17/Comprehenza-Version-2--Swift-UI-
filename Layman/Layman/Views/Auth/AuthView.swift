import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = true
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.laymanCream
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Layman")
                            .font(LaymanFont.logo(36))
                            .foregroundColor(.laymanDark)
                        
                        Text(isSignUp ? "Create your account" : "Welcome back")
                            .font(LaymanFont.headline(18))
                            .foregroundColor(.laymanGray)
                    }
                    
                    // Email Confirmation Banner
                    if authViewModel.showEmailConfirmation {
                        emailConfirmationBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Form Card
                    VStack(spacing: 20) {
                        // Mode toggle
                        HStack(spacing: 0) {
                            modeButton("Sign Up", isActive: isSignUp) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isSignUp = true
                                    authViewModel.errorMessage = nil
                                    authViewModel.dismissConfirmation()
                                }
                            }
                            
                            modeButton("Log In", isActive: !isSignUp) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isSignUp = false
                                    authViewModel.errorMessage = nil
                                    authViewModel.dismissConfirmation()
                                }
                            }
                        }
                        .background(Color.laymanBeige)
                        .cornerRadius(12)
                        .padding(.horizontal, 4)
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(LaymanFont.caption(13))
                                .foregroundColor(.laymanGray)
                            
                            TextField("your@email.com", text: $email)
                                .font(LaymanFont.body())
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($focusedField, equals: .email)
                                .padding(14)
                                .background(Color.laymanBeige.opacity(0.5))
                                .cornerRadius(12)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(LaymanFont.caption(13))
                                .foregroundColor(.laymanGray)
                            
                            SecureField("At least 6 characters", text: $password)
                                .font(LaymanFont.body())
                                .textContentType(isSignUp ? .newPassword : .password)
                                .focused($focusedField, equals: .password)
                                .padding(14)
                                .background(Color.laymanBeige.opacity(0.5))
                                .cornerRadius(12)
                        }
                        
                        // Error message
                        if let error = authViewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.red.opacity(0.8))
                                
                                Text(error)
                                    .font(LaymanFont.caption(13))
                                    .foregroundColor(.red.opacity(0.8))
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.06))
                            .cornerRadius(10)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                        
                        // Submit button
                        Button {
                            focusedField = nil
                            Task {
                                if isSignUp {
                                    await authViewModel.signUp(email: email, password: password)
                                    // If confirmation shown, auto-switch to login
                                    if authViewModel.showEmailConfirmation {
                                        withAnimation(.easeInOut(duration: 0.4)) {
                                            isSignUp = false
                                        }
                                    }
                                } else {
                                    await authViewModel.signIn(email: email, password: password)
                                }
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.laymanOrange)
                                    .frame(height: 52)
                                
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Log In")
                                        .font(LaymanFont.headline(16))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(authViewModel.isLoading)
                    }
                    .padding(24)
                    .background(Color.laymanCardBg)
                    .cornerRadius(LaymanDimension.cornerRadius)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
                    
                    // Toggle text
                    Button {
                        withAnimation {
                            isSignUp.toggle()
                            authViewModel.errorMessage = nil
                            authViewModel.dismissConfirmation()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.laymanGray)
                            Text(isSignUp ? "Log In" : "Sign Up")
                                .foregroundColor(.laymanOrange)
                                .bold()
                        }
                        .font(LaymanFont.caption(14))
                    }
                    
                    Spacer().frame(height: 20)
                }
                .padding(.horizontal, LaymanDimension.screenPadding)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private var emailConfirmationBanner: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 36))
                .foregroundColor(.laymanOrange)
            
            VStack(spacing: 4) {
                Text("Check your email!")
                    .font(LaymanFont.headline(18))
                    .foregroundColor(.laymanDark)
                
                Text(authViewModel.confirmationEmail ?? "your email")
                    .font(LaymanFont.small(12))
                    .foregroundColor(.laymanOrange)
                    .bold()
            }
            
            Text("We sent a confirmation link to your inbox. Tap the link in your email, then come back here.")
                .font(LaymanFont.body(14))
                .foregroundColor(.laymanGray)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            
            Button {
                Task {
                    await authViewModel.refreshSession()
                }
            } label: {
                HStack(spacing: 8) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Check Status")
                            .font(LaymanFont.headline(15))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.laymanOrange)
                .cornerRadius(12)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.laymanOrange.opacity(0.08))
        .cornerRadius(LaymanDimension.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LaymanDimension.cornerRadius)
                .stroke(Color.laymanOrange.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func modeButton(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(LaymanFont.headline(14))
                .foregroundColor(isActive ? .white : .laymanGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isActive ? Color.laymanOrange : Color.clear)
                .cornerRadius(10)
        }
    }
}

// MARK: - Reusable Back Button
struct BackButton: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.laymanDark)
                .frame(width: 36, height: 36)
                .background(Color.laymanBeige.opacity(0.8))
                .clipShape(Circle())
        }
    }
}

#Preview {
    NavigationStack {
        AuthView()
            .environmentObject(AuthViewModel())
    }
}
