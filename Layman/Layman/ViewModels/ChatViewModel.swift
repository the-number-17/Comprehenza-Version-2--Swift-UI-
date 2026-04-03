import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var suggestions: [String] = []
    @Published var inputText = ""
    @Published var isLoading = false
    
    private let aiService = AIService.shared
    private let article: Article
    private let articlesViewModel: ArticlesViewModel
    
    var articleContext: String {
        // Build robust context — use whatever info we have
        var parts: [String] = []
        parts.append(article.title)
        if let desc = article.description, !desc.isEmpty {
            parts.append(desc)
        }
        if let content = article.content, !content.isEmpty {
            parts.append(content)
        }
        let cards = article.laymanCards.filter { !$0.isEmpty }
        if !cards.isEmpty {
            parts.append(cards.joined(separator: " "))
        }
        let combined = parts.joined(separator: ". ")
        return combined.isEmpty ? "General news article" : combined
    }
    
    init(article: Article, articlesViewModel: ArticlesViewModel) {
        self.article = article
        self.articlesViewModel = articlesViewModel
        
        // Initial bot greeting
        messages.append(ChatMessage(
            content: "Hi, I'm Layman! I'm simplifying this article for you right now. Ask me anything and I'll explain it simply. 😊",
            isUser: false
        ))
        
        // Enrich article and generate suggestions in background
        Task {
            await articlesViewModel.enrichArticleWithAI(article)
            await generateSuggestions()
        }
    }
    
    // MARK: - Send Message
    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        
        // Clear suggestions after first user message
        suggestions = []
        
        isLoading = true
        
        do {
            let response = try await aiService.sendMessage(text, articleContext: articleContext)
            let botMessage = ChatMessage(content: response, isUser: false)
            messages.append(botMessage)
        } catch {
            print("❌ Chat Error: \(error.localizedDescription)")
            print("❌ Chat Error Detail: \(error)")
            let errorMsg = ChatMessage(
                content: "Sorry, I couldn't get an answer right now. Please try asking again!",
                isUser: false
            )
            messages.append(errorMsg)
        }
        
        isLoading = false
    }
    
    // MARK: - Send Suggestion
    func sendSuggestion(_ suggestion: String) async {
        inputText = suggestion
        await sendMessage()
    }
    
    // MARK: - Generate Suggestions
    private func generateSuggestions() async {
        do {
            let content = article.laymanCards.isEmpty
                ? (article.description ?? article.title)
                : article.laymanCards.joined(separator: " ")
            
            let questions = try await aiService.generateSuggestions(
                for: article.laymanTitle.isEmpty ? article.title : article.laymanTitle,
                articleContent: content
            )
            suggestions = questions
        } catch {
            print("⚠️ Suggestions Error: \(error)")
            // Fallback suggestions
            suggestions = [
                "What's the main point here?",
                "Why does this matter?",
                "Who's involved in this?"
            ]
        }
    }
}
