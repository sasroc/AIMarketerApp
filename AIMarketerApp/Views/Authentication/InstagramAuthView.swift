import SwiftUI
import WebKit

struct InstagramAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    let onAuthComplete: (InstagramConnection) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                WebView(
                    url: InstagramService.shared.getAuthorizationURL()!,
                    onCodeReceived: handleAuthCode
                )
                
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("Connecting Instagram...")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                        )
                    }
                }
            }
            .navigationTitle("Connect Instagram")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Connection Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAuthCode(_ code: String) {
        Task {
            await completeOAuthFlow(code: code)
        }
    }
    
    private func completeOAuthFlow(code: String) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            print("🔐 Exchanging authorization code for access token...")
            
            // Step 1: Exchange code for short-lived token
            let shortLivedToken = try await InstagramService.shared.exchangeCodeForToken(code: code)
            
            print("✅ Got short-lived token, exchanging for long-lived token...")
            
            // Step 2: Exchange for long-lived token (60 days)
            let longLivedTokenResponse = try await InstagramService.shared.getLongLivedToken(
                shortLivedToken: shortLivedToken
            )
            
            print("✅ Got long-lived token, fetching Facebook pages...")
            
            // Step 3: Get Facebook pages
            let pages = try await InstagramService.shared.getFacebookPages(
                accessToken: longLivedTokenResponse.access_token
            )
            
            guard let firstPage = pages.first else {
                throw InstagramError.noBusinessAccount
            }
            
            print("✅ Found Facebook page: \(firstPage.name), fetching Instagram account...")
            
            // Step 4: Get Instagram Business Account from the page
            let instagramAccount = try await InstagramService.shared.getInstagramBusinessAccount(
                pageId: firstPage.id,
                pageAccessToken: firstPage.access_token
            )
            
            print("✅ Connected to Instagram account: @\(instagramAccount.username)")
            
            // Step 5: Calculate token expiration
            let expiresAt = Date().addingTimeInterval(TimeInterval(longLivedTokenResponse.expirationSeconds))
            
            // Step 6: Create connection object
            let connection = InstagramConnection(
                userId: "", // Will be set by SupabaseService
                instagramUserId: instagramAccount.id,
                instagramUsername: instagramAccount.username,
                facebookPageId: firstPage.id,
                facebookPageName: firstPage.name,
                accessToken: firstPage.access_token, // Use page access token for API calls
                tokenExpiresAt: expiresAt
            )
            
            // Step 7: Save to database via callback
            await MainActor.run {
                isLoading = false
                onAuthComplete(connection)
                dismiss()
            }
            
        } catch let error as InstagramError {
            await MainActor.run {
                isLoading = false
                errorMessage = error.localizedDescription
                showError = true
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

// MARK: - WebView for OAuth

struct WebView: UIViewRepresentable {
    let url: URL
    let onCodeReceived: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeReceived: onCodeReceived)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let onCodeReceived: (String) -> Void
        
        init(onCodeReceived: @escaping (String) -> Void) {
            self.onCodeReceived = onCodeReceived
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Check if this is the redirect with the authorization code
            if let url = navigationAction.request.url {
                print("🔍 Navigating to: \(url.absoluteString)")
                
                // Check for localhost redirect (from Facebook OAuth)
                if (url.host == "localhost" || url.host == "127.0.0.1"),
                   let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                    
                    print("🔐 Received authorization code from localhost")
                    onCodeReceived(code)
                    decisionHandler(.cancel)
                    return
                }
                
                // Also check for custom scheme (backup)
                if url.scheme == "aimarketer",
                   url.host == "instagram-auth",
                   let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let code = components.queryItems?.first(where: { $0.name == "code" })?.value {
                    
                    print("🔐 Received authorization code from custom scheme")
                    onCodeReceived(code)
                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
    }
}

// MARK: - Preview

#Preview {
    InstagramAuthView { connection in
        print("Connected: @\(connection.instagramUsername)")
    }
}


