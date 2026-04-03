# Layman — AI Context File

## Overview
Layman is a SwiftUI iOS app that simplifies business, tech, and startup news into everyday language.

## Architecture
- **Pattern**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI (iOS 17+)
- **Backend**: Supabase (auth + saved articles)
- **News API**: NewsData.io
- **AI Chat**: Google Gemini API (gemini-2.0-flash)

## Design System
- **Colors**: Warm peach (#F4A574), orange accent (#E8734A), cream cards (#FFF5EB), dark text (#2D1B0E)
- **Corners**: 20pt radius on cards
- **Typography**: System fonts — titles bold, body regular
- **Headline Rules**: 48-52 characters, 7-9 words, conversational casual tone

## Key Conventions
- All API keys stored in `Secrets.plist` (gitignored)
- Headlines must be rewritten in layman's terms (simple, casual)
- Content cards: exactly 3 per article, 2 sentences each, 28-35 words
- Chat responses: 1-2 sentences max, simple everyday language
- Use `@MainActor` for ViewModels
- Use `async/await` for all network calls

## File Structure
```
Layman/
├── LaymanApp.swift          # App entry point
├── Design/Theme.swift       # Color palette, typography, gradients
├── Models/                  # Article, ChatMessage
├── Services/                # SupabaseManager, NewsService, GeminiService
├── ViewModels/              # AuthVM, ArticlesVM, SavedArticlesVM, ChatVM
└── Views/
    ├── Auth/                # WelcomeView, AuthView
    ├── Home/                # HomeView, FeaturedCarousel, ArticleRow
    ├── Detail/              # ArticleDetailView
    ├── Saved/               # SavedView
    ├── Profile/             # ProfileView
    └── Chat/                # ChatView
```
