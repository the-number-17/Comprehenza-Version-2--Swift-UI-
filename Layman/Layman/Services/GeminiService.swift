import Foundation

final class GeminiService {
    static let shared = GeminiService()
    
    private let apiKey: String
    private let primaryModel = "gemini-2.0-flash-lite"
    private let fallbackModel = "gemini-2.0-flash-lite"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    
    // Rate limiting
    private var lastRequestTime: Date = .distantPast
    private let minRequestInterval: TimeInterval = 2.0 // seconds between requests
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["GEMINI_API_KEY"] as? String else {
            fatalError("Missing GEMINI_API_KEY in Secrets.plist")
        }
        self.apiKey = key
    }
    
    // MARK: - Chat Response
    func sendMessage(_ userMessage: String, articleContext: String) async throws -> String {
        let context = articleContext.isEmpty ? "General news article" : articleContext
        
        let systemPrompt = """
        You are Layman, a friendly and simple assistant. Your job is to help people understand news articles in plain, everyday language.
        
        Rules:
        - Answer in 2-3 SHORT sentences maximum
        - Use simple, everyday words — like explaining to a friend
        - No jargon, no technical terms
        - Be friendly and conversational
        - If you don't know something, say so simply
        
        Article context:
        \(context)
        """
        
        return try await makeRequest(
            systemPrompt: systemPrompt,
            userMessage: userMessage
        )
    }
    
    // MARK: - Generate Question Suggestions
    func generateSuggestions(for articleTitle: String, articleContent: String) async throws -> [String] {
        let content = articleContent.isEmpty ? articleTitle : articleContent
        
        let prompt = """
        Based on this news article, generate exactly 3 simple questions a reader might ask.
        
        Article title: \(articleTitle)
        Article content: \(content)
        
        Rules:
        - Each question should be short (under 8 words)
        - Use simple everyday language
        - Questions should be about key facts in the article
        - Return ONLY the 3 questions, one per line, no numbering or bullets
        """
        
        let response = try await makeRequest(
            systemPrompt: "You generate simple questions about news articles. Return ONLY the questions, one per line.",
            userMessage: prompt
        )
        
        let questions = response
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
        
        return Array(questions)
    }
    
    // MARK: - Simplify Headlines (for layman-izing)
    func simplifyHeadline(_ headline: String) async throws -> String {
        let prompt = """
        Rewrite this news headline in simple, casual language. Make it sound like you're telling a friend.
        Do not truncate or shorten the headline in a way that loses its core meaning. 
        Ensure it is a complete, well-formed sentence. NO dots (...) at the end.
        
        Original: \(headline)
        
        Return ONLY the rewritten headline, nothing else.
        """
        
        let response = try await makeRequest(
            systemPrompt: "You rewrite headlines in simple casual language. Never truncate with dots.",
            userMessage: prompt
        )
        
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Expand Full Story (for truncated News API content)
    func expandFullStory(title: String, description: String, partialContent: String?) async throws -> String {
        let content = partialContent ?? "Details available in the source link."
        
        // Don't waste tokens on "Paid Plans" messages in the prompt
        let cleanedContent = content
            .replacingOccurrences(of: "ONLY AVAILABLE IN PAID PLANS", with: "")
            .replacingOccurrences(of: "[...]", with: "")
        
        let prompt = """
        You are a seasoned journalist for Layman News. Taking the following headline and summary, write a COMPREHENSIVE and detailed "Full Story" that is easy to read. 
        
        Headline: \(title)
        Summary: \(description)
        Partial Context: \(cleanedContent)
        
        Rules:
        - Write at least 300-400 words.
        - Don't just summarize; provide a detailed narrative.
        - Use simple, everyday language as per your 'Layman' persona.
        - NO markup, NO bolding, just plain text paragraphs.
        - Ensure every sentence is complete. NEVER use dots (...) for truncation.
        - Return ONLY the full story text.
        """
        
        let response = try await makeRequest(
            systemPrompt: "You are a professional news writer. Never use dots to truncate sentences.",
            userMessage: prompt
        )
        
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Generate Content Cards
    func generateContentCards(for articleContent: String) async throws -> [String] {
        let prompt = """
        Summarize this article into exactly 3 short paragraphs.
        
        Rules for EACH paragraph:
        - Use 2-3 complete sentences.
        - Do not truncate the thought. 
        - Use simple, everyday language — like explaining to a friend
        - Each paragraph MUST end with a proper period (.), never with dots (...).
        - Each paragraph covers a different aspect of the story.
        
        Article: \(articleContent)
        
        Return ONLY the 3 paragraphs, separated by blank lines. No numbering.
        """
        
        let response = try await makeRequest(
            systemPrompt: "You summarize news in simple everyday language. Never truncate with dots.",
            userMessage: prompt
        )
        
        let cards = response
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
        
        var result = Array(cards)
        
        while result.count < 3 {
            result.append("This story is still developing. Check back later for more details about what's happening and what it means for everyone.")
        }
        
        return result
    }
    
    // MARK: - API Request (with throttling + retry)
    private func makeRequest(systemPrompt: String, userMessage: String) async throws -> String {
        // Throttle requests to avoid rate limits
        await throttle()
        
        // Try primary model
        do {
            return try await performRequest(model: primaryModel, systemPrompt: systemPrompt, userMessage: userMessage)
        } catch let error as GeminiError where error == .rateLimited {
            // Wait and retry once on rate limit
            print("⏳ Rate limited. Waiting 5 seconds before retry...")
            try await Task.sleep(nanoseconds: 5_000_000_000)
            return try await performRequest(model: primaryModel, systemPrompt: systemPrompt, userMessage: userMessage)
        } catch {
            print("⚠️ Gemini primary model failed: \(error)")
            throw error
        }
    }
    
    private func throttle() async {
        let elapsed = Date().timeIntervalSince(lastRequestTime)
        if elapsed < minRequestInterval {
            let waitTime = minRequestInterval - elapsed
            try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
        }
        lastRequestTime = Date()
    }
    
    private func performRequest(model: String, systemPrompt: String, userMessage: String) async throws -> String {
        let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [
                [
                    "parts": [["text": userMessage]]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 1024
            ]
        ]
        
        // Log request body (omitting API key) for debugging if needed
        // print("🤖 Gemini Request to \(model): \(userMessage.prefix(100))...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.badResponse
        }
        
        if httpResponse.statusCode == 429 {
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            print("⏳ Gemini Rate Limited (429): \(responseBody.prefix(200))")
            throw GeminiError.rateLimited
        }
        
        if httpResponse.statusCode != 200 {
            let responseBody = String(data: data, encoding: .utf8) ?? "No body"
            print("❌ Gemini API Error [\(httpResponse.statusCode)]: \(responseBody.prefix(300))")
            throw GeminiError.badResponse
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            let responseBody = String(data: data, encoding: .utf8) ?? "No body"
            print("❌ Gemini Parse Error. Response: \(responseBody.prefix(300))")
            throw GeminiError.parsingError
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum GeminiError: Error, LocalizedError, Equatable {
    case invalidURL
    case badResponse
    case parsingError
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .badResponse: return "AI service unavailable. Try again."
        case .parsingError: return "Couldn't understand the AI response."
        case .rateLimited: return "Your daily AI limit has been reached. Please try again soon."
        }
    }
}
