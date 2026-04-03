import SwiftUI

struct ChatView: View {
    let article: Article
    @EnvironmentObject var articlesViewModel: ArticlesViewModel
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    @Namespace private var bottomAnchor
    
    init(article: Article, articlesViewModel: ArticlesViewModel) {
        self.article = article
        _viewModel = StateObject(wrappedValue: ChatViewModel(article: article, articlesViewModel: articlesViewModel))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.laymanCream.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Article headline bar
                    articleHeader
                    
                    Divider().opacity(0.3)
                    
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubbleView(message: message)
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                                
                                // Suggestion chips
                                if !viewModel.suggestions.isEmpty {
                                    SuggestionChipsView(
                                        suggestions: viewModel.suggestions,
                                        onSelect: { suggestion in
                                            Task {
                                                await viewModel.sendSuggestion(suggestion)
                                            }
                                        }
                                    )
                                    .transition(.opacity)
                                }
                                
                                // Loading indicator
                                if viewModel.isLoading {
                                    HStack {
                                        TypingIndicatorView()
                                        Spacer()
                                    }
                                    .padding(.horizontal, LaymanDimension.screenPadding)
                                }
                                
                                // Invisible anchor for auto-scroll
                                Color.clear
                                    .frame(height: 1)
                                    .id("bottom")
                            }
                            .padding(.vertical, 16)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    
                    // Input bar
                    inputBar
                }
            }
            .navigationTitle("Ask Layman")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.laymanGray)
                            .frame(width: 30, height: 30)
                            .background(Color.laymanBeige)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
    
    // MARK: - Article Header
    private var articleHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(article.laymanTitle.isEmpty ? article.title : article.laymanTitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.laymanDark)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipped()
                                .cornerRadius(8)
                        default:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.laymanBeige)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                
                if let source = article.sourceName {
                    Text(source)
                        .font(LaymanFont.caption(12))
                        .foregroundColor(.laymanOrange)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.laymanOrange.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(Color.laymanWhite)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Input Bar
    private var inputBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Type your question...", text: $viewModel.inputText)
                    .font(LaymanFont.body(15))
                    .focused($isInputFocused)
                    .onSubmit {
                        Task { await viewModel.sendMessage() }
                    }
                
                // Microphone button (placeholder)
                Button {
                    // Non-functional placeholder
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.laymanGray)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.laymanBeige.opacity(0.5))
            .cornerRadius(24)
            
            // Send button
            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundColor(viewModel.inputText.isEmpty ? .laymanLightGray : .laymanOrange)
            }
            .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, LaymanDimension.screenPadding)
        .padding(.vertical, 10)
        .background(Color.laymanWhite)
    }
}

// MARK: - Message Bubble
struct MessageBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if !message.isUser {
                // Bot icon
                ZStack {
                    Circle()
                        .fill(Color.laymanOrange)
                        .frame(width: 30, height: 30)
                    
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            Text(message.content)
                .font(LaymanFont.body(15))
                .foregroundColor(message.isUser ? .white : .laymanDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isUser ? Color.laymanOrange : Color.laymanBotBubble)
                .cornerRadius(18)
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, LaymanDimension.screenPadding)
    }
}

// MARK: - Suggestion Chips
struct SuggestionChipsView: View {
    let suggestions: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question Suggestions")
                .font(LaymanFont.small(11))
                .foregroundColor(.laymanGray)
                .padding(.horizontal, LaymanDimension.screenPadding)
            
            VStack(spacing: 8) {
                ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                    Button {
                        onSelect(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(LaymanFont.caption(14))
                            .foregroundColor(.laymanOrange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.laymanOrange.opacity(0.4), lineWidth: 1)
                                    .fill(Color.laymanOrange.opacity(0.05))
                            )
                    }
                }
            }
            .padding(.horizontal, LaymanDimension.screenPadding)
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicatorView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.laymanOrange)
                    .frame(width: 30, height: 30)
                
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.laymanGray)
                        .frame(width: 7, height: 7)
                        .offset(y: animationPhase == i ? -4 : 0)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.laymanBotBubble)
            .cornerRadius(18)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                animationPhase = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    animationPhase = 1
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    animationPhase = 2
                }
            }
        }
    }
}

#Preview {
    ChatView(article: Article(
        id: "1",
        title: "Test Article",
        laymanTitle: "Test Article Title",
        description: "Test description",
        content: nil,
        imageURL: nil,
        sourceURL: nil,
        sourceName: "TechCrunch",
        publishedAt: nil,
        laymanCards: ["Card 1", "Card 2", "Card 3"],
        isSaved: false
    ), articlesViewModel: ArticlesViewModel())
}
