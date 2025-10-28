import Foundation

struct DraftCampaign: Identifiable, Codable {
    let id: String
    var mediaItems: [MediaItem]
    var marketingPlan: MarketingPlan
    var schedule: PostSchedule
    var currentStep: Int
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        mediaItems: [MediaItem] = [],
        marketingPlan: MarketingPlan = MarketingPlan(
            description: "",
            targetAudience: "",
            tone: .casual,
            hashtags: [],
            callToAction: ""
        ),
        schedule: PostSchedule = PostSchedule(),
        currentStep: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.mediaItems = mediaItems
        self.marketingPlan = marketingPlan
        self.schedule = schedule
        self.currentStep = currentStep
        self.updatedAt = updatedAt
    }
}


