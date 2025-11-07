import Foundation
import Supabase

class UserProfileService {
    static let shared = UserProfileService()
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    func fetchUserProfile() async throws -> UserProfile? {
        guard let userId = await getCurrentUserId() else {
            return nil
        }
        
        let supabase = supabaseService.client
        
        let profiles: [UserProfile] = try await supabase
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return profiles.first
    }
    
    private func getCurrentUserId() async -> UUID? {
        do {
            let session = try await supabaseService.client.auth.session
            return UUID(uuidString: session.user.id.uuidString)
        } catch {
            return nil
        }
    }
}

