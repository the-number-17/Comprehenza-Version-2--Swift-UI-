import SwiftUI

// MARK: - ReadBuddy View (Dictionary Chatbot)
struct ReadBuddyView: View {
    @State private var inputText   = ""
    @State private var messages:  [BuddyMessage] = []
    @State private var isLoading   = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F8F0FF").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 14) {
                                // Welcome message
                                if messages.isEmpty {
                                    welcomeCard
                                }

                                ForEach(messages) { msg in
                                    BuddyMessageBubble(message: msg)
                                        .id(msg.id)
                                }

                                if isLoading {
                                    HStack(spacing: 6) {
                                        ForEach(0..<3) { i in
                                            Circle()
                                                .fill(Color.brandAccent)
                                                .frame(width: 8, height: 8)
                                                .animation(
                                                    .easeInOut(duration: 0.5)
                                                    .repeatForever()
                                                    .delay(Double(i) * 0.15),
                                                    value: isLoading
                                                )
                                                .offset(y: isLoading ? -4 : 0)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .id("loading")
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        }
                        .onChange(of: messages.count) { _ in
                            withAnimation {
                                proxy.scrollTo(messages.last?.id ?? "loading", anchor: .bottom)
                            }
                        }
                    }

                    // Input bar
                    inputBar
                }
            }
            .navigationTitle("ReadBuddy")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Welcome Card
    var welcomeCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 64, height: 64)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundColor(.white)
            }
            Text("Hi! I'm ReadBuddy")
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Text("Type any word and I'll give you its meaning, usage, example, and how to pronounce it!")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Quick examples
            VStack(alignment: .leading, spacing: 8) {
                Text("Try looking up:")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    ForEach(["ephemeral", "luminous", "cascade"], id: \.self) { word in
                        Button(word) {
                            inputText = word
                            lookupWord()
                        }
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.brandAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.brandAccent.opacity(0.12))
                        .cornerRadius(20)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .cardStyle()
    }

    // MARK: Input Bar
    var inputBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Type a word...", text: $inputText)
                    .font(.system(size: 16, design: .rounded))
                    .focused($isFocused)
                    .onSubmit { lookupWord() }
                    .submitLabel(.search)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8)
            )

            Button {
                lookupWord()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(inputText.isEmpty ? .secondary : .brandAccent)
            }
            .disabled(inputText.isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "F8F0FF").ignoresSafeArea())
    }

    private func lookupWord() {
        let word = inputText.trimmingCharacters(in: .whitespaces)
        guard !word.isEmpty else { return }
        isFocused = false

        // Add user message
        let userMsg = BuddyMessage(isUser: true, word: word, content: word)
        messages.append(userMsg)
        inputText = ""
        isLoading = true

        // Simulate lookup delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            let definition = WordDictionary.lookup(word)
            let buddyMsg = BuddyMessage(isUser: false, word: word, content: "", definition: definition)
            messages.append(buddyMsg)
        }
    }
}

// MARK: - Message Model
struct BuddyMessage: Identifiable {
    let id = UUID().uuidString
    let isUser: Bool
    let word: String
    let content: String
    var definition: WordDefinition? = nil
}

struct WordDefinition {
    let word: String
    let pronunciation: String
    let meaning: String
    let usage: String
    let example: String
    let synonyms: [String]
}

// MARK: - Message Bubble
struct BuddyMessageBubble: View {
    let message: BuddyMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if message.isUser {
                Spacer()
                Text(message.word.capitalized)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.brandAccent))
            } else {
                // Buddy avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(hex: "6C5CE7").opacity(0.2), Color(hex: "A29BFE").opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 36, height: 36)
                        .overlay(Circle().stroke(Color(hex: "A29BFE").opacity(0.3), lineWidth: 1))
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "6C5CE7"))
                }

                if let def = message.definition {
                    definitionCard(def)
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    func definitionCard(_ def: WordDefinition) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Word + pronunciation
            VStack(alignment: .leading, spacing: 4) {
                Text(def.word.capitalized)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.brandAccent)
                Text(def.pronunciation)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Divider()

            // Sections
            definitionRow(icon: "text.alignleft", label: "Meaning", value: def.meaning, color: .brandPrimary)
            definitionRow(icon: "pencil", label: "Usage", value: def.usage, color: .brandTeal)
            definitionRow(icon: "quote.closing", label: "Example", value: "\u{201C}\(def.example)\u{201D}", color: .brandOrange)

            // Synonyms
            if !def.synonyms.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Synonyms", systemImage: "equal.circle")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    FlowLayout(spacing: 6) {
                        ForEach(def.synonyms, id: \.self) { syn in
                            Text(syn)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.brandPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.brandPrimary.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.07), radius: 8)
    }

    func definitionRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Word Dictionary (Local)
