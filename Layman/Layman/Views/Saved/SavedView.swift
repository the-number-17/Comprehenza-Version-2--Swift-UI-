import SwiftUI

struct SavedView: View {
    @EnvironmentObject var savedArticlesViewModel: SavedArticlesViewModel
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @State private var showSearch = false
    
    var body: some View {
        ZStack {
            Color.laymanCream.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Header — matching HomeView style
                    HStack {
                        Text("Saved")
                            .font(LaymanFont.logo(28))
                            .foregroundColor(.laymanDark)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
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
                    
                    // Search bar
                    if showSearch {
                        SearchBarView(searchText: $savedArticlesViewModel.searchText, showSearch: $showSearch)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if savedArticlesViewModel.savedArticles.isEmpty && !savedArticlesViewModel.isLoading {
                        // Empty state
                        VStack(spacing: 16) {
                            Spacer().frame(height: 60)
                            Image(systemName: "bookmark")
                                .font(.system(size: 48))
                                .foregroundColor(.laymanLightGray)
                            
                            Text("No saved articles yet")
                                .font(LaymanFont.headline(18))
                                .foregroundColor(.laymanDark)
                            
                            Text("Bookmark articles to read them later")
                                .font(LaymanFont.body(15))
                                .foregroundColor(.laymanGray)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(savedArticlesViewModel.filteredArticles) { article in
                                NavigationLink(destination: ArticleDetailView(article: article).environmentObject(articlesViewModel)) {
                                    ArticleRowView(article: article)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        Task {
                                            await savedArticlesViewModel.removeArticle(article)
                                        }
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, LaymanDimension.screenPadding)
                    }
                    
                    // Bottom padding for tab bar
                    Color.clear.frame(height: 80)
                }
            }
            .refreshable {
                await savedArticlesViewModel.fetchSavedArticles()
            }
            
            if savedArticlesViewModel.isLoading {
                ProgressView()
                    .tint(.laymanOrange)
            }
        }
        .navigationBarHidden(true)
        .task {
            await savedArticlesViewModel.fetchSavedArticles()
        }
    }
}

#Preview {
    NavigationStack {
        SavedView()
            .environmentObject(SavedArticlesViewModel())
            .environmentObject(ArticlesViewModel())
    }
}
