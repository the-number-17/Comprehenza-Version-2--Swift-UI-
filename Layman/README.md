# Layman — Business, Tech & Startups Made Simple

A SwiftUI iOS app that takes complex business, tech, and startup news and presents it in plain, everyday language — in layman's terms.

## Features

- **Simplified News**: Complex articles rewritten in simple, conversational language
- **Featured Carousel**: Horizontal swipeable cards with image overlays
- **Article Detail**: 3 swipeable content cards per article, each 2 sentences
- **Ask Layman AI Chat**: Context-aware chatbot that answers questions about articles in 1-2 simple sentences
- **Save & Bookmark**: Synced to Supabase backend
- **Authentication**: Supabase email/password auth with session persistence

## Tech Stack

- **SwiftUI** (iOS 17+)
- **Supabase** — Authentication + Database
- **NewsData.io** — News API
- **Google Gemini** — AI Chat (gemini-2.0-flash)

## Setup

### 1. API Keys
Create `Layman/Secrets.plist` with:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>YOUR_SUPABASE_URL</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>YOUR_SUPABASE_ANON_KEY</string>
    <key>NEWSDATA_API_KEY</key>
    <string>YOUR_NEWSDATA_API_KEY</string>
    <key>GEMINI_API_KEY</key>
    <string>YOUR_GEMINI_API_KEY</string>
</dict>
</plist>
```

### 2. Supabase Database
Run this SQL in your Supabase SQL Editor:
```sql
CREATE TABLE saved_articles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    article_id TEXT NOT NULL,
    title TEXT NOT NULL,
    layman_title TEXT NOT NULL,
    description TEXT,
    image_url TEXT,
    source_url TEXT,
    source_name TEXT,
    published_at TEXT,
    layman_cards TEXT[],
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE saved_articles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own articles" ON saved_articles
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own articles" ON saved_articles
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own articles" ON saved_articles
    FOR DELETE USING (auth.uid() = user_id);
```

### 3. Build & Run
Open `Layman.xcodeproj` in Xcode, select a simulator, and run.

## AI Tool Used
This project was built using **Antigravity** (AI coding assistant by Google DeepMind).

## Architecture
MVVM pattern with SwiftUI, using `@MainActor` ViewModels and `async/await` for all async operations.
