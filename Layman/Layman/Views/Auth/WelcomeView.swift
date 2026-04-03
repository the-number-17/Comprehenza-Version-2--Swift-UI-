import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showAuth = false
    @State private var dragOffset: CGFloat = 0
    @State private var animateContent = false
    @State private var slideCompleted = false
    
    private let sliderWidth: CGFloat = 280
    private let knobSize: CGFloat = 56
    private let completionThreshold: CGFloat = 200
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient.welcomeGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Logo
                    Text("Layman")
                        .font(LaymanFont.logo(42))
                        .foregroundColor(.laymanDark)
                        .opacity(animateContent ? 1 : 0)
                        .offset(y: animateContent ? 0 : -20)
                    
                    Spacer()
                    
                    // Slogan
                    VStack(spacing: 8) {
                        Text("Business,")
                            .font(LaymanFont.title(28))
                            .foregroundColor(.laymanDark)
                        
                        Text("tech & startups")
                            .font(LaymanFont.title(28))
                            .foregroundColor(.laymanDark)
                        
                        Text("made simple")
                            .font(LaymanFont.title(28))
                            .foregroundColor(.laymanOrange)
                            .italic()
                    }
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    
                    Spacer()
                    Spacer()
                    
                    // Swipe to get started slider
                    ZStack(alignment: .leading) {
                        // Track background
                        RoundedRectangle(cornerRadius: knobSize / 2)
                            .fill(Color.laymanDark.opacity(0.15))
                            .frame(width: sliderWidth, height: knobSize)
                        
                        // Track text
                        Text("Swipe to get started")
                            .font(LaymanFont.caption(14))
                            .foregroundColor(.laymanDark.opacity(0.6))
                            .frame(width: sliderWidth, height: knobSize)
                        
                        // Filled track
                        RoundedRectangle(cornerRadius: knobSize / 2)
                            .fill(Color.laymanDark.opacity(0.1))
                            .frame(width: knobSize + dragOffset, height: knobSize)
                        
                        // Knob
                        Circle()
                            .fill(Color.laymanDark)
                            .frame(width: knobSize - 8, height: knobSize - 8)
                            .overlay {
                                Image(systemName: "chevron.right.2")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .padding(4)
                            .offset(x: dragOffset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newOffset = max(0, min(value.translation.width, sliderWidth - knobSize))
                                        dragOffset = newOffset
                                    }
                                    .onEnded { value in
                                        if dragOffset > completionThreshold {
                                            // Complete — navigate to auth
                                            withAnimation(.spring(response: 0.4)) {
                                                dragOffset = sliderWidth - knobSize
                                                slideCompleted = true
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                showAuth = true
                                            }
                                        } else {
                                            // Reset
                                            withAnimation(.spring(response: 0.4)) {
                                                dragOffset = 0
                                            }
                                        }
                                    }
                            )
                    }
                    .opacity(animateContent ? 1 : 0)
                    
                    Spacer()
                        .frame(height: 60)
                }
                .padding(.horizontal, LaymanDimension.screenPadding)
            }
            .navigationDestination(isPresented: $showAuth) {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthViewModel())
}
