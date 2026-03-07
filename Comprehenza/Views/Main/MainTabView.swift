import SwiftUI

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(0)

            JourneyView()
                .tabItem {
                    Label("Journey", systemImage: "map.fill")
                }
                .tag(1)

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.xaxis")
                }
                .tag(2)

            ReadBuddyView()
                .tabItem {
                    Label("ReadBuddy", systemImage: "message.fill")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(4)
        }
        .tint(.brandPrimary)
        .onAppear {
            // Custom tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            UITabBar.appearance().standardAppearance  = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
