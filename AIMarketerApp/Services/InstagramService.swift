import Foundation
import UIKit

/// Service for handling Instagram Graph API interactions
/// Supports OAuth authentication, media publishing, and token management
class InstagramService {
    static let shared = InstagramService()
    
    private let graphAPIBaseURL = "https://graph.facebook.com/v22.0"
    
    // MARK: - Configuration
    // These should be loaded from Config.plist
    private var facebookAppId: String {
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let configData = NSDictionary(contentsOfFile: configPath),
              let appId = configData["FacebookAppId"] as? String else {
            fatalError("Config.plist missing FacebookAppId")
        }
        return appId
    }
    
    private var facebookAppSecret: String {
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let configData = NSDictionary(contentsOfFile: configPath),
              let secret = configData["FacebookAppSecret"] as? String else {
            fatalError("Config.plist missing FacebookAppSecret")
        }
        return secret
    }
    
    private var redirectURI: String {
        return "https://localhost/"
    }
    
    private init() {}
    
    // MARK: - OAuth Flow
    
    /// Generate the Facebook OAuth URL for Instagram permissions
    func getAuthorizationURL() -> URL? {
        var components = URLComponents(string: "https://www.facebook.com/v22.0/dialog/oauth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: facebookAppId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: "instagram_basic,instagram_content_publish,instagram_manage_insights,pages_read_engagement,pages_show_list,business_management"),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "state", value: UUID().uuidString) // CSRF protection
        ]
        return components?.url
    }
    
    /// Exchange authorization code for access token
    func exchangeCodeForToken(code: String) async throws -> String {
        let url = URL(string: "\(graphAPIBaseURL)/oauth/access_token")!
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: facebookAppId),
            URLQueryItem(name: "client_secret", value: facebookAppSecret),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code", value: code)
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = components.query?.data(using: .utf8)
        
        print("🔍 Exchanging code for token...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log the raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Token exchange response: \(jsonString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ HTTP Error: Status code \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
            throw InstagramError.authenticationFailed
        }
        
