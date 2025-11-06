import SwiftUI

struct BusinessAnalysisResultsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.marketingSuccess)
                            
                            Text("Analysis Complete!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        if let analysis = viewModel.businessAnalysis {
                            // Business Summary Card
                            AnalysisCard(
                                title: "Business Summary",
                                content: analysis.summary,
                                icon: "doc.text.fill"
                            )
                            
                            // Value Proposition Card
                            if !analysis.valueProposition.isEmpty {
                                AnalysisCard(
                                    title: "Value Proposition",
                                    content: analysis.valueProposition,
                                    icon: "star.fill"
                                )
                            }
                            
                            // Business Description Card
                            if !analysis.description.isEmpty {
                                AnalysisCard(
                                    title: "Business Description",
                                    content: analysis.description,
                                    icon: "info.circle.fill"
                                )
                            }
                            
                            // Brand Colors
                            if !analysis.colors.isEmpty {
                                BrandColorsCard(colors: analysis.colors)
                            }
                            
                            // Logo
                            if let logoUrl = analysis.logoUrl {
                                LogoCard(logoUrl: logoUrl)
                            }
                            
                            // Brand Images
                            if !analysis.images.isEmpty {
                                BrandImagesCard(imageUrls: analysis.images)
                            }
                        }
                        
                        // Continue Button
                        Button(action: {
                            Task {
                                do {
                                    try await viewModel.completeOnboarding()
                                    // Notify that onboarding is complete
                                    NotificationCenter.default.post(name: RootView.onboardingCompletedNotification, object: nil)
                                } catch {
                                    // Handle error
                                }
                            }
                        }) {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.marketingPrimary, Color.marketingSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AnalysisCard: View {
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.marketingPrimary)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 32)
    }
}

struct BrandColorsCard: View {
    let colors: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(.marketingPrimary)
                Text("Brand Colors")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(colors, id: \.self) { colorHex in
                        ColorSwatch(colorHex: colorHex)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 32)
    }
}

struct ColorSwatch: View {
    let colorHex: String
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: colorHex) ?? Color.gray)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text(colorHex.uppercased())
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

struct LogoCard: View {
    let logoUrl: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundColor(.marketingPrimary)
                Text("Logo")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            AsyncImage(url: URL(string: logoUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(height: 100)
            .cornerRadius(8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 32)
    }
}

struct BrandImagesCard: View {
    let imageUrls: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .foregroundColor(.marketingPrimary)
                Text("Brand Images")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(imageUrls, id: \.self) { imageUrl in
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.2))
                        }
                        .frame(width: 120, height: 120)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 32)
    }
}

// Extension to convert hex string to Color
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    BusinessAnalysisResultsView(viewModel: OnboardingViewModel())
        .environmentObject(AuthenticationViewModel())
}

