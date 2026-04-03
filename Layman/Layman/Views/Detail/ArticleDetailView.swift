import SwiftUI
import SafariServices

struct ArticleDetailView: View {
    let article: Article
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showChat = false
    @State private var showSafari = false
    @State private var showShareSheet = false
    @State private var isSaved: Bool
    @State private var currentCardIndex = 0
    
    private var displayTitle: String {
        let title = article.laymanTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? article.title : title
    }
    
    init(article: Article) {
        self.article = article
        _isSaved = State(initialValue: article.isSaved)
    }
    
    var body: some View {
        ZStack {
            Color.laymanCream.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // 1. HEADLINE
                        Text(displayTitle)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.laymanDark)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        // 2. IMAGE — always same size container
                        ZStack {
                            // Placeholder always present
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.laymanBeige)
                                .frame(height: 220)
                                .overlay(
                                    Image(systemName: "newspaper.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.laymanPeach)
                                )
                            
                            // Real image loads on top
                            if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    if case .success(let image) = phase {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 220)
                                            .clipped()
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        
                        // 3. CONTENT CARDS — always same size frame
                        VStack(spacing: 10) {
                            if article.laymanCards.isEmpty {
                                // Skeleton fills the same space
                                VStack(alignment: .leading, spacing: 12) {
                                    SkeletonLine()
                                    SkeletonLine()
                                    SkeletonLine(width: 220)
                                    SkeletonLine()
                                    SkeletonLine(width: 180)
                                    SkeletonLine()
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 220)
                                .background(Color.laymanCardBg)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                                .padding(.horizontal, 20)
                            } else {
                                TabView(selection: $currentCardIndex) {
                                    ForEach(Array(article.laymanCards.enumerated()), id: \.offset) { index, card in
                                        ScrollView(.vertical, showsIndicators: false) {
                                            Text(card)
                                                .font(.system(size: 18))
                                                .foregroundColor(.laymanDark)
                                                .lineSpacing(7)
                                                .multilineTextAlignment(.leading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding(20)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 220)
                                        .background(Color.laymanCardBg)
                                        .cornerRadius(20)
                                        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                                        .padding(.horizontal, 20)
                                        .tag(index)
                                    }
                                }
                                .tabViewStyle(.page(indexDisplayMode: .never))
                                .frame(height: 240)
                            }
                            
                            // Page dots — always visible
                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { i in
                                    Capsule()
                                        .fill(i == currentCardIndex && !article.laymanCards.isEmpty ? Color.laymanOrange : Color.laymanLightGray.opacity(0.4))
                                        .frame(width: i == currentCardIndex && !article.laymanCards.isEmpty ? 20 : 7, height: 7)
                                        .animation(.easeInOut(duration: 0.25), value: currentCardIndex)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                
                // 4. ASK LAYMAN — solid orange button
                Button { showChat = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Ask Layman")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [Color.laymanOrange, Color.laymanOrange.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // Back button — left
            ToolbarItem(placement: .navigationBarLeading) { BackButton() }
            // Link, Bookmark, Share — right (in that order)
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button { showSafari = true } label: { toolbarIcon("link") }
                Button {
                    Task { isSaved.toggle(); await articlesViewModel.toggleSave(article) }
                } label: {
                    toolbarIcon(isSaved ? "bookmark.fill" : "bookmark", color: isSaved ? .laymanOrange : .laymanDark)
                }
                Button { showShareSheet = true } label: { toolbarIcon("square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $showChat) {
            ChatView(article: article, articlesViewModel: articlesViewModel)
        }
        .sheet(isPresented: $showSafari) {
            // In-app popup — does NOT navigate away from the app
            if let s = article.sourceURL, let u = URL(string: s) {
                SafariView(url: u).ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let s = article.sourceURL, let u = URL(string: s) {
                ShareSheet(items: [u])
            }
        }
        .onAppear {
            Task {
                await articlesViewModel.enrichArticleWithAI(article)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func toolbarIcon(_ name: String, color: Color = .laymanDark) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(color)
            .frame(width: 34, height: 34)
            .background(Color.laymanBeige.opacity(0.8))
            .clipShape(Circle())
    }
    
    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(colors: [Color.laymanBeige, Color.laymanPeach.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "newspaper.fill")
                .font(.system(size: 40))
                .foregroundColor(.laymanPeach)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .cornerRadius(16)
    }
}

// MARK: - Utility Views

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
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
