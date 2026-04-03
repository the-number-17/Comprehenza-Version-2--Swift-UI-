import Foundation

final class AIService {
    static let shared = AIService()
    
    private let geminiKey: String
    private let openRouterKey: String
    
    // Primary - Gemini
    private let geminiModel = "gemini-2.0-flash-lite"
    private let geminiBaseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    // Fallback - OpenRouter (Free Models)
    private let openRouterModel = "qwen/qwen3.6-plus:free" // More reliable free model
    private let openRouterBaseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    // Rate limiting
    private var lastRequestTime: Date = .distantPast
    private let minRequestInterval: TimeInterval = 1.0 // Reduced interval for flash-lite
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) else {
            fatalError("Secrets.plist not found")
        }
        
        self.geminiKey = dict["GEMINI_API_KEY"] as? String ?? ""
        self.openRouterKey = dict["OPENROUTER_API_KEY"] as? String ?? ""
    }
    
    // MARK: - Public Methods (Same as GeminiService)
    
    func sendMessage(_ userMessage: String, articleContext: String) async throws -> String {
        let context = articleContext.isEmpty ? "General news article" : articleContext
        let systemPrompt = "You are Layman, a friendly assistant. Explain news simply (2-3 sentences max). No jargon. Context: \(context)"
        return try await makeRequest(systemPrompt: systemPrompt, userMessage: userMessage)
    }
    
    func generateSuggestions(for articleTitle: String, articleContent: String) async throws -> [String] {
        let prompt = "Generate exactly 3 simple questions about this: \(articleTitle). \(articleContent). Return ONLY the questions, one per line."
        let response = try await makeRequest(systemPrompt: "Simple question generator.", userMessage: prompt)
        let questions = response.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(6) // Get a few more to filter duplicates
        
        // Ensure uniqueness for SwiftUI ForEach
        var uniqueQuestions: [String] = []
        for question in questions {
            if !uniqueQuestions.contains(question) && !question.isEmpty {
                uniqueQuestions.append(question)
            }
        }
        
        return Array(uniqueQuestions.prefix(3))
    }
    
    func simplifyHeadline(_ headline: String) async throws -> String {
        let prompt = "Rewrite simply: \(headline). No dots at the end. NEVER use [...] or truncate."
        return try await makeRequest(systemPrompt: "Headline simplifier.", userMessage: prompt)
    }
    
    func expandFullStory(title: String, description: String, partialContent: String?) async throws -> String {
        let content = partialContent ?? description
        let systemPrompt = "You are a professional journalist. Write a complete, well-structured news article. Use 4-5 paragraphs. Write in simple, clear language. NEVER use [...], '(read more)', ellipsis, or any truncation. Every sentence must be complete."
        let prompt = "Write a full news article based on this headline and snippet. Headline: \(title). Snippet: \(content)"
        let response = try await makeRequest(systemPrompt: systemPrompt, userMessage: prompt)
        return cleanAIOutput(response)
    }
    
    func generateContentCards(for articleContent: String) async throws -> [String] {
        let prompt = """
        Summarize this news into exactly 3 separate paragraphs numbered 1, 2, 3.
        
        Paragraph 1: What happened — explain the main event in 3 simple sentences.
        Paragraph 2: Why it matters — explain the impact or significance in 3 simple sentences.
        Paragraph 3: What's next — explain what could happen next in 3 simple sentences.
        
        Write in casual, easy-to-understand language. Separate each paragraph with a blank line.
        NEVER use [...] or truncate. Every sentence must be complete.
        
        Content: \(articleContent)
        """
        let response = try await makeRequest(
            systemPrompt: "News summarizer. Always produce exactly 3 paragraphs. Each paragraph has 3 complete sentences about a different aspect. Never truncate.",
            userMessage: prompt
        )
        
        // Parse paragraphs
        var paragraphs = response.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { line -> String in
                // Strip numbering like "1.", "2.", "3." or "1:", "2:", "3:"
                var cleaned = line
                if let first = cleaned.first, first.isNumber {
                    cleaned = String(cleaned.drop(while: { $0.isNumber || $0 == "." || $0 == ":" || $0 == " " }))
                }
                return cleanAIOutput(cleaned)
            }
            .filter { !$0.isEmpty && $0.count > 20 }
        
        // Remove duplicates
        var unique: [String] = []
        for p in paragraphs {
            if !unique.contains(p) {
                unique.append(p)
            }
        }
        
        // Guarantee exactly 3 cards
        if unique.count < 3 {
            // Generate additional cards
            let fillPrompt = "Write \(3 - unique.count) more simple paragraph(s) about this news, each with 3 sentences covering aspects not yet mentioned. Content: \(articleContent)"
            let extra = try await makeRequest(systemPrompt: "News summarizer. Write short paragraphs with 3 sentences each.", userMessage: fillPrompt)
            let extraParagraphs = extra.components(separatedBy: "\n\n")
                .map { cleanAIOutput($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                .filter { !$0.isEmpty && $0.count > 20 && !unique.contains($0) }
            unique.append(contentsOf: extraParagraphs)
        }
        
        return Array(unique.prefix(3))
    }
    
    // MARK: - Output Cleanup
    
    private func cleanAIOutput(_ text: String) -> String {
        var cleaned = text
        let markers = ["[...]", "(...)", "[Read more]", "(read more)", "ONLY AVAILABLE IN PAID PLANS"]
        for marker in markers {
            cleaned = cleaned.replacingOccurrences(of: marker, with: "", options: .caseInsensitive)
        }
        // Remove trailing ellipsis
        while cleaned.hasSuffix("...") {
            cleaned = String(cleaned.dropLast(3)).trimmingCharacters(in: .whitespaces)
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - API Orchestration
    
    private func makeRequest(systemPrompt: String, userMessage: String) async throws -> String {
        // Attempt 1: Gemini (Primary)
        do {
            return try await performGeminiRequest(systemPrompt: systemPrompt, userMessage: userMessage)
        } catch {
            print("⚠️ Gemini failed: \(error.localizedDescription). Switching to OpenRouter...")
            
            // Attempt 2: OpenRouter (Fallback)
            if !openRouterKey.isEmpty {
                do {
                    return try await performOpenRouterRequest(systemPrompt: systemPrompt, userMessage: userMessage)
                } catch {
                    print("❌ OpenRouter also failed: \(error.localizedDescription)")
                    throw AIError.allProvidersFailed
                }
            } else {
                print("🚫 No OpenRouter key provided. No fallback available.")
                throw error
            }
        }
    }
    
    // MARK: - Provider: Gemini
    
    private func performGeminiRequest(systemPrompt: String, userMessage: String) async throws -> String {
        let urlString = "\(geminiBaseURL)/\(geminiModel):generateContent?key=\(geminiKey)"
        guard let url = URL(string: urlString) else { throw AIError.invalidURL }
        
        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemPrompt]]],
            "contents": [["parts": [["text": userMessage]]]],
            "generationConfig": ["temperature": 0.7, "maxOutputTokens": 2048]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 20
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIError.providerError("Gemini")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let text = (json?["candidates"] as? [[String: Any]])?.first?["content"] as? [String: Any]
        let parts = text?["parts"] as? [[String: Any]]
        if let result = parts?.first?["text"] as? String {
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw AIError.parsingError
    }
    
    // MARK: - Provider: OpenRouter
    
    private func performOpenRouterRequest(systemPrompt: String, userMessage: String) async throws -> String {
        guard let url = URL(string: openRouterBaseURL) else { throw AIError.invalidURL }
        
        let body: [String: Any] = [
            "model": openRouterModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ],
            "temperature": 0.7
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openRouterKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://layman-ia.app", forHTTPHeaderField: "HTTP-Referer") // Required by OpenRouter
        request.setValue("Layman News", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 25
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown"
            print("⚠️ OpenRouter Error: \(msg)")
            throw AIError.providerError("OpenRouter")
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let content = choices?.first?["message"] as? [String: Any]
        if let result = content?["content"] as? String {
            return result.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw AIError.parsingError
    }
}

enum AIError: Error, LocalizedError {
    case invalidURL
    case parsingError
    case providerError(String)
    case allProvidersFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "AI URL Configuration Issue."
        case .parsingError: return "Failed to read AI response."
        case .providerError(let name): return "\(name) is currently unavailable."
        case .allProvidersFailed: return "All AI services reached their daily limit. Please try again later."
        }
    }
}