struct WordDictionary {
    static let entries: [String: WordDefinition] = [
        "ephemeral": WordDefinition(
            word: "ephemeral", pronunciation: "/ɪˈfem.ər.əl/",
            meaning: "Lasting for only a very short time.",
            usage: "Used to describe things that are brief or fleeting.",
            example: "The morning dew is ephemeral, vanishing by sunrise.",
            synonyms: ["transient", "fleeting", "momentary", "brief"]
        ),
        "luminous": WordDefinition(
            word: "luminous", pronunciation: "/ˈluː.mɪ.nəs/",
            meaning: "Giving off or reflecting bright light; shining.",
            usage: "Describes something glowing or full of light.",
            example: "The luminous stars lit up the night sky.",
            synonyms: ["glowing", "radiant", "bright", "brilliant"]
        ),
        "cascade": WordDefinition(
            word: "cascade", pronunciation: "/kæˈskeɪd/",
            meaning: "A small waterfall; a series of things following in rapid succession.",
            usage: "Used for waterfalls or a chain of events.",
            example: "A cascade of water fell over the rocky cliff.",
            synonyms: ["waterfall", "torrent", "series", "flood"]
        ),
        "resilient": WordDefinition(
            word: "resilient", pronunciation: "/rɪˈzɪl.i.ənt/",
            meaning: "Able to recover quickly from difficulty or setbacks.",
            usage: "Describes a person or thing that bounces back easily.",
            example: "She was resilient enough to keep going after failure.",
            synonyms: ["tough", "hardy", "flexible", "strong"]
        ),
        "tranquil": WordDefinition(
            word: "tranquil", pronunciation: "/ˈtræŋ.kwɪl/",
            meaning: "Free from disturbance; calm and peaceful.",
            usage: "Describes a peaceful, undisturbed environment.",
            example: "The lake was tranquil at dawn, not a ripple in sight.",
            synonyms: ["calm", "serene", "peaceful", "quiet"]
        ),
        "abundant": WordDefinition(
            word: "abundant", pronunciation: "/əˈbʌn.dənt/",
            meaning: "Existing or available in large quantities; plentiful.",
            usage: "Describes resources or things in great supply.",
            example: "The forest had abundant wildlife and vegetation.",
            synonyms: ["plentiful", "ample", "copious", "rich"]
        ),
        "meticulous": WordDefinition(
            word: "meticulous", pronunciation: "/mɪˈtɪk.jʊ.ləs/",
            meaning: "Showing great attention to detail; very careful and precise.",
            usage: "Used to describe careful, thorough work or people.",
            example: "The scientist was meticulous in recording every observation.",
            synonyms: ["careful", "thorough", "precise", "diligent"]
        ),
        "eloquent": WordDefinition(
            word: "eloquent", pronunciation: "/ˈel.ə.kwənt/",
            meaning: "Fluent or persuasive in speaking or writing.",
            usage: "Describes a speaker or writer who expresses ideas clearly.",
            example: "She gave an eloquent speech that moved the audience.",
            synonyms: ["articulate", "fluent", "persuasive", "expressive"]
        )
    ]

    static func lookup(_ word: String) -> WordDefinition {
        let key = word.lowercased()
        if let def = entries[key] { return def }

        // Generic fallback
        return WordDefinition(
            word: word,
            pronunciation: "/\(word.lowercased())/",
            meaning: "A word in the English language. Check a dictionary for its precise meaning.",
            usage: "This word can be used in various contexts depending on the sentence.",
            example: "She used the word '\(word.lowercased())' correctly in her essay.",
            synonyms: []
        )
    }
}
