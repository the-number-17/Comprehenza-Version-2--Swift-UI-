import SwiftUI

struct ArticleRowView: View {
    let article: Article
    
    private var displayTitle: String {
        let title = article.laymanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            return article.title
        }
        return title
    }
    
    /// Cleans source name — if it's a URL, extract the domain; if it's too long, truncate
    private var cleanSourceName: String? {
        guard let source = article.sourceName, !source.isEmpty else { return nil }
        
        // If source looks like a URL, extract domain
        var cleaned = source
        if cleaned.lowercased().hasPrefix("http://") || cleaned.lowercased().hasPrefix("https://") {
            if let url = URL(string: cleaned), let host = url.host {
                cleaned = host
            } else {
                // Manual cleanup
                cleaned = cleaned
                    .replacingOccurrences(of: "https://", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "http://", with: "", options: .caseInsensitive)
                if let slashIndex = cleaned.firstIndex(of: "/") {
                    cleaned = String(cleaned[cleaned.startIndex..<slashIndex])
                }
            }
        }
        
        // Remove www. prefix
        if cleaned.lowercased().hasPrefix("www.") {
            cleaned = String(cleaned.dropFirst(4))
        }
        
        // Capitalize nicely if it's a domain
        if cleaned.contains(".") {
            // It's a domain like "ksnblocal4.com" — just show the name part
            if let dotIndex = cleaned.firstIndex(of: ".") {
                let name = String(cleaned[cleaned.startIndex..<dotIndex])
                cleaned = name.prefix(1).uppercased() + name.dropFirst()
            }
        }
        
        // Truncate if still too long
        return cleaned // No truncation as per user request
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Text content — takes priority
            VStack(alignment: .leading, spacing: 8) {
                Text(displayTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.laymanDark)
                    .lineLimit(nil) // Zero truncation
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 6) {
                    if let source = cleanSourceName {
                        Text(source)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.laymanOrange)
                            .lineLimit(nil)
                    }
                    
                    if cleanSourceName != nil && article.publishedAt != nil {
                        Circle()
                            .fill(Color.laymanLightGray)
                            .frame(width: 3, height: 3)
                    }
                    
                    if let date = article.publishedAt {
                        Text(formatDate(date))
                            .font(LaymanFont.caption(12))
                            .foregroundColor(.laymanGray)
                            .lineLimit(nil)
                    }
                    
                    Spacer(minLength: 0)
                    
                    if article.isSaved {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.laymanOrange)
                    }
                }
            }
            .layoutPriority(1)
            
            // Thumbnail — fixed size
            if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipped()
                    case .failure:
                        thumbnailPlaceholder
                    case .empty:
                        ZStack {
                            Color.laymanBeige
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.laymanOrange)
                        }
                        .frame(width: 80, height: 80)
                    @unknown default:
                        thumbnailPlaceholder
                    }
                }
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            } else {
                thumbnailPlaceholder
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.laymanCardBg)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
    
    private var thumbnailPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.laymanBeige, Color.laymanPeach.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "photo")
                .foregroundColor(.laymanPeach)
                .font(.system(size: 20))
        }
        .frame(width: 80, height: 80)
        .cornerRadius(12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd"
        ]
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                let relative = RelativeDateTimeFormatter()
                relative.unitsStyle = .abbreviated
                return relative.localizedString(for: date, relativeTo: Date())
            }
        }
        
        return ""
    }
}

#Preview {
    VStack(spacing: 12) {
        ArticleRowView(article: Article(
            id: "1", title: "Test headline that is quite long to see how it wraps across lines",
            laymanTitle: "This AI Startup Just Raised $40M From Big Investors",
            description: nil, content: nil, imageURL: nil,
            sourceURL: nil, sourceName: "Https://www.ksnblocal4.com",
            publishedAt: "2024-01-15 10:30:00",
            laymanCards: [], isSaved: false
        ))
        
        ArticleRowView(article: Article(
            id: "2", title: "Short title",
            laymanTitle: "",
            description: nil, content: nil, imageURL: nil,
            sourceURL: nil, sourceName: "TechCrunch",
            publishedAt: "2024-01-15 10:30:00",
            laymanCards: [], isSaved: true
        ))
    }
    .padding()
}
