import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "4834D4"), Color(hex: "6C5CE7"), Color(hex: "A29BFE")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 300)
                .offset(x: -100, y: -200)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 200)
                .offset(x: 120, y: 250)

            VStack(spacing: 24) {
                // Logo
                ZStack {
                    // Pulsing glow ring
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 136, height: 136)
                        .scaleEffect(glowOpacity + 1)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: glowOpacity)

                    // White background circle
                    Circle()
                        .fill(Color.white)
                        .frame(width: 116, height: 116)
                        .shadow(color: Color.white.opacity(0.4), radius: 16, y: 4)

                    // Logo image
                    Image("comprehenza_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 88, height: 88)
                }

                VStack(spacing: 8) {
                    Text("Comprehenza")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Your Reading Journey Starts Here")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                scale   = 1.0
                opacity = 1.0
            }
            glowOpacity = 0.1
        }
    }
}
