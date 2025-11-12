import Foundation

/// Analytics data for an Instagram post
struct InstagramAnalytics: Identifiable, Codable {
    let id: String // Instagram post ID
    let postId: String // Local post ID from GeneratedPost
    let impressions: Int
    let reach: Int
    let likes: Int
    let comments: Int
    let saves: Int
    let shares: Int
    let profileVisits: Int
    let websiteClicks: Int
    let engagement: Int // Total engagement (likes + comments + saves + shares)
    let engagementRate: Double // Engagement rate as percentage
    let fetchedAt: Date
    
    init(
        id: String,
        postId: String,
        impressions: Int = 0,
        reach: Int = 0,
        likes: Int = 0,
        comments: Int = 0,
        saves: Int = 0,
        shares: Int = 0,
        profileVisits: Int = 0,
        websiteClicks: Int = 0,
        fetchedAt: Date = Date()
    ) {
        self.id = id
        self.postId = postId
        self.impressions = impressions
        self.reach = reach
        self.likes = likes
        self.comments = comments
        self.saves = saves
        self.shares = shares
        self.profileVisits = profileVisits
        self.websiteClicks = websiteClicks
        self.engagement = likes + comments + saves + shares
        // Calculate engagement rate: (engagement / reach) * 100, or (engagement / impressions) * 100 if reach is 0
        let denominator = reach > 0 ? reach : (impressions > 0 ? impressions : 1)
        self.engagementRate = denominator > 0 ? (Double(engagement) / Double(denominator)) * 100.0 : 0.0
        self.fetchedAt = fetchedAt
    }
}

/// Response model for Instagram Graph API insights
struct InstagramInsightsResponse: Codable {
    let data: [InstagramInsightData]
}

struct InstagramInsightData: Codable {
    let name: String
    let period: String?
    let values: [InstagramInsightValue]
    let title: String?
    let description: String?
}

struct InstagramInsightValue: Codable {
    let value: InsightValue
    let end_time: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode value as different types
        if let intValue = try? container.decode(Int.self, forKey: .value) {
            self.value = .int(intValue)
        } else if let stringValue = try? container.decode(String.self, forKey: .value) {
            // Try to parse string as integer
            if let intValue = Int(stringValue) {
                self.value = .int(intValue)
            } else {
                self.value = .string(stringValue)
            }
        } else if let dictValue = try? container.decode([String: Int].self, forKey: .value) {
            self.value = .dict(dictValue)
        } else {
            // Fallback: try to decode as any codable and extract int if possible
            self.value = .int(0)
        }
        
        self.end_time = try? container.decode(String.self, forKey: .end_time)
    }
    
    enum CodingKeys: String, CodingKey {
        case value
        case end_time
    }
}

enum InsightValue: Codable {
    case int(Int)
    case string(String)
    case dict([String: Int])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let dictValue = try? container.decode([String: Int].self) {
            self = .dict(dictValue)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode InsightValue")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .dict(let value):
            try container.encode(value)
        }
    }
    
    var intValue: Int? {
        if case .int(let value) = self {
            return value
        }
        return nil
    }
    
    var dictValue: [String: Int]? {
        if case .dict(let value) = self {
            return value
        }
        return nil
    }
}

