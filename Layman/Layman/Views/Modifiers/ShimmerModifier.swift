import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: -geo.size.width + (geo.size.width * 2 * phase))
                }
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Building Blocks

struct SkeletonLine: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.laymanLightGray.opacity(0.25))
            .frame(maxWidth: width ?? .infinity)
            .frame(height: height)
            .shimmer()
    }
}

struct SkeletonCard: View {
    let lineCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<lineCount, id: \.self) { i in
                SkeletonLine(width: i == lineCount - 1 ? 160 : nil)
            }
        }
        .padding(24)
        .background(Color.laymanCardBg)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
