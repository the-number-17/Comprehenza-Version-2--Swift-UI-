import Foundation
import Supabase

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserEmail: String?
    @Published var showEmailConfirmation = false
    @Published var confirmationEmail: String?
    
    private let supabase = SupabaseManager.shared.client
    
    init() {
        setupAuthStateListener()
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        Task {
            // In the current SDK, authStateChanges is the correct AsyncSequence
            for await (event, session) in supabase.auth.authStateChanges {
                print("🔑 Auth Event: \(event)")
                if event == .signedIn || event == .initialSession || event == .tokenRefreshed {
                    if let session = session {
                        self.isAuthenticated = true
                        self.currentUserEmail = session.user.email
                        self.showEmailConfirmation = false
                    }
                } else if event == .signedOut {
                    self.isAuthenticated = false
                    self.currentUserEmail = nil
                }
            }
        }
    }
    
    // MARK: - Check Existing Session
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            isAuthenticated = true
            currentUserEmail = session.user.email
            showEmailConfirmation = false
        } catch {
            isAuthenticated = false
            currentUserEmail = nil
        }
    }
    
    func refreshSession() async {
        await checkSession()
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String) async {
        guard validate(email: email, password: password) else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            // Check if we got a session back (auto-confirm enabled)
            if response.session != nil {
                // Auto-confirmed — sign the user in
                currentUserEmail = response.user.email
                isAuthenticated = true
            } else {
                // Email confirmation required — show message
                confirmationEmail = email
                showEmailConfirmation = true
            }
        } catch {
            let desc = error.localizedDescription.lowercased()
            print("⚠️ Sign Up Error: \(error)")
            
            // Check if user already exists — Supabase returns a fake success 
            // for existing users to prevent email enumeration
            if desc.contains("already") || desc.contains("registered") || desc.contains("exists") {
                errorMessage = "This email is already registered. Try logging in."
            } else {
                errorMessage = simplifyError(error)
            }
        }
        
        isLoading = false
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async {
        guard validate(email: email, password: password) else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            currentUserEmail = session.user.email
            isAuthenticated = true
        } catch {
            print("⚠️ Sign In Error: \(error)")
            errorMessage = simplifyError(error)
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            isAuthenticated = false
            currentUserEmail = nil
        } catch {
            errorMessage = "Couldn't sign out. Try again."
        }
    }
    
    // MARK: - Dismiss Confirmation
    func dismissConfirmation() {
        showEmailConfirmation = false
        confirmationEmail = nil
    }
    
    // MARK: - Validation
    private func validate(email: String, password: String) -> Bool {
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Please enter your email."
            return false
        }
        
        if !email.contains("@") || !email.contains(".") {
            errorMessage = "Please enter a valid email."
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return false
        }
        
        return true
    }
    
    private func simplifyError(_ error: Error) -> String {
        let desc = error.localizedDescription.lowercased()
        if desc.contains("invalid") || desc.contains("credentials") || desc.contains("invalid login") {
            return "Wrong email or password. Try again."
        } else if desc.contains("already") || desc.contains("exists") {
            return "This email is already registered. Try signing in."
        } else if desc.contains("network") || desc.contains("connection") {
            return "No internet connection. Check your network."
        } else if desc.contains("email not confirmed") || desc.contains("confirm") {
            return "Please confirm your email first, then log in."
        } else {
            return "Something went wrong. Please try again."
        }
    }
}
