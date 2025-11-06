import SwiftUI

struct WebsiteAnalysisLoadingView: View {
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Animated Logo
                ZStack {
                    Circle()
                        .stroke(Color.marketingPrimary.opacity(0.2), lineWidth: 4)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [Color.marketingPrimary, Color.marketingSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(rotationAngle))
                        .animation(
                            Animation.linear(duration: 1)
                                .repeatForever(autoreverses: false),
                            value: rotationAngle
                        )
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.marketingPrimary)
                }
                
                // Loading Text
                VStack(spacing: 12) {
                    Text("AI is analyzing your business")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("This may take a few moments...")
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                // Progress indicators
                HStack(spacing: 8) {
                    ProgressDot(delay: 0)
                    ProgressDot(delay: 0.2)
                    ProgressDot(delay: 0.4)
                }
                
                Spacer()
            }
        }
        .onAppear {
            rotationAngle = 360
        }
    }
}

struct ProgressDot: View {
    let delay: Double
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .fill(Color.marketingPrimary)
            .frame(width: 8, height: 8)
            .opacity(isAnimating ? 0.3 : 1)
            .scaleEffect(isAnimating ? 1.2 : 1)
            .animation(
                Animation.easeInOut(duration: 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    WebsiteAnalysisLoadingView()
}

