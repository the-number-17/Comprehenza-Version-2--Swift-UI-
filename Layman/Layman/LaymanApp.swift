import SwiftUI

@main
struct LaymanApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    WelcomeView()
                        .environmentObject(authViewModel)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: authViewModel.isAuthenticated)
        }
    }
}
