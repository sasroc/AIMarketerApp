import UIKit

final class PostStatusBackgroundFetcher {
    static let shared = PostStatusBackgroundFetcher()
    
    private let supabaseService = SupabaseService.shared
    private let notificationManager = NotificationManager.shared
    
    private init() {}
    
    func performFetch() async -> UIBackgroundFetchResult {
        do {
            let posts = try await supabaseService.fetchGeneratedPosts()
            let changes = await PostStatusTracker.shared.process(posts: posts)
            guard !changes.isEmpty else {
                return .noData
            }
            for change in changes {
                notificationManager.sendPostStatusNotification(for: change.post, previousStatus: change.previousStatus)
            }
            return .newData
        } catch {
            print("❌ Background fetch failed: \(error.localizedDescription)")
            return .failed
        }
    }
}