        do {
            let tokenResponse = try JSONDecoder().decode(AccessTokenResponse.self, from: data)
            print("✅ Successfully got access token")
            return tokenResponse.access_token
        } catch {
            print("❌ Failed to decode token response: \(error)")
            throw InstagramError.authenticationFailed
        }
    }
    
    /// Get long-lived access token (60 days) from short-lived token
    func getLongLivedToken(shortLivedToken: String) async throws -> LongLivedTokenResponse {
        var components = URLComponents(string: "\(graphAPIBaseURL)/oauth/access_token")!
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "fb_exchange_token"),
            URLQueryItem(name: "client_id", value: facebookAppId),
            URLQueryItem(name: "client_secret", value: facebookAppSecret),
            URLQueryItem(name: "fb_exchange_token", value: shortLivedToken)
        ]
        
        print("🔍 Requesting long-lived token from: \(components.url!.absoluteString)")
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        
        // Log the raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Long-lived token response: \(jsonString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ HTTP Error: Status code \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
            throw InstagramError.authenticationFailed
        }
        
        do {
            let tokenResponse = try JSONDecoder().decode(LongLivedTokenResponse.self, from: data)
            print("✅ Successfully decoded long-lived token (expires in \(tokenResponse.expirationSeconds) seconds)")
            return tokenResponse
        } catch {
            print("❌ Failed to decode long-lived token response: \(error)")
            print("❌ Decoding error details: \(error.localizedDescription)")
            throw InstagramError.authenticationFailed
        }
    }
    
    /// Get Facebook pages connected to the user account
    /// This handles both personal pages and Business Manager pages
    func getFacebookPages(accessToken: String) async throws -> [FacebookPage] {
        // First try /me/accounts (for personal pages)
        var components = URLComponents(string: "\(graphAPIBaseURL)/me/accounts")!
        components.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "fields", value: "id,name,access_token")
        ]
        
        print("🔍 Fetching Facebook Pages from /me/accounts...")
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        
        // Log the raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 Pages Response: \(jsonString)")
        }
        
        let response = try JSONDecoder().decode(PagesResponse.self, from: data)
        
        if response.data.isEmpty {
            print("⚠️ No pages found via /me/accounts, trying Business Manager approach...")
            // Try to get pages via businesses the user manages
            return try await getBusinessPages(accessToken: accessToken)
        }
        
        print("✅ Found \(response.data.count) Facebook Page(s)")
        for page in response.data {
            print("   📄 Page: \(page.name) (ID: \(page.id))")
        }
        return response.data
    }
    
    /// Get Facebook pages from Business Manager
    private func getBusinessPages(accessToken: String) async throws -> [FacebookPage] {
        // Get businesses the user has access to
        var components = URLComponents(string: "\(graphAPIBaseURL)/me/businesses")!
        components.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "fields", value: "id,name")
        ]
        
        print("🔍 Fetching Business Manager accounts...")
        let (businessData, _) = try await URLSession.shared.data(from: components.url!)
        
        if let jsonString = String(data: businessData, encoding: .utf8) {
            print("📦 Businesses Response: \(jsonString)")
        }
        
        let businessResponse = try JSONDecoder().decode(BusinessesResponse.self, from: businessData)
        
        guard let firstBusiness = businessResponse.data.first else {
            print("❌ No Business Manager accounts found")
            throw InstagramError.noBusinessAccount
        }
        
        print("✅ Found Business: \(firstBusiness.name) (ID: \(firstBusiness.id))")
        
        // Now get pages owned by this business
        var pagesComponents = URLComponents(string: "\(graphAPIBaseURL)/\(firstBusiness.id)/owned_pages")!
        pagesComponents.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "fields", value: "id,name,access_token")
        ]
        
        print("🔍 Fetching pages from Business Manager...")
        let (pagesData, _) = try await URLSession.shared.data(from: pagesComponents.url!)
        
        if let jsonString = String(data: pagesData, encoding: .utf8) {
            print("📦 Business Pages Response: \(jsonString)")
        }
        
        let pagesResponse = try JSONDecoder().decode(PagesResponse.self, from: pagesData)
        print("✅ Found \(pagesResponse.data.count) Business Manager Page(s)")
        for page in pagesResponse.data {
            print("   📄 Page: \(page.name) (ID: \(page.id))")
        }
        
        return pagesResponse.data
    }
    
    /// Get Instagram Business Account ID linked to a Facebook Page
    func getInstagramBusinessAccount(pageId: String, pageAccessToken: String) async throws -> InstagramAccountInfo {
        var components = URLComponents(string: "\(graphAPIBaseURL)/\(pageId)")!
        components.queryItems = [
            URLQueryItem(name: "access_token", value: pageAccessToken),
            URLQueryItem(name: "fields", value: "instagram_business_account")
        ]
        
        print("🔍 Fetching Instagram Business Account for page: \(pageId)")
        print("🔍 API URL: \(components.url!.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        
        // Log the raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📦 API Response: \(jsonString)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            print("❌ HTTP Error: Status code \(String(describing: (response as? HTTPURLResponse)?.statusCode))")
            throw InstagramError.noBusinessAccount
        }
        
        let pageInfo = try JSONDecoder().decode(PageInstagramInfo.self, from: data)
        
        guard let igAccountId = pageInfo.instagram_business_account?.id else {
            print("❌ No instagram_business_account field found in response")
            print("❌ This usually means:")
            print("   1. Instagram account is not a Business account")
            print("   2. Instagram account is not linked to this Facebook Page")
            print("   3. The page owner needs to reconnect Instagram in Facebook Page settings")
            throw InstagramError.noBusinessAccount
        }
        
        print("✅ Found Instagram Business Account ID: \(igAccountId)")
        
        // Get Instagram username
        let username = try await getInstagramUsername(accountId: igAccountId, accessToken: pageAccessToken)
        
        return InstagramAccountInfo(id: igAccountId, username: username)
    }
    
    /// Get Instagram username for an account
    private func getInstagramUsername(accountId: String, accessToken: String) async throws -> String {
        var components = URLComponents(string: "\(graphAPIBaseURL)/\(accountId)")!
        components.queryItems = [
            URLQueryItem(name: "access_token", value: accessToken),
            URLQueryItem(name: "fields", value: "username")
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let accountInfo = try JSONDecoder().decode(InstagramAccountDetails.self, from: data)
        return accountInfo.username
    }
    
    // MARK: - Publishing Content
    
    /// Create a media container for an image post
    /// Returns the container ID that can be published later
    func createMediaContainer(
        instagramAccountId: String,
        imageUrl: String,
        caption: String,
        accessToken: String
    ) async throws -> String {
        var components = URLComponents(string: "\(graphAPIBaseURL)/\(instagramAccountId)/media")!
        components.queryItems = [
            URLQueryItem(name: "image_url", value: imageUrl),
            URLQueryItem(name: "caption", value: caption),
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(InstagramErrorResponse.self, from: data)
            throw InstagramError.publishFailed(errorResponse?.error.message ?? "Unknown error")
        }
        
        let containerResponse = try JSONDecoder().decode(MediaContainerResponse.self, from: data)
        return containerResponse.id
    }
    
    /// Create a media container for a video post
    /// Videos require a different endpoint and have different parameters
    func createVideoMediaContainer(
        instagramAccountId: String,
        videoUrl: String,
        caption: String,
        accessToken: String
    ) async throws -> String {
        var components = URLComponents(string: "\(graphAPIBaseURL)/\(instagramAccountId)/media")!
        components.queryItems = [
            URLQueryItem(name: "media_type", value: "VIDEO"),
            URLQueryItem(name: "video_url", value: videoUrl),
            URLQueryItem(name: "caption", value: caption),
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(InstagramErrorResponse.self, from: data)
            throw InstagramError.publishFailed(errorResponse?.error.message ?? "Unknown error")
        }
        
        let containerResponse = try JSONDecoder().decode(MediaContainerResponse.self, from: data)
        return containerResponse.id
    }
    
    /// Check if a video container is ready to be published
    func checkContainerStatus(containerId: String, accessToken: String) async throws -> ContainerStatus {
        var components = URLComponents(string: "\(graphAPIBaseURL)/\(containerId)")!
        components.queryItems = [
            URLQueryItem(name: "fields", value: "status_code"),
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let statusResponse = try JSONDecoder().decode(ContainerStatusResponse.self, from: data)
        
        switch statusResponse.status_code {
        case "FINISHED":
            return .finished
        case "IN_PROGRESS":
            return .inProgress
        case "ERROR":
            return .error
        default:
            return .unknown
        }
    }
    
    /// Publish a media container to Instagram
    /// Returns the Instagram media ID
    func publishMediaContainer(
        instagramAccountId: String,
        creationId: String,
        accessToken: String
    ) async throws -> PublishResponse {
        var components = URLComponents(string: "\(graphAPIBaseURL)/\(instagramAccountId)/media_publish")!
        components.queryItems = [
            URLQueryItem(name: "creation_id", value: creationId),
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(InstagramErrorResponse.self, from: data)
            throw InstagramError.publishFailed(errorResponse?.error.message ?? "Unknown error")
        }
        
        let publishResponse = try JSONDecoder().decode(PublishResponse.self, from: data)
        return publishResponse
    }
    
    /// Complete workflow: Create container and publish (for images)
    func publishImagePost(
        instagramAccountId: String,
        imageUrl: String,
        caption: String,
        accessToken: String
    ) async throws -> PublishResponse {
        print("📸 Creating media container for image...")
        let containerId = try await createMediaContainer(
            instagramAccountId: instagramAccountId,
            imageUrl: imageUrl,
            caption: caption,
            accessToken: accessToken
        )
        
        print("📸 Container created: \(containerId), publishing...")
        let publishResponse = try await publishMediaContainer(
            instagramAccountId: instagramAccountId,
            creationId: containerId,
            accessToken: accessToken
        )
        
        print("✅ Post published successfully: \(publishResponse.id)")
        return publishResponse
    }
    
    /// Create a carousel media container for multiple images
    /// Returns the container ID that can be published later
    func createCarouselContainer(
        instagramAccountId: String,
        imageUrls: [String],
        caption: String,
        accessToken: String
    ) async throws -> String {
        print("📸 Creating carousel with \(imageUrls.count) images...")
        
        // Step 1: Create individual media containers for each image
        var childContainerIds: [String] = []
        
        for (index, imageUrl) in imageUrls.enumerated() {
            print("   Creating container for image \(index + 1)/\(imageUrls.count)...")
            let containerId = try await createCarouselItemContainer(
                instagramAccountId: instagramAccountId,
                imageUrl: imageUrl,
                accessToken: accessToken
            )
            childContainerIds.append(containerId)
        }
        
        // Step 2: Create carousel container with all children
        print("   Creating carousel container with \(childContainerIds.count) children...")
        var components = URLComponents(string: "\(graphAPIBaseURL)/\(instagramAccountId)/media")!
        components.queryItems = [
            URLQueryItem(name: "media_type", value: "CAROUSEL"),
            URLQueryItem(name: "caption", value: caption),
            URLQueryItem(name: "children", value: childContainerIds.joined(separator: ",")),
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(InstagramErrorResponse.self, from: data)
            throw InstagramError.publishFailed(errorResponse?.error.message ?? "Failed to create carousel container")
        }
        
        let containerResponse = try JSONDecoder().decode(MediaContainerResponse.self, from: data)
        print("✅ Carousel container created: \(containerResponse.id)")
        return containerResponse.id
    }
    
    /// Create a single media item container for carousel (without caption)
    private func createCarouselItemContainer(
        instagramAccountId: String,
        imageUrl: String,
        accessToken: String
    ) async throws -> String {
        var components = URLComponents(string: "\(graphAPIBaseURL)/\(instagramAccountId)/media")!
        components.queryItems = [
            URLQueryItem(name: "image_url", value: imageUrl),
            URLQueryItem(name: "is_carousel_item", value: "true"),
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(InstagramErrorResponse.self, from: data)
            throw InstagramError.publishFailed(errorResponse?.error.message ?? "Failed to create carousel item")
        }
        
        let containerResponse = try JSONDecoder().decode(MediaContainerResponse.self, from: data)
        return containerResponse.id
    }
    
    /// Complete workflow: Create carousel and publish (for multiple images)
    func publishCarouselPost(
        instagramAccountId: String,
        imageUrls: [String],
        caption: String,
        accessToken: String
    ) async throws -> PublishResponse {
        print("📸 Creating carousel post with \(imageUrls.count) images...")
        let containerId = try await createCarouselContainer(
            instagramAccountId: instagramAccountId,
            imageUrls: imageUrls,
            caption: caption,
            accessToken: accessToken
        )
        
        print("📸 Publishing carousel...")
        let publishResponse = try await publishMediaContainer(
            instagramAccountId: instagramAccountId,
            creationId: containerId,
            accessToken: accessToken
        )
        
        print("✅ Carousel published successfully: \(publishResponse.id)")
        return publishResponse
    }
    
    /// Complete workflow: Create container, wait for processing, then publish (for videos)
    func publishVideoPost(
        instagramAccountId: String,
        videoUrl: String,
        caption: String,
        accessToken: String
    ) async throws -> PublishResponse {
        print("🎥 Creating media container for video...")
        let containerId = try await createVideoMediaContainer(
            instagramAccountId: instagramAccountId,
            videoUrl: videoUrl,
            caption: caption,
            accessToken: accessToken
        )
        
        print("🎥 Container created: \(containerId), waiting for processing...")
        
        // Poll for container status (videos need processing time)
        var attempts = 0
        let maxAttempts = 30 // 30 attempts = ~5 minutes max
        
        while attempts < maxAttempts {
            let status = try await checkContainerStatus(containerId: containerId, accessToken: accessToken)
            
            switch status {
            case .finished:
                print("🎥 Video processing complete, publishing...")
                let publishResponse = try await publishMediaContainer(
                    instagramAccountId: instagramAccountId,
                    creationId: containerId,
                    accessToken: accessToken
                )
                print("✅ Video published successfully: \(publishResponse.id)")
                return publishResponse
                
            case .error:
                throw InstagramError.publishFailed("Video processing failed")
                
            case .inProgress, .unknown:
                print("⏳ Video still processing... (attempt \(attempts + 1)/\(maxAttempts))")
                try await Task.sleep(nanoseconds: 10_000_000_000) // Wait 10 seconds
                attempts += 1
            }
        }
        
        throw InstagramError.publishFailed("Video processing timeout")
    }
    
    // MARK: - Analytics & Insights
    
    /// Fetch analytics/insights for an Instagram media post
    /// Returns analytics data including impressions, reach, engagement metrics
    func fetchMediaInsights(
        mediaId: String,
        accessToken: String
    ) async throws -> InstagramAnalytics {
        // Request multiple metrics in a single call
        // Note: Starting from v22.0, "impressions" is no longer supported
        // Valid metrics: reach, likes, comments, saved, shares, total_interactions
        let metrics = [
            "reach",
            "likes",
            "comments",
            "saved",  // Note: API uses "saved" not "saves"
            "shares",
            "total_interactions"
        ].joined(separator: ",")
        
        var components = URLComponents(string: "\(graphAPIBaseURL)/\(mediaId)/insights")!
        components.queryItems = [
            URLQueryItem(name: "metric", value: metrics),
            URLQueryItem(name: "access_token", value: accessToken)
        ]
        
        print("🔍 Fetching insights for media: \(mediaId)")
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Insights API Error: \(jsonString)")
            }
            throw InstagramError.analyticsFailed("Failed to fetch insights")
        }
        
        // Parse insights response
        let insightsResponse = try JSONDecoder().decode(InstagramInsightsResponse.self, from: data)
        
        // Extract metrics from response
        var impressions = 0
        var reach = 0
        var likes = 0
        var comments = 0
        var saves = 0
        var shares = 0
        var profileVisits = 0
        var websiteClicks = 0
        
        for insight in insightsResponse.data {
            // Get the latest value (usually the first one, but check all)
            guard let firstValue = insight.values.first else { continue }
            
            // Extract integer value from the insight
            let metricValue: Int
            switch firstValue.value {
            case .int(let value):
                metricValue = value
            case .dict(let dict):
                // Some metrics return a dictionary with breakdowns, sum all values
                metricValue = dict.values.reduce(0, +)
            case .string(let str):
                // Try to parse string as integer
                metricValue = Int(str) ?? 0
            }
            
            switch insight.name {
            case "impressions":
                impressions = metricValue
            case "reach":
                reach = metricValue
            case "likes":
                likes = metricValue
            case "comments":
                comments = metricValue
            case "saved":  // API returns "saved" not "saves"
                saves = metricValue
            case "shares":
                shares = metricValue
            case "total_interactions":
                // Total interactions is a calculated metric, we can use it to verify our sum
                // But we don't store it separately since we calculate engagement from individual metrics
                break
            case "profile_visits":
                profileVisits = metricValue
            case "website_clicks":
                websiteClicks = metricValue
            default:
                break
            }
        }
        
        // Calculate impressions from reach if available, or use 0
        // Note: Impressions not available in v22.0+, using reach as approximation
        let calculatedImpressions = impressions > 0 ? impressions : reach
        
        print("✅ Fetched insights: reach=\(reach), likes=\(likes), comments=\(comments), saved=\(saves), shares=\(shares)")
        
        return InstagramAnalytics(
            id: mediaId,
            postId: "", // Will be set by caller
            impressions: calculatedImpressions, // Use reach as approximation since impressions not available
            reach: reach,
            likes: likes,
            comments: comments,
            saves: saves,
            shares: shares,
            profileVisits: profileVisits,
            websiteClicks: websiteClicks
        )
    }
    
    /// Fetch analytics for multiple media posts in batch
    func fetchMultipleMediaInsights(
        mediaIds: [String],
        accessToken: String
    ) async throws -> [InstagramAnalytics] {
        var analytics: [InstagramAnalytics] = []
        
        // Fetch insights for each media ID
        // Note: Instagram Graph API doesn't support batch insights, so we fetch individually
        // Add small delay to avoid rate limiting
        for (index, mediaId) in mediaIds.enumerated() {
            if index > 0 {
                // Small delay between requests (50ms)
                try await Task.sleep(nanoseconds: 50_000_000)
            }
            
            do {
                let insight = try await fetchMediaInsights(mediaId: mediaId, accessToken: accessToken)
                analytics.append(insight)
            } catch {
                print("⚠️ Failed to fetch insights for media \(mediaId): \(error.localizedDescription)")
                // Continue with other media even if one fails
            }
        }
        
        return analytics
    }
    
    // MARK: - Token Management
    
    /// Refresh an existing long-lived token
    /// This extends the token expiration by another 60 days
    func refreshLongLivedToken(currentToken: String) async throws -> LongLivedTokenResponse {
        var components = URLComponents(string: "\(graphAPIBaseURL)/oauth/access_token")!
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "fb_exchange_token"),
            URLQueryItem(name: "client_id", value: facebookAppId),
            URLQueryItem(name: "client_secret", value: facebookAppSecret),
            URLQueryItem(name: "fb_exchange_token", value: currentToken)
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode(LongLivedTokenResponse.self, from: data)
    }
}

