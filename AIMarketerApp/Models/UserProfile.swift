import Foundation

struct UserProfile: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var onboardingCompleted: Bool
    var businessCategory: String?
    var websiteUrl: String?
    var businessSummary: String?
    var businessValueProposition: String?
    var businessDescription: String?
    var brandColors: [String]
    var logoUrl: String?
    var brandImages: [String]
    var websiteAnalyzedAt: Date?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case onboardingCompleted = "onboarding_completed"
        case businessCategory = "business_category"
        case websiteUrl = "website_url"
        case businessSummary = "business_summary"
        case businessValueProposition = "business_value_proposition"
        case businessDescription = "business_description"
        case brandColors = "brand_colors"
        case logoUrl = "logo_url"
        case brandImages = "brand_images"
        case websiteAnalyzedAt = "website_analyzed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        onboardingCompleted: Bool = false,
        businessCategory: String? = nil,
        websiteUrl: String? = nil,
        businessSummary: String? = nil,
        businessValueProposition: String? = nil,
        businessDescription: String? = nil,
        brandColors: [String] = [],
        logoUrl: String? = nil,
        brandImages: [String] = [],
        websiteAnalyzedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.onboardingCompleted = onboardingCompleted
        self.businessCategory = businessCategory
        self.websiteUrl = websiteUrl
        self.businessSummary = businessSummary
        self.businessValueProposition = businessValueProposition
        self.businessDescription = businessDescription
        self.brandColors = brandColors
        self.logoUrl = logoUrl
        self.brandImages = brandImages
        self.websiteAnalyzedAt = websiteAnalyzedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct BusinessAnalysisResult: Codable {
    var summary: String
    var valueProposition: String
    var description: String
    var colors: [String]
    var logoUrl: String?
    var images: [String]
}

