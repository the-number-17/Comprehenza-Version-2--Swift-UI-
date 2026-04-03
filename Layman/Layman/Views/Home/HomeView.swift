import SwiftUI

struct HomeView: View {
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @State private var showSearch = false
    
    var body: some View {
        ZStack {
            Color.laymanCream.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header — logo + greeting inline
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Layman")
                                .font(LaymanFont.logo(28))
                                .foregroundColor(.laymanDark)
                            
                            Text("\(greetingText) · \(formattedDate)")
                                .font(LaymanFont.caption(13))
                                .foregroundColor(.laymanGray)
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSearch.toggle()
                            }
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.laymanDark)
                                .frame(width: 40, height: 40)
                                .background(Color.laymanBeige)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, LaymanDimension.screenPadding)
                    .padding(.top, 8)
                    
                    // Search bar (inline, not toolbar)
                    if showSearch {
                        SearchBarView(searchText: $articlesViewModel.searchText, showSearch: $showSearch)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Featured Section
                    if !articlesViewModel.featuredArticles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.laymanOrange)
                                
                                Text("Featured")
                                    .font(LaymanFont.headline(16))
                                    .foregroundColor(.laymanDark)
                            }
                            .padding(.horizontal, LaymanDimension.screenPadding)
                            
                            FeaturedCarouselView(articles: articlesViewModel.featuredArticles)
                                .environmentObject(articlesViewModel)
                        }
                    }
                    
                    // Today's Picks Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .center) {
                            Text("Today's Picks")
                                .font(LaymanFont.title(20))
                                .foregroundColor(.laymanDark)
                            
                            Spacer()
                            
                            NavigationLink(destination: AllNewsView().environmentObject(articlesViewModel)) {
                                HStack(spacing: 4) {
                                    Text("View All")
                                        .font(LaymanFont.caption(14))
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.laymanOrange)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.laymanOrange.opacity(0.08))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, LaymanDimension.screenPadding)
                        
                        // Article list
                        if articlesViewModel.filteredTodaysPicks.isEmpty && !articlesViewModel.searchText.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32))
                                    .foregroundColor(.laymanLightGray)
                                Text("No articles found")
                                    .font(LaymanFont.body())
                                    .foregroundColor(.laymanGray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(articlesViewModel.filteredTodaysPicks) { article in
                                    NavigationLink(destination: ArticleDetailView(article: article).environmentObject(articlesViewModel)) {
                                        ArticleRowView(article: article)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, LaymanDimension.screenPadding)
                        }
                    }
                    
                    // Bottom padding so last item isn't hidden by tab bar
                    Color.clear.frame(height: 80)
                }
            }
            .refreshable {
                await articlesViewModel.fetchArticles()
            }
            
            // Loading overlay
            if articlesViewModel.isLoading && articlesViewModel.allArticles.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.laymanOrange)
                        .scaleEffect(1.2)
                    Text("Loading your news...")
                        .font(LaymanFont.body())
                        .foregroundColor(.laymanGray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.laymanCream)
            }
        }
        .navigationBarHidden(true)
        .task {
            if articlesViewModel.allArticles.isEmpty {
                await articlesViewModel.fetchArticles()
            }
        }
    }
    
    // MARK: - Helpers
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning ☀️"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Late night reading 🌙"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - Search Bar
struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var showSearch: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.laymanGray)
                    .font(.system(size: 14))
                
                TextField("Search articles...", text: $searchText)
                    .font(LaymanFont.body(15))
                    .focused($isFocused)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.laymanGray)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(10)
            .background(Color.laymanBeige)
            .cornerRadius(12)
            
            Button("Cancel") {
                searchText = ""
                withAnimation {
                    showSearch = false
                }
            }
            .font(LaymanFont.caption(14))
            .foregroundColor(.laymanOrange)
        }
        .padding(.horizontal, LaymanDimension.screenPadding)
        .onAppear { isFocused = true }
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(ArticlesViewModel())
    }
}
