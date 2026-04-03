import Foundation
import Supabase

@MainActor
final class ArticlesViewModel: ObservableObject {
    @Published var featuredArticles: [Article] = []
    @Published var todaysPicks: [Article] = []
    @Published var allArticles: [Article] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEnhancingWithAI = false
    
    private let newsService = NewsService.shared
    private let geminiService = GeminiService.shared
    private let supabase = SupabaseManager.shared.client
    private var savedArticleIds: Set<String> = []
    
    var filteredTodaysPicks: [Article] {
        if searchText.isEmpty {
            return todaysPicks
        }
        return todaysPicks.filter {
            $0.laymanTitle.localizedCaseInsensitiveContains(searchText) ||
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.sourceName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Fetch Articles
    func fetchArticles() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch saved article IDs first
            await loadSavedArticleIds()
            
            let articles = try await newsService.fetchArticles()
            
            // Mark saved articles
            let processed = articles.map { article -> Article in
                var a = article
                a.isSaved = savedArticleIds.contains(a.id)
                return a
            }
            
            allArticles = processed
            
            // First 5 articles for featured carousel
            featuredArticles = Array(processed.prefix(5))
            
            // Remaining for Today's Picks
            if processed.count > 5 {
                todaysPicks = Array(processed.dropFirst(5))
            } else {
                todaysPicks = processed
            }
            
            // OPTIMIZATION: Automatic enhancement removed — only trigger manually now
            
        } catch {
            errorMessage = "Couldn't load articles. Pull to refresh."
        }
        
        isLoading = false
    }
    
    // MARK: - AI Enhancement (ON-DEMAND ONLY)
    /// Enriches an article with a simplified headline, summary cards, and expanded content.
    /// Triggered only when the user interacts with 'Ask Layman'.
    func enrichArticleWithAI(_ article: Article) async {
        guard let index = allArticles.firstIndex(where: { $0.id == article.id }) else { return }
        
        // If already enriched, skip to save quota
        if allArticles[index].expandedContent != nil && !allArticles[index].laymanCards.isEmpty {
            return
        }
        
        isEnhancingWithAI = true
        
        do {
            // 1. Simplify Headline (if missing)
            if allArticles[index].laymanTitle.isEmpty {
                let simpleHeadline = try await geminiService.simplifyHeadline(article.title)
                if !simpleHeadline.isEmpty {
                    allArticles[index].laymanTitle = simpleHeadline
                }
            }
            
            // 2. Generate Summary Cards (if missing)
            if allArticles[index].laymanCards.isEmpty {
                let content = article.content ?? article.description ?? article.title
                let cards = try await geminiService.generateContentCards(for: content)
                if !cards.isEmpty {
                    allArticles[index].laymanCards = cards
                }
            }
            
            // 3. Expand Full Story (if missing or truncated)
            let currentContent = allArticles[index].content ?? ""
            if allArticles[index].expandedContent == nil && (currentContent.count < 1000 || currentContent.contains("PAID PLANS")) {
                let expandedContent = try await geminiService.expandFullStory(
                    title: article.title,
                    description: article.description ?? "",
                    partialContent: article.content
                )
                if !expandedContent.isEmpty {
                    allArticles[index].expandedContent = expandedContent
                }
            }
            
            // Trigger UI refresh
            updateDisplayArrays()
            
        } catch {
            print("⚠️ AI enrichment failed for article \(article.id): \(error.localizedDescription)")
        }
        
        isEnhancingWithAI = false
    }
    
    private func updateDisplayArrays() {
        featuredArticles = Array(allArticles.prefix(5))
        if allArticles.count > 5 {
            todaysPicks = Array(allArticles.dropFirst(5))
        } else {
            todaysPicks = allArticles
        }
    }
    
    // MARK: - Save/Unsave
    func toggleSave(_ article: Article) async {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else { return }
        
        if let index = allArticles.firstIndex(where: { $0.id == article.id }) {
            let wasSaved = allArticles[index].isSaved
            allArticles[index].isSaved.toggle()
            updateDisplayArrays()
            
            do {
                if wasSaved {
                    // Remove from saved
                    try await supabase
                        .from("saved_articles")
                        .delete()
                        .eq("article_id", value: article.id)
                        .eq("user_id", value: userId)
                        .execute()
                    savedArticleIds.remove(article.id)
                } else {
                    // Save article
                    let row = SavedArticleRow(from: allArticles[index], userId: userId)
                    try await supabase
                        .from("saved_articles")
                        .insert(row)
                        .execute()
                    savedArticleIds.insert(article.id)
                }
            } catch {
                // Revert on failure
                allArticles[index].isSaved = wasSaved
                updateDisplayArrays()
            }
        }
    }
    
    // MARK: - Load Saved IDs
    private func loadSavedArticleIds() async {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else { return }
        
        do {
            let response: [SavedArticleRow] = try await supabase
                .from("saved_articles")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            
            savedArticleIds = Set(response.map { $0.article_id })
        } catch {
            // Silently fail — articles will show as unsaved
        }
    }
}
