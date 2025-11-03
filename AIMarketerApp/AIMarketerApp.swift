import SwiftUI

extension Color {
    // Blue/Purple Gradient Theme
    static let marketingPrimary = Color(red: 0.231, green: 0.506, blue: 0.965) // Blue #3B82F6
    static let marketingSecondary = Color(red: 0.545, green: 0.361, blue: 0.965) // Purple #8B5CF6
    static let marketingAccent = Color(red: 0.584, green: 0.345, blue: 0.953) // Bright Purple #9565F4
    static let marketingSuccess = Color(red: 0.396, green: 0.639, blue: 0.051) // Lime Green #65A30D
    static let marketingWarning = Color(red: 0.918, green: 0.345, blue: 0.047) // Orange #EA580C
    static let marketingError = Color(red: 0.863, green: 0.149, blue: 0.149) // Red #DC2626
    static let marketingInfo = Color(red: 0.231, green: 0.506, blue: 0.965) // Blue #3B82F6
    
    // Background variations
    static let marketingBackground = Color.black
    static let marketingCardBackground = Color.gray.opacity(0.1)
    static let marketingSelectedBackground = marketingPrimary.opacity(0.2)
    static let marketingHoverBackground = marketingPrimary.opacity(0.1)
}

@main
struct AIMarketerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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

