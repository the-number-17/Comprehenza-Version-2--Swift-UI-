import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var articlesViewModel = ArticlesViewModel()
    @StateObject private var savedArticlesViewModel = SavedArticlesViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .environmentObject(articlesViewModel)
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                Text("Home")
            }
            .tag(0)
            
            NavigationStack {
                SavedView()
                    .environmentObject(savedArticlesViewModel)
                    .environmentObject(articlesViewModel)
            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "bookmark.fill" : "bookmark")
                Text("Saved")
            }
            .tag(1)
            
            NavigationStack {
                ProfileView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                Text("Profile")
            }
            .tag(2)
        }
        .tint(.laymanOrange)
        .onAppear {
            // Style the tab bar
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(Color.laymanWhite)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
