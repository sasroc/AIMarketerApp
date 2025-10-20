import Foundation
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let authService = AuthenticationService.shared
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        currentUser = authService.getCurrentUser()
        isAuthenticated = currentUser != nil
    }
    
    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signUp(email: email, password: password, name: name)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        authService.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    func demoLogin() async {
        isLoading = true
        errorMessage = nil
        
        // Create a demo user instantly (no network delay for testing)
        let demoUser = User(
            email: "demo@aimarketer.app",
            name: "Demo User",
            instagramConnected: false
        )
        
        currentUser = demoUser
        isAuthenticated = true
        isLoading = false
    }
}

