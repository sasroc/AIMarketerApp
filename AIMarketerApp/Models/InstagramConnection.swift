import Foundation

struct InstagramConnection: Identifiable, Codable {
    let id: String
    let userId: String
    let instagramUserId: String
    var instagramUsername: String
    let facebookPageId: String
    var facebookPageName: String?
    var accessToken: String
    var tokenExpiresAt: Date
    var isConnected: Bool
    var lastTokenRefresh: Date
    let connectedAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case instagramUserId = "instagram_user_id"
        case instagramUsername = "instagram_username"
        case facebookPageId = "facebook_page_id"
        case facebookPageName = "facebook_page_name"
        case accessToken = "access_token"
        case tokenExpiresAt = "token_expires_at"
        case isConnected = "is_connected"
        case lastTokenRefresh = "last_token_refresh"
        case connectedAt = "connected_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        instagramUserId: String,
        instagramUsername: String,
        facebookPageId: String,
        facebookPageName: String? = nil,
        accessToken: String,
        tokenExpiresAt: Date,
        isConnected: Bool = true,
        lastTokenRefresh: Date = Date(),
        connectedAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.instagramUserId = instagramUserId
        self.instagramUsername = instagramUsername
        self.facebookPageId = facebookPageId
        self.facebookPageName = facebookPageName
        self.accessToken = accessToken
        self.tokenExpiresAt = tokenExpiresAt
        self.isConnected = isConnected
        self.lastTokenRefresh = lastTokenRefresh
        self.connectedAt = connectedAt
        self.updatedAt = updatedAt
    }
    
    var needsTokenRefresh: Bool {
        // Refresh if token expires in less than 7 days
        let sevenDaysFromNow = Date().addingTimeInterval(7 * 24 * 60 * 60)
        return tokenExpiresAt < sevenDaysFromNow
    }
}


