import Foundation
import Supabase

@MainActor
final class SavedArticlesViewModel: ObservableObject {
    @Published var savedArticles: [Article] = []
    @Published var searchText = ""
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared.client
    
    var filteredArticles: [Article] {
        if searchText.isEmpty {
            return savedArticles
        }
        return savedArticles.filter {
            $0.laymanTitle.localizedCaseInsensitiveContains(searchText) ||
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.sourceName ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func fetchSavedArticles() async {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else { return }
        
        isLoading = true
        
        do {
            let response: [SavedArticleRow] = try await supabase
                .from("saved_articles")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            savedArticles = response.map { $0.toArticle() }
        } catch {
            // Keep existing list on error
        }
        
        isLoading = false
    }
    
    func removeArticle(_ article: Article) async {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else { return }
        
        // Optimistic removal
        savedArticles.removeAll { $0.id == article.id }
        
        do {
            try await supabase
                .from("saved_articles")
                .delete()
                .eq("article_id", value: article.id)
                .eq("user_id", value: userId)
                .execute()
        } catch {
            // Re-fetch on failure
            await fetchSavedArticles()
        }
    }
}
