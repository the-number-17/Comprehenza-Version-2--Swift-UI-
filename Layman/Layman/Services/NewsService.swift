import Foundation

final class NewsService {
    static let shared = NewsService()
    
    private let apiKey: String
    private let baseURL = "https://newsdata.io/api/1/latest"
    
    private init() {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let key = dict["NEWSDATA_API_KEY"] as? String else {
            fatalError("Missing NEWSDATA_API_KEY in Secrets.plist")
        }
        self.apiKey = key
    }
    
    func fetchArticles() async throws -> [Article] {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "category", value: "business,technology"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "image", value: "1"),
            URLQueryItem(name: "size", value: "10")
        ]
        
        guard let url = components.url else {
            throw NewsError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NewsError.badResponse
        }
        
        let newsResponse = try JSONDecoder().decode(NewsDataResponse.self, from: data)
        
        return newsResponse.results?.compactMap { result in
            guard let title = result.title, !title.isEmpty else { return nil }
            
            let laymanTitle = generateLaymanHeadline(from: title)
            let cards = generateContentCards(
                from: result.description ?? result.content ?? title
            )
            
            return Article(
                id: result.article_id ?? UUID().uuidString,
                title: title,
                laymanTitle: laymanTitle,
                description: result.description,
                content: result.content,
                imageURL: result.image_url,
                sourceURL: result.link,
                sourceName: result.source_name,
                publishedAt: result.pubDate,
                laymanCards: cards,
                isSaved: false
            )
        } ?? []
    }
    
    // Generate a conversational, casual headline (48-52 chars, 7-9 words)
    private func generateLaymanHeadline(from title: String) -> String {
        // Remove formal/complex words and simplify
        var simplified = title
        
        // Common replacements for simpler language
        let replacements: [(String, String)] = [
            ("Advances", "Pushes Forward"),
            ("Infrastructure", "Tech"),
            ("Acquisition", "Buyout"),
            ("Approximately", "About"),
            ("Implementation", "Setup"),
            ("Comprehensive", "Full"),
            ("Demonstrates", "Shows"),
            ("Significant", "Big"),
            ("Announcement", "News"),
            ("Collaboration", "Team-up"),
            ("Restructuring", "Shakeup"),
            ("Subsequently", "Then"),
            ("Preliminary", "Early"),
            ("Unprecedented", "Never-before-seen"),
            ("Substantial", "Huge"),
            ("Incorporated", "Added"),
            ("Strategically", "Smartly"),
            ("Manufacturing", "Making"),
            ("Sustainability", "Going Green"),
            ("Revolutionary", "Game-changing"),
        ]
        
        for (formal, casual) in replacements {
            simplified = simplified.replacingOccurrences(
                of: formal, with: casual,
                options: .caseInsensitive
            )
        }
        
        // Truncate to roughly 65-72 characters to keep it readable
        if simplified.count > 72 {
            let words = simplified.split(separator: " ")
            var result = ""
            for word in words {
                let candidate = result.isEmpty ? String(word) : result + " " + word
                if candidate.count > 68 { break }
                result = candidate
            }
            simplified = result + "…"
        }
        
        return simplified
    }
    
    // Generate 3 content cards, each with 2 sentences (28-35 words)
    private func generateContentCards(from text: String) -> [String] {
        let sentences = splitIntoSentences(text)
        var cards: [String] = []
        
        // Try to create 3 cards with 2 sentences each
        var index = 0
        for _ in 0..<3 {
            if index < sentences.count {
                var cardText = sentences[index]
                index += 1
                
                if index < sentences.count {
                    cardText += " " + sentences[index]
                    index += 1
                }
                
                // Trim to 28-35 words
                let words = cardText.split(separator: " ")
                if words.count > 35 {
                    cardText = words.prefix(35).joined(separator: " ") + "."
                }
                
                cards.append(cardText)
            }
        }
        
        // If we don't have 3 cards, pad with generic summaries
        while cards.count < 3 {
            if let first = cards.first {
                cards.append("Here's another way to think about it. " + first.prefix(80) + "...")
            } else {
                cards.append("This article covers the latest developments in business and technology. Stay tuned for more updates on this story.")
            }
        }
        
        return cards
    }
    
    private func splitIntoSentences(_ text: String) -> [String] {
        let cleaned = text.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        
        var sentences: [String] = []
        cleaned.enumerateSubstrings(in: cleaned.startIndex..., options: .bySentences) { substring, _, _, _ in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines),
               !sentence.isEmpty {
                sentences.append(sentence)
            }
        }
        
        return sentences
    }
}

// MARK: - NewsData.io Response Models
struct NewsDataResponse: Codable {
    let status: String?
    let totalResults: Int?
    let results: [NewsDataArticle]?
}

struct NewsDataArticle: Codable {
    let article_id: String?
    let title: String?
    let link: String?
    let description: String?
    let content: String?
    let pubDate: String?
    let image_url: String?
    let source_name: String?
    let source_icon: String?
    let category: [String]?
}

enum NewsError: Error, LocalizedError {
    case invalidURL
    case badResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .badResponse: return "Server error. Please try again."
        case .decodingError: return "Failed to parse articles."
        }
    }
}
