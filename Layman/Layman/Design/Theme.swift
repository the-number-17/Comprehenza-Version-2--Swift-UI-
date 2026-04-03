import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary warm palette
    static let laymanPeach = Color(red: 244/255, green: 165/255, blue: 116/255)       // #F4A574
    static let laymanOrange = Color(red: 232/255, green: 115/255, blue: 74/255)        // #E8734A
    static let laymanDeepOrange = Color(red: 200/255, green: 80/255, blue: 40/255)     // #C85028
    static let laymanCream = Color(red: 255/255, green: 245/255, blue: 235/255)        // #FFF5EB
    static let laymanBeige = Color(red: 250/255, green: 235/255, blue: 220/255)        // #FAEBDC
    static let laymanDark = Color(red: 45/255, green: 27/255, blue: 14/255)            // #2D1B0E
    static let laymanGray = Color(red: 120/255, green: 110/255, blue: 100/255)         // #786E64
    static let laymanLightGray = Color(red: 200/255, green: 195/255, blue: 190/255)    // #C8C3BE
    static let laymanCardBg = Color(red: 255/255, green: 248/255, blue: 240/255)       // #FFF8F0
    static let laymanWhite = Color(red: 253/255, green: 250/255, blue: 247/255)        // #FDFAF7
    
    // Chat colors
    static let laymanBotBubble = Color(red: 245/255, green: 235/255, blue: 225/255)    // #F5EBE1
    static let laymanUserBubble = Color(red: 232/255, green: 115/255, blue: 74/255)    // same as laymanOrange
}

// MARK: - Gradients
extension LinearGradient {
    static let welcomeGradient = LinearGradient(
        colors: [
            Color(red: 255/255, green: 220/255, blue: 190/255),
            Color.laymanPeach,
            Color.laymanOrange
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let imageOverlayGradient = LinearGradient(
        colors: [.clear, .clear, .black.opacity(0.7)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color.laymanCream, Color.laymanBeige],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
struct LaymanFont {
    static func logo(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }
    
    static func title(_ size: CGFloat = 22) -> Font {
        .system(size: size, weight: .bold)
    }
    
    static func headline(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold)
    }
    
    static func body(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .regular)
    }
    
    static func caption(_ size: CGFloat = 13) -> Font {
        .system(size: size, weight: .regular)
    }
    
    static func small(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium)
    }
}

// MARK: - Dimensions
struct LaymanDimension {
    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20
    static let thumbnailSize: CGFloat = 75
    static let carouselHeight: CGFloat = 220
    static let contentCardHeight: CGFloat = 180
    static let tabBarHeight: CGFloat = 50
}
