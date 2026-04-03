import SwiftUI

struct AllNewsView: View {
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    private let categories = ["All", "Business", "Technology"]
    
    var filteredArticles: [Article] {
        var articles = articlesViewModel.allArticles
        
        // Apply search filter
        if !searchText.isEmpty {
            articles = articles.filter {
                $0.laymanTitle.localizedCaseInsensitiveContains(searchText) ||
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.sourceName ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.description ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return articles
    }
    
    var body: some View {
        ZStack {
            Color.laymanCream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.laymanGray)
                        .font(.system(size: 14))
                    
                    TextField("Search all articles...", text: $searchText)
                        .font(LaymanFont.body(15))
                    
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
                .padding(12)
                .background(Color.laymanBeige)
                .cornerRadius(14)
                .padding(.horizontal, LaymanDimension.screenPadding)
                .padding(.vertical, 10)
                
                // Article count
                HStack {
                    Text("\(filteredArticles.count) article\(filteredArticles.count == 1 ? "" : "s")")
                        .font(LaymanFont.caption(13))
                        .foregroundColor(.laymanGray)
                    
                    Spacer()
                    
                    if articlesViewModel.isEnhancingWithAI {
                        HStack(spacing: 6) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.laymanOrange)
                            Text("AI enhancing...")
                                .font(LaymanFont.small(11))
                                .foregroundColor(.laymanOrange)
                        }
                    }
                }
                .padding(.horizontal, LaymanDimension.screenPadding)
                .padding(.bottom, 8)
                
                // Articles list
                if filteredArticles.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: searchText.isEmpty ? "newspaper" : "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.laymanLightGray)
                        
                        Text(searchText.isEmpty ? "No articles yet" : "No articles match your search")
                            .font(LaymanFont.headline(16))
                            .foregroundColor(.laymanDark)
                        
                        Text(searchText.isEmpty ? "Pull to refresh and load articles." : "Try a different search term.")
                            .font(LaymanFont.body(14))
                            .foregroundColor(.laymanGray)
                    }
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredArticles) { article in
                                NavigationLink(destination: ArticleDetailView(article: article).environmentObject(articlesViewModel)) {
                                    ArticleRowView(article: article)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, LaymanDimension.screenPadding)
                        .padding(.bottom, 30)
                    }
                    .refreshable {
                        await articlesViewModel.fetchArticles()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 12) {
                    BackButton()
                    
                    Text("All News")
                        .font(LaymanFont.title(22))
                        .foregroundColor(.laymanDark)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AllNewsView()
            .environmentObject(ArticlesViewModel())
    }
}
