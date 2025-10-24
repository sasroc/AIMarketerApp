import Foundation
import Supabase
import AuthenticationServices

class AuthenticationService: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AuthenticationService()
    
    private let supabase: SupabaseClient
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private override init() {
        // Load configuration from Config.plist
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let configData = NSDictionary(contentsOfFile: configPath),
              let supabaseURL = configData["SupabaseURL"] as? String,
              let supabaseKey = configData["SupabaseKey"] as? String else {
            fatalError("Config.plist not found or missing required keys. Please copy Config.template.plist to Config.plist and fill in your credentials.")
        }
        
        supabase = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
        
        super.init()
        
        // Check for existing session
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: ["name": .string(name)]
        )
        
        let user = response.user
        
        let appUser = User(
            id: user.id.uuidString,
            email: user.email ?? "",
            name: name
        )
        
        await MainActor.run {
            self.currentUser = appUser
            self.isAuthenticated = true
        }
        
        return appUser
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let response = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        let user = response.user
        
        let appUser = User(
            id: user.id.uuidString,
            email: user.email ?? "",
            name: user.userMetadata["name"]?.stringValue ?? ""
        )
        
        await MainActor.run {
            self.currentUser = appUser
            self.isAuthenticated = true
        }
        
        return appUser
    }
    
    func signInWithGoogle() async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                // Use the app's custom URL scheme for redirect
                var authURL = try supabase.auth.getOAuthSignInURL(
                    provider: .google,
                    redirectTo: URL(string: "ai-marketer://auth/callback")
                )
                
                // Add prompt=select_account to force Google to show account picker
                if var components = URLComponents(url: authURL, resolvingAgainstBaseURL: false) {
                    var queryItems = components.queryItems ?? []
                    queryItems.append(URLQueryItem(name: "prompt", value: "select_account"))
                    components.queryItems = queryItems
                    if let modifiedURL = components.url {
                        authURL = modifiedURL
                    }
                }
                
                print("🔍 Using custom redirect URL: ai-marketer://auth/callback")
                print("🔍 Added prompt=select_account to force account picker")
                
                print("🔍 OAuth URL components:")
                print("  - Scheme: \(authURL.scheme ?? "nil")")
                print("  - Host: \(authURL.host ?? "nil")")
                print("  - Path: \(authURL.path)")
                print("  - Query: \(authURL.query ?? "nil")")
                
                print("🔗 Generated OAuth URL: \(authURL)")
                print("📱 Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
                print("🔑 Supabase configuration loaded successfully")
            
            print("🔄 Creating ASWebAuthenticationSession...")
            print("🔄 Auth URL: \(authURL)")
            print("🔄 Callback scheme: ai-marketer")
            
            // Test if the URL is accessible
            print("🔍 Testing OAuth URL accessibility...")
            URLSession.shared.dataTask(with: authURL) { data, response, error in
                if let error = error {
                    print("❌ URL test failed: \(error)")
                } else if let httpResponse = response as? HTTPURLResponse {
                    print("✅ URL test response: \(httpResponse.statusCode)")
                    if let data = data, let body = String(data: data, encoding: .utf8) {
                        print("📄 Response body preview: \(String(body.prefix(200)))")
                    }
                }
            }.resume()
            
            let webAuthSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "ai-marketer"
            ) { callbackURL, error in
                print("🔔 ASWebAuthenticationSession completion handler called")
                
                if let error = error {
                    let nsError = error as NSError
                    print("❌ OAuth Error: \(error)")
                    print("❌ Error details: \(error.localizedDescription)")
                    print("❌ Error domain: \(nsError.domain)")
                    print("❌ Error code: \(nsError.code)")
                    
                    // Error code 1 means user cancelled - but check if we have a session anyway
                    if nsError.code == 1 {
                        print("⚠️ Session cancelled - checking if auth completed on server...")
                        print("⚠️ This means the OAuth redirect is not working properly")
                        print("⚠️ Check Supabase Dashboard -> Authentication -> URL Configuration")
                        print("⚠️ Add 'ai-marketer://**' to Redirect URLs")
                        Task {
                            do {
                                // Wait a moment for the session to be created
                                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                                
                                let session = try await self.supabase.auth.session
                                let user = session.user
                                
                                print("✅ Found existing session! User: \(user.email ?? "unknown")")
                                
                                let appUser = User(
                                    id: user.id.uuidString,
                                    email: user.email ?? "",
                                    name: user.userMetadata["name"]?.stringValue ?? user.userMetadata["full_name"]?.stringValue ?? ""
                                )
                                
                                await MainActor.run {
                                    self.currentUser = appUser
                                    self.isAuthenticated = true
                                }
                                
                                continuation.resume(returning: appUser)
                            } catch {
                                print("❌ No session found: \(error)")
                                print("❌ This confirms the OAuth flow is not completing properly")
                                continuation.resume(throwing: nsError)
                            }
                        }
                        return
                    }
                    
                    continuation.resume(throwing: error)
                    return
                }
                
                print("🔍 OAuth callback received - checking URL...")

                guard let callbackURL = callbackURL else {
                    print("❌ No callback URL received")
                    continuation.resume(throwing: AuthError.signInFailed)
                    return
                }
                
                print("✅ Received callback URL: \(callbackURL)")
                print("✅ Callback URL components: \(callbackURL.absoluteString)")
                
                Task {
                    do {
                        print("🔄 Creating session from callback URL...")
                        let session = try await self.supabase.auth.session(from: callbackURL)
                        let user = session.user
                        
                        print("✅ Session created successfully")
                        print("✅ User ID: \(user.id.uuidString)")
                        print("✅ User email: \(user.email ?? "No email")")
                        print("✅ User metadata: \(user.userMetadata)")
                        
                        let appUser = User(
                            id: user.id.uuidString,
                            email: user.email ?? "",
                            name: user.userMetadata["name"]?.stringValue ?? user.userMetadata["full_name"]?.stringValue ?? ""
                        )
                        
                        print("✅ Created app user: \(appUser)")
                        
                        await MainActor.run {
                            self.currentUser = appUser
                            self.isAuthenticated = true
                        }

                        print("✅ Authentication completed successfully")
                        continuation.resume(returning: appUser)
                    } catch {
                        print("❌ Session creation failed: \(error)")
                        print("❌ Session error details: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            webAuthSession.presentationContextProvider = self
            webAuthSession.prefersEphemeralWebBrowserSession = false
            print("🔄 Starting ASWebAuthenticationSession...")
            print("🔄 Ephemeral session: false (keeps Google accounts list, but forces account picker)")
            
            DispatchQueue.main.async {
                let success = webAuthSession.start()
                print("🔄 Session start result: \(success)")
                
                if !success {
                    print("❌ Session failed to start!")
                    continuation.resume(throwing: AuthError.signInFailed)
                    return
                }
                
                // Add a timeout to detect if the session gets stuck
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    print("⏰ OAuth session timeout check - 10 seconds elapsed")
                }
            }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    private func checkAuthStatus() async {
        do {
            let session = try await supabase.auth.session
            let user = session.user
            let appUser = User(
                id: user.id.uuidString,
                email: user.email ?? "",
                name: user.userMetadata["name"]?.stringValue ?? ""
            )
            
            await MainActor.run {
                self.currentUser = appUser
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }
    
    // MARK: - ASWebAuthenticationPresentationContextProviding
    
    @MainActor
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case signUpFailed
    case signInFailed
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .signInFailed:
            return "Failed to sign in. Please check your credentials."
        case .notImplemented:
            return "Google sign-in is not yet implemented. Please use email/password for now."
        }
    }
}

