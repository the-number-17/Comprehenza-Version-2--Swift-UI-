import SwiftUI
import SafariServices

struct ArticleDetailView: View {
    let article: Article
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSimpleSummary = false
    @State private var showChat = false
    @State private var showSafari = false
    @State private var showShareSheet = false
    @State private var isSaved: Bool
    
    private var displayTitle: String {
        let title = article.laymanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? article.title : title
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
    
    init(article: Article) {
        self.article = article
        _isSaved = State(initialValue: article.isSaved)
    }
    
    var body: some View {
        ZStack {
            Color.laymanCream.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 1. Source and date
                    HStack(spacing: 8) {
                        if let source = cleanSourceName {
                            Text(source.uppercased())
                                .font(LaymanFont.small(11))
                                .foregroundColor(.white)
                                .tracking(0.5)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.laymanOrange)
                                .cornerRadius(6)
                        }
                        
                        if let date = article.publishedAt {
                            Text(formatDate(date))
                                .font(LaymanFont.caption(12))
                                .foregroundColor(.laymanGray)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, LaymanDimension.screenPadding)
                    .padding(.top, 16)
                    
                    // 2. Headline
                    Text(displayTitle)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.laymanDark)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, LaymanDimension.screenPadding)
                    
                    // 3. Photo Card
                    if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 240)
                                    .clipped()
                                    .cornerRadius(LaymanDimension.cornerRadius)
                            default:
                                imagePlaceholder
                            }
                        }
                        .padding(.horizontal, LaymanDimension.screenPadding)
                    }
                    
                    // 4. Simple Version Card (Interactive)
                    if !article.laymanCards.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.laymanOrange)
                                
                                Text("THE SIMPLE VERSION")
                                    .font(LaymanFont.small(11))
                                    .tracking(1.0)
                                    .foregroundColor(.laymanGray)
                                
                                Spacer()
                            }
                            .padding(.horizontal, LaymanDimension.screenPadding + 4)
                            
                            Button {
                                showSimpleSummary = true
                            } label: {
                                VStack(alignment: .leading, spacing: 14) {
                                    Text(article.laymanCards.first ?? "")
                                        .font(.system(size: 17, weight: .regular))
                                        .foregroundColor(.laymanDark)
                                        .lineSpacing(6)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true) // Ensure it shows fully
                                    
                                    HStack {
                                        Text("Tap for full summary")
                                            .font(LaymanFont.small(12))
                                            .foregroundColor(.laymanGray)
                                        Spacer()
                                        Image(systemName: "arrow.up.right.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.laymanOrange)
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.laymanCardBg)
                                .cornerRadius(LaymanDimension.cornerRadius)
                                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                                .padding(.horizontal, LaymanDimension.screenPadding)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // 5. Full News Section — Now in a matching Card orientation
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.laymanOrange)
                            
                            Text("FULL STORY")
                                .font(LaymanFont.small(11))
                                .tracking(1.0)
                                .foregroundColor(.laymanGray)
                            
                            Spacer()
                        }
                        .padding(.horizontal, LaymanDimension.screenPadding + 4)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            if articlesViewModel.isEnhancingWithAI && (article.expandedContent?.isEmpty ?? true) {
                                HStack(spacing: 12) {
                                    ProgressView().tint(.laymanOrange)
                                    Text("Expanding story with AI...").font(LaymanFont.small(12)).foregroundColor(.laymanGray)
                                }
                                .padding(.vertical, 8)
                            }
                            
                            let displayContent = article.expandedContent ?? article.content ?? article.description ?? ""
                            let cleanedContent = displayContent
                                .replacingOccurrences(of: "ONLY AVAILABLE IN PAID PLANS", with: "")
                                .replacingOccurrences(of: "[...]", with: "")
                            
                            if !cleanedContent.isEmpty {
                                Text(cleanedContent)
                                    .font(.system(size: 17))
                                    .foregroundColor(.laymanDark.opacity(0.9))
                                    .lineSpacing(7)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true) // No Truncation
                            } else {
                                Text("Building your story. Please check back in a moment or view the source link below.")
                                    .font(LaymanFont.body(15))
                                    .foregroundColor(.laymanGray)
                                    .italic()
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.laymanCardBg)
                        .cornerRadius(LaymanDimension.cornerRadius)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, LaymanDimension.screenPadding)
                    }
                    
                    Spacer().frame(height: 100)
                }
            }
            
            // Ask Layman button
            VStack {
                Spacer()
                Button { showChat = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(LinearGradient(colors: [.laymanPeach, .laymanOrange], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 36, height: 36)
                            Image(systemName: "bubble.left.fill").font(.system(size: 14)).foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ask Layman").font(LaymanFont.headline(16)).foregroundColor(.laymanDark)
                            Text("Get a simple explanation").font(LaymanFont.small(11)).foregroundColor(.laymanGray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(.laymanOrange)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 14).background(Color.laymanCardBg).cornerRadius(LaymanDimension.cornerRadius).shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)
                }
                .padding(.horizontal, LaymanDimension.screenPadding).padding(.bottom, 12)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { showSafari = true } label: { toolbarIcon("link") }
                Button { Task { isSaved.toggle(); await articlesViewModel.toggleSave(article) } } label: { toolbarIcon(isSaved ? "bookmark.fill" : "bookmark", color: isSaved ? .laymanOrange : .laymanDark) }
                Button { showShareSheet = true } label: { toolbarIcon("square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $showSimpleSummary) { SimpleSummarySheet(article: article) }
        .sheet(isPresented: $showChat) { ChatView(article: article, articlesViewModel: articlesViewModel) }
        .sheet(isPresented: $showSafari) { if let s = article.sourceURL, let u = URL(string: s) { SafariView(url: u).ignoresSafeArea() } }
        .sheet(isPresented: $showShareSheet) { if let s = article.sourceURL, let u = URL(string: s) { ShareSheet(items: [u]) } }
    }
    
    private func toolbarIcon(_ name: String, color: Color = .laymanDark) -> some View {
        Image(systemName: name).font(.system(size: 14, weight: .medium)).foregroundColor(color).frame(width: 34, height: 34).background(Color.laymanBeige.opacity(0.8)).clipShape(Circle())
    }
    
    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(colors: [Color.laymanBeige, Color.laymanPeach.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "newspaper.fill").font(.system(size: 40)).foregroundColor(.laymanPeach)
        }.frame(maxWidth: .infinity).frame(height: 240).cornerRadius(LaymanDimension.cornerRadius)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        let formats = ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ss'Z'", "yyyy-MM-dd"]
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                let d = DateFormatter()
                d.dateFormat = "MMM d, yyyy"
                return d.string(from: date)
            }
        }
        return ""
    }
}

// MARK: - Simple Summary Sheet
struct SimpleSummarySheet: View {
    let article: Article
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.laymanCream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Simple Summary").font(LaymanFont.logo(20)).foregroundColor(.laymanDark)
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 24)).foregroundColor(.laymanGray.opacity(0.5)) }
                }
                .padding(24)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(article.laymanTitle.isEmpty ? article.title : article.laymanTitle)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.laymanDark)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(article.laymanCards, id: \.self) { p in
                                Text(p)
                                    .font(.system(size: 17))
                                    .foregroundColor(.laymanDark)
                                    .lineSpacing(6)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer(minLength: 60) // Extra bottom breathing room
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct ContentCardView: View {
    let text: String
    let cardNumber: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text).font(.system(size: 16)).foregroundColor(.laymanDark).lineSpacing(5).lineLimit(7).multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding(LaymanDimension.cardPadding).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading).background(Color.laymanCardBg).cornerRadius(LaymanDimension.cornerRadius).shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2).padding(.horizontal, LaymanDimension.screenPadding)
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let s = SFSafariViewController(url: url)
        s.preferredControlTintColor = UIColor(Color.laymanOrange)
        return s
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
