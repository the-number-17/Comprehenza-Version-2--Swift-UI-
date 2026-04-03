import SwiftUI

struct FeaturedCarouselView: View {
    let articles: [Article]
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(spacing: 12) {
            TabView(selection: $currentIndex) {
                ForEach(Array(articles.enumerated()), id: \.element.id) { index, article in
                    NavigationLink(destination: ArticleDetailView(article: article).environmentObject(articlesViewModel)) {
                        FeaturedCardView(article: article)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: LaymanDimension.carouselHeight)
            
            // Custom page indicators — capsule style
            HStack(spacing: 6) {
                ForEach(0..<articles.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentIndex ? Color.laymanOrange : Color.laymanLightGray.opacity(0.5))
                        .frame(width: index == currentIndex ? 20 : 6, height: 6)
                        .animation(.easeInOut(duration: 0.25), value: currentIndex)
                }
            }
        }
    }
}

struct FeaturedCardView: View {
    let article: Article
    
    private var displayTitle: String {
        let title = article.laymanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            return article.title
        }
        return title
    }
    
    private var cleanSourceName: String? {
        guard let source = article.sourceName, !source.isEmpty else { return nil }
        var cleaned = source
        if cleaned.lowercased().hasPrefix("http") {
            if let url = URL(string: cleaned), let host = url.host {
                cleaned = host
            } else {
                cleaned = cleaned.replacingOccurrences(of: "https://", with: "", options: .caseInsensitive)
                    .replacingOccurrences(of: "http://", with: "", options: .caseInsensitive)
                if let i = cleaned.firstIndex(of: "/") { cleaned = String(cleaned[..<i]) }
            }
        }
        if cleaned.lowercased().hasPrefix("www.") { cleaned = String(cleaned.dropFirst(4)) }
        if cleaned.contains("."), let i = cleaned.firstIndex(of: ".") {
            let name = String(cleaned[..<i])
            cleaned = name.prefix(1).uppercased() + name.dropFirst()
        }
        return cleaned.count > 20 ? String(cleaned.prefix(18)) + "…" : cleaned
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // Article image
                if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        case .failure:
                            placeholderImage(size: geo.size)
                        case .empty:
                            ZStack {
                                Color.laymanBeige
                                ProgressView()
                                    .tint(.laymanOrange)
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                        @unknown default:
                            placeholderImage(size: geo.size)
                        }
                    }
                } else {
                    placeholderImage(size: geo.size)
                }
                
                // Gradient overlay for text readability
                LinearGradient(
                    colors: [.clear, .black.opacity(0.15), .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Headline — pinned to bottom, properly constrained
                VStack(alignment: .leading, spacing: 8) {
                    if let source = cleanSourceName {
                        Text(source.uppercased())
                            .font(LaymanFont.small(10))
                            .foregroundColor(.white.opacity(0.9))
                            .tracking(0.5)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.laymanOrange.opacity(0.85))
                            .cornerRadius(6)
                    }
                    
                    Text(displayTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                }
                .padding(16)
                .frame(width: geo.size.width, alignment: .leading)
            }
            .cornerRadius(LaymanDimension.cornerRadius)
        }
        .padding(.horizontal, LaymanDimension.screenPadding)
    }
    
    private func placeholderImage(size: CGSize) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color.laymanPeach.opacity(0.3), Color.laymanBeige],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "newspaper.fill")
                .font(.system(size: 40))
                .foregroundColor(.laymanPeach)
        }
        .frame(width: size.width, height: size.height)
    }
}

#Preview {
    FeaturedCarouselView(articles: [])
        .environmentObject(ArticlesViewModel())
}
