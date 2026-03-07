import SwiftUI

@main
struct ComprehenzaApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isShowingSplash {
                SplashView()
            } else if appState.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.isLoggedIn)
        .animation(.easeInOut(duration: 0.4), value: appState.isShowingSplash)
    }
}