// MARK: - Response Models

struct AccessTokenResponse: Codable {
    let access_token: String
    let token_type: String
}

struct LongLivedTokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int? // seconds until expiration (typically 5184000 = 60 days) - optional because some tokens don't include this
    
    // Default to 60 days if not provided
    var expirationSeconds: Int {
        return expires_in ?? (60 * 24 * 60 * 60) // 60 days in seconds
    }
}

struct PagesResponse: Codable {
    let data: [FacebookPage]
}

struct FacebookPage: Codable, Identifiable {
    let id: String
    let name: String
    let access_token: String
}

struct BusinessesResponse: Codable {
    let data: [Business]
}

struct Business: Codable, Identifiable {
    let id: String
    let name: String
}

struct PageInstagramInfo: Codable {
    let instagram_business_account: InstagramBusinessAccount?
}

struct InstagramBusinessAccount: Codable {
    let id: String
}

struct InstagramAccountDetails: Codable {
    let username: String
}

struct InstagramAccountInfo {
    let id: String
    let username: String
}

struct MediaContainerResponse: Codable {
    let id: String
}

struct ContainerStatusResponse: Codable {
    let status_code: String
}

enum ContainerStatus {
    case finished
    case inProgress
    case error
    case unknown
}

struct PublishResponse: Codable {
    let id: String
}

struct InstagramErrorResponse: Codable {
    let error: InstagramErrorDetail
}

struct InstagramErrorDetail: Codable {
    let message: String
    let type: String
    let code: Int
}

// MARK: - Errors

enum InstagramError: LocalizedError {
    case authenticationFailed
    case noBusinessAccount
    case publishFailed(String)
    case tokenExpired
    case invalidMediaURL
    case analyticsFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Failed to authenticate with Instagram"
        case .noBusinessAccount:
            return "No Instagram Business Account found. Please convert your Instagram account to a Business account and link it to a Facebook Page."
        case .publishFailed(let message):
            return "Failed to publish post: \(message)"
        case .tokenExpired:
            return "Instagram access token has expired. Please reconnect your account."
        case .invalidMediaURL:
            return "Invalid media URL provided"
        case .analyticsFailed(let message):
            return "Failed to fetch analytics: \(message)"
        }
    }
}


