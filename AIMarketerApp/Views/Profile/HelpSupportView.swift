import SwiftUI

struct HelpSupportView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // In progress icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.marketingPrimary.opacity(0.2), Color.marketingSecondary.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.marketingPrimary)
                    }
                    
                    VStack(spacing: 12) {
                        Text("In Progress")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Help & Support features are currently being developed. Please check back soon for ways to get assistance.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HelpSupportView()
}

