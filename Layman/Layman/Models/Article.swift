import Foundation

struct Article: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    var laymanTitle: String
    let description: String?
    let content: String?
    var expandedContent: String? // AI-reconstructed full story
    let imageURL: String?
    let sourceURL: String?
    let sourceName: String?
    let publishedAt: String?
    var laymanCards: [String]
    var isSaved: Bool
    
    enum CodingKeys: String, CodingKey {
        case id = "article_id"
        case title
        case laymanTitle = "layman_title"
        case description
        case content
        case expandedContent = "expanded_content"
        case imageURL = "image_url"
        case sourceURL = "source_url"
        case sourceName = "source_name"
        case publishedAt = "published_at"
        case laymanCards = "layman_cards"
        case isSaved
    }
    
    init(id: String, title: String, laymanTitle: String, description: String?,
         content: String?, expandedContent: String? = nil, imageURL: String?, sourceURL: String?,
         sourceName: String?, publishedAt: String?, laymanCards: [String], isSaved: Bool = false) {
        self.id = id
        self.title = title
        self.laymanTitle = laymanTitle
        self.description = description
        self.content = content
        self.expandedContent = expandedContent
        self.imageURL = imageURL
        self.sourceURL = sourceURL
        self.sourceName = sourceName
        self.publishedAt = publishedAt
        self.laymanCards = laymanCards
        self.isSaved = isSaved
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        laymanTitle = try container.decodeIfPresent(String.self, forKey: .laymanTitle) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        expandedContent = try container.decodeIfPresent(String.self, forKey: .expandedContent)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        sourceURL = try container.decodeIfPresent(String.self, forKey: .sourceURL)
        sourceName = try container.decodeIfPresent(String.self, forKey: .sourceName)
        publishedAt = try container.decodeIfPresent(String.self, forKey: .publishedAt)
        laymanCards = try container.decodeIfPresent([String].self, forKey: .laymanCards) ?? []
        isSaved = try container.decodeIfPresent(Bool.self, forKey: .isSaved) ?? false
    }
    
    static func == (lhs: Article, rhs: Article) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Supabase SavedArticle (for DB operations)
struct SavedArticleRow: Codable {
    let id: String?
    let user_id: String?
    let article_id: String
    let title: String
    let layman_title: String
    let description: String?
    let image_url: String?
    let source_url: String?
    let source_name: String?
    let published_at: String?
    let layman_cards: [String]?
    
    init(from article: Article, userId: String) {
        self.id = nil
        self.user_id = userId
        self.article_id = article.id
        self.title = article.title
        self.layman_title = article.laymanTitle
        self.description = article.description
        self.image_url = article.imageURL
        self.source_url = article.sourceURL
        self.source_name = article.sourceName
        self.published_at = article.publishedAt
        self.layman_cards = article.laymanCards
    }
    
    func toArticle() -> Article {
        Article(
            id: article_id,
            title: title,
            laymanTitle: layman_title,
            description: description,
            content: nil,
            imageURL: image_url,
            sourceURL: source_url,
            sourceName: source_name,
            publishedAt: published_at,
            laymanCards: layman_cards ?? [],
            isSaved: true
        )
    }
}
