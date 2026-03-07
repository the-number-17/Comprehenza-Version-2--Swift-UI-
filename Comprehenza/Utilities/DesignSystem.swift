import SwiftUI

// MARK: - Brand Colors
extension Color {
    static let brandPrimary    = Color(hex: "6C5CE7")  // deep violet
    static let brandSecondary  = Color(hex: "A29BFE")  // lavender
    static let brandAccent     = Color(hex: "FD79A8")  // coral pink
    static let brandOrange     = Color(hex: "FDCB6E")  // warm yellow
    static let brandGreen      = Color(hex: "00B894")  // mint green
    static let brandRed        = Color(hex: "E17055")  // soft red
    static let brandTeal       = Color(hex: "00CEC9")  // teal
    static let cardBg          = Color(hex: "F8F7FF")  // near-white purple tint
    static let darkBg          = Color(hex: "2D3436")  // dark charcoal

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Category
enum ExerciseCategory: String, CaseIterable, Codable {
    case comprehension = "Comprehension"
    case vocabulary    = "Vocabulary"
    case relearning    = "Relearning"
    case fluency       = "Fluency"

    var icon: String {
        switch self {
        case .comprehension: return "brain.head.profile"
        case .vocabulary:    return "textformat.abc"
        case .relearning:    return "arrow.clockwise"
        case .fluency:       return "waveform.and.mic"
        }
    }

    var color: Color {
        switch self {
        case .comprehension: return .brandPrimary
        case .vocabulary:    return .brandTeal
        case .relearning:    return .brandOrange
        case .fluency:       return .brandAccent
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .comprehension:
            return LinearGradient(colors: [Color(hex: "6C5CE7"), Color(hex: "A29BFE")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .vocabulary:
            return LinearGradient(colors: [Color(hex: "00CEC9"), Color(hex: "81ECEC")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .relearning:
            return LinearGradient(colors: [Color(hex: "FDCB6E"), Color(hex: "E17055")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .fluency:
            return LinearGradient(colors: [Color(hex: "FD79A8"), Color(hex: "A29BFE")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var shortName: String {
        switch self {
        case .comprehension: return "Comp"
        case .vocabulary:    return "Vocab"
        case .relearning:    return "Learn"
        case .fluency:       return "Talk"
        }
    }
}

// MARK: - Difficulty Level
enum DifficultyLevel: Int, CaseIterable, Codable {
    case beginner     = 1
    case intermediate = 2
    case advanced     = 3
    case pro          = 4

    var label: String {
        switch self {
        case .beginner:     return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        case .pro:          return "Pro"
        }
    }

    var range: ClosedRange<Int> {
        switch self {
        case .beginner:     return 0...100
        case .intermediate: return 101...200
        case .advanced:     return 201...300
        case .pro:          return 301...400
        }
    }

    var color: Color {
        switch self {
        case .beginner:     return .brandGreen
        case .intermediate: return .brandOrange
        case .advanced:     return .brandPrimary
        case .pro:          return .brandAccent
        }
    }

    var icon: String {
        switch self {
        case .beginner:     return "leaf.fill"
        case .intermediate: return "flame.fill"
        case .advanced:     return "star.fill"
        case .pro:          return "crown.fill"
        }
    }

    static func level(for cq: Int) -> DifficultyLevel {
        switch cq {
        case 0...100:   return .beginner
        case 101...200: return .intermediate
        case 201...300: return .advanced
        default:        return .pro
        }
    }
}

// MARK: - Avatar
enum Avatar: String, CaseIterable, Codable {
    case owl    = "owl"
    case fox    = "fox"
    case bear   = "bear"
    case bunny  = "bunny"
    case cat    = "cat"
    case dragon = "dragon"

    var emoji: String {
        switch self {
        case .owl:    return "🦉"
        case .fox:    return "🦊"
        case .bear:   return "🐻"
        case .bunny:  return "🐰"
        case .cat:    return "🐱"
        case .dragon: return "🐲"
        }
    }

    var color: Color {
        switch self {
        case .owl:    return Color(hex: "6C5CE7")
        case .fox:    return Color(hex: "E17055")
        case .bear:   return Color(hex: "FDCB6E")
        case .bunny:  return Color(hex: "FD79A8")
        case .cat:    return Color(hex: "A29BFE")
        case .dragon: return Color(hex: "00B894")
        }
    }
}

// MARK: - View Modifiers
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .brandPrimary
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.85 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 20) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Haptics
struct HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
