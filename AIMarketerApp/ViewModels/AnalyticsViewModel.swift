import Foundation
import SwiftUI

@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var analytics: [String: InstagramAnalytics] = [:] // Key: postId, Value: analytics
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefreshTime: Date?
    
    private let instagramService = InstagramService.shared
    private let supabaseService = SupabaseService.shared
    private var refreshTimer: Timer?
    private var lastPostCount: Int = 0
    
    /// Load analytics for all posted posts
    func loadAnalytics(for posts: [GeneratedPost]) async {
        // Filter to only posts that have been posted through the app (have instagramPostId)
        let postedPosts = posts.filter { $0.status == .posted && $0.instagramPostId != nil }
        
        guard !postedPosts.isEmpty else {
            print("📊 No posted posts to fetch analytics for")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Get Instagram connection to access token
            guard let connection = try await supabaseService.fetchInstagramConnection(),
                  connection.isConnected else {
                print("⚠️ No Instagram connection found")
                isLoading = false
                return
            }
            
            // Check if token needs refresh
            if connection.needsTokenRefresh {
                print("🔄 Refreshing Instagram token...")
                let refreshedToken = try await instagramService.refreshLongLivedToken(
                    currentToken: connection.accessToken
                )
                
                // Update connection in database
                let expirationDate = Date().addingTimeInterval(TimeInterval(refreshedToken.expirationSeconds))
                try await supabaseService.updateInstagramConnectionToken(
                    accessToken: refreshedToken.access_token,
                    expiresAt: expirationDate
                )
            }
            
            // Get current access token (use refreshed one if we just refreshed)
            let currentConnection = try await supabaseService.fetchInstagramConnection()
            guard let accessToken = currentConnection?.accessToken else {
                throw AnalyticsError.noAccessToken
            }
            
            // Fetch analytics for all posted posts
            let mediaIds = postedPosts.compactMap { $0.instagramPostId }
            print("📊 Fetching analytics for \(mediaIds.count) posts...")
            
            let fetchedAnalytics = try await instagramService.fetchMultipleMediaInsights(
                mediaIds: mediaIds,
                accessToken: accessToken
            )
            
            // Map analytics to posts by instagramPostId
            var analyticsDict: [String: InstagramAnalytics] = [:]
            for post in postedPosts {
                if let instagramPostId = post.instagramPostId,
                   let analytics = fetchedAnalytics.first(where: { $0.id == instagramPostId }) {
                    // Create analytics with postId set
                    let analyticsWithPostId = InstagramAnalytics(
                        id: analytics.id,
                        postId: post.id,
                        impressions: analytics.impressions,
                        reach: analytics.reach,
                        likes: analytics.likes,
                        comments: analytics.comments,
                        saves: analytics.saves,
                        shares: analytics.shares,
                        profileVisits: analytics.profileVisits,
                        websiteClicks: analytics.websiteClicks,
                        fetchedAt: analytics.fetchedAt
                    )
                    analyticsDict[post.id] = analyticsWithPostId
                }
            }
            
            self.analytics = analyticsDict
            self.lastRefreshTime = Date()
            print("✅ Loaded analytics for \(analyticsDict.count) posts")
            
        } catch {
            print("❌ Failed to load analytics: \(error.localizedDescription)")
            
            // Check if it's a permissions error
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("permission") || errorString.contains("oauth") || errorString.contains("code 10") {
                errorMessage = "Instagram Insights permission required. Please reconnect your Instagram account in Profile settings to grant insights access."
            } else {
                errorMessage = "Failed to load analytics: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    /// Get analytics for a specific post
    func getAnalytics(for postId: String) -> InstagramAnalytics? {
        return analytics[postId]
    }
    
    /// Refresh analytics for posted posts
    func refreshAnalytics(for posts: [GeneratedPost]) async {
        await loadAnalytics(for: posts)
    }
    
    /// Start auto-refresh timer for analytics (refreshes every 2 minutes)
    /// Note: Posts should be passed via the refresh callback, not stored
    func startAutoRefresh() {
        stopAutoRefresh() // Clean up any existing timer
        
        // Create timer that refreshes every 2 minutes
        // Posts will be passed when refresh is called
        let timer = Timer(timeInterval: 120.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Timer will be used for periodic refresh, but we'll get posts from notification
            print("⏰ Analytics auto-refresh timer fired")
        }
        
        // Add to run loop with common mode so it runs even during scrolling
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }
    
    /// Stop auto-refresh timer
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    /// Check if new posts were published and refresh analytics if needed
    func checkForNewPosts(currentPosts: [GeneratedPost]) async {
        let currentPostedCount = currentPosts.filter { $0.status == .posted && $0.instagramPostId != nil }.count
        
        // If we have new posted posts, refresh analytics
        if currentPostedCount > lastPostCount {
            print("📊 New posts detected (\(currentPostedCount) vs \(lastPostCount)), refreshing analytics...")
            lastPostCount = currentPostedCount
            await loadAnalytics(for: currentPosts)
        }
    }
}

enum AnalyticsError: LocalizedError {
    case noAccessToken
    case noInstagramConnection
    
    var errorDescription: String? {
        switch self {
        case .noAccessToken:
            return "No Instagram access token available"
        case .noInstagramConnection:
            return "No Instagram connection found"
        }
    }
}

