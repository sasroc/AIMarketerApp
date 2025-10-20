import Foundation

struct MarketingPlan: Codable {
    var description: String
    var targetAudience: String
    var tone: ContentTone
    var hashtags: [String]
    var callToAction: String
    
    init(description: String = "", targetAudience: String = "", tone: ContentTone = .casual, hashtags: [String] = [], callToAction: String = "") {
        self.description = description
        self.targetAudience = targetAudience
        self.tone = tone
        self.hashtags = hashtags
        self.callToAction = callToAction
    }
}

enum ContentTone: String, Codable, CaseIterable {
    case professional = "Professional"
    case casual = "Casual"
    case energetic = "Energetic"
    case friendly = "Friendly"
    case inspirational = "Inspirational"
    
    var icon: String {
        switch self {
        case .professional: return "briefcase.fill"
        case .casual: return "person.fill"
        case .energetic: return "bolt.fill"
        case .friendly: return "heart.fill"
        case .inspirational: return "sparkles"
        }
    }
}

