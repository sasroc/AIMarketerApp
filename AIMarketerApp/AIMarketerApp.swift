import SwiftUI

extension Color {
    // Corporate Green Theme - Growth, Prosperity, Success
    static let marketingPrimary = Color(red: 0.024, green: 0.373, blue: 0.275) // Forest Green #065F46
    static let marketingSecondary = Color(red: 0.051, green: 0.580, blue: 0.533) // Teal #0D9488
    static let marketingAccent = Color(red: 0.063, green: 0.725, blue: 0.506) // Emerald #10B981
    static let marketingSuccess = Color(red: 0.396, green: 0.639, blue: 0.051) // Lime Green #65A30D
    static let marketingWarning = Color(red: 0.918, green: 0.345, blue: 0.047) // Orange #EA580C
    static let marketingError = Color(red: 0.863, green: 0.149, blue: 0.149) // Red #DC2626
    static let marketingInfo = Color(red: 0.051, green: 0.580, blue: 0.533) // Teal #0D9488
    
    // Background variations
    static let marketingBackground = Color.black
    static let marketingCardBackground = Color.gray.opacity(0.1)
    static let marketingSelectedBackground = marketingPrimary.opacity(0.2)
    static let marketingHoverBackground = marketingPrimary.opacity(0.1)
}

@main
struct AIMarketerApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    print("🔗 App received URL: \(url)")
                    handleOAuthCallback(url: url)
                }
        }
    }
    
    private func handleOAuthCallback(url: URL) {
        print("🔗 Handling OAuth callback: \(url)")
        print("🔗 URL scheme: \(url.scheme ?? "nil")")
        print("🔗 URL host: \(url.host ?? "nil")")
        print("🔗 URL path: \(url.path)")
        print("🔗 URL query: \(url.query ?? "nil")")
        
        // Check if this is our OAuth callback
        if url.scheme == "ai-marketer" && url.host == "auth" && url.path == "/callback" {
            print("✅ OAuth callback detected!")
            // The ASWebAuthenticationSession should handle this automatically
            // but we can add additional processing here if needed
        }
    }
}

