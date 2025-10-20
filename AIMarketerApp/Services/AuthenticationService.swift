import Foundation

class AuthenticationService {
    static let shared = AuthenticationService()
    
    private init() {}
    
    // Mock authentication - replace with real backend calls
    func signUp(email: String, password: String, name: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock user creation
        let user = User(email: email, name: name)
        
        // Save to UserDefaults for demo purposes
        saveUser(user)
        
        return user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock login - check if user exists
        if let savedUser = loadUser() {
            return savedUser
        }
        
        // Create a mock user if none exists
        let user = User(email: email, name: "Demo User")
        saveUser(user)
        return user
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
    
    func getCurrentUser() -> User? {
        return loadUser()
    }
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }
    
    private func loadUser() -> User? {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            return user
        }
        return nil
    }
}

