import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    private let supabase: SupabaseClient
    
    private init() {
        // Load configuration from Config.plist
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let configData = NSDictionary(contentsOfFile: configPath),
              let supabaseURL = configData["SupabaseURL"] as? String,
              let supabaseKey = configData["SupabaseKey"] as? String else {
            fatalError("Config.plist not found or missing required keys. Please copy Config.template.plist to Config.plist and fill in your credentials.")
        }
        
        supabase = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
    }
    
    // MARK: - AI Content Generation
    
    func generateCaptions(
        mediaItems: [MediaItem],
        marketingPlan: MarketingPlan,
        schedule: PostSchedule
    ) async throws -> [GeneratedPost] {
        let request = CaptionGenerationRequest(
            mediaItems: mediaItems.map { MediaItemRequest(
                id: $0.id,
                type: $0.type.rawValue,
                description: "" // We'll add image analysis later
            )},
            marketingPlan: MarketingPlanRequest(
                description: marketingPlan.description,
                targetAudience: marketingPlan.targetAudience,
                tone: marketingPlan.tone.rawValue,
                hashtags: marketingPlan.hashtags,
                callToAction: marketingPlan.callToAction
            ),
            schedule: PostScheduleRequest(
                startDate: schedule.startDate?.ISO8601Format(),
                endDate: schedule.endDate?.ISO8601Format(),
                selectedDays: Array(schedule.selectedDays).map { $0.rawValue },
                postsPerDay: Dictionary(uniqueKeysWithValues: schedule.postsPerDay.map { ($0.key.rawValue, $0.value) }),
                contentGuidelines: schedule.contentGuidelines
            )
        )
        
        let response: CaptionGenerationResponse = try await supabase.functions
            .invoke("generate-captions", options: FunctionInvokeOptions(body: request))
        
        // Apply the original scheduling logic to the AI-generated captions
        return applySchedulingToAIPosts(
            aiPosts: response.posts,
            mediaItems: mediaItems,
            schedule: schedule
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func applySchedulingToAIPosts(
        aiPosts: [GeneratedPostResponse],
        mediaItems: [MediaItem],
        schedule: PostSchedule
    ) -> [GeneratedPost] {
        var posts: [GeneratedPost] = []
        
        // Use the original scheduling logic from ContentGenerationService
        guard let startDate = schedule.startDate, let endDate = schedule.endDate else {
            return []
        }
        
        let calendar = Calendar.current
        var currentDate = startDate
        var aiPostIndex = 0
        
        // Iterate through each day in the range
        while currentDate <= endDate {
            let weekdayComponent = calendar.component(.weekday, from: currentDate)
            
            // Check if this day is in the selected days
            if let weekDay = WeekDay.from(calendarWeekday: weekdayComponent),
               schedule.selectedDays.contains(weekDay) {
                
                // Get number of posts for this day
                let postsForThisDay = schedule.postsPerDay[weekDay] ?? 1
                let times = schedule.postTimes[weekDay] ?? []
                
                // Generate posts for this day using AI captions
                for postIndex in 0..<postsForThisDay {
                    guard aiPostIndex < aiPosts.count else { break }
                    
                    let aiPost = aiPosts[aiPostIndex]
                    _ = mediaItems[aiPostIndex % mediaItems.count]
                    
                    // Set the scheduled time
                    var scheduledDate = currentDate
                    if postIndex < times.count {
                        let time = times[postIndex]
                        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                        scheduledDate = calendar.date(bySettingHour: timeComponents.hour ?? 9,
                                                    minute: timeComponents.minute ?? 0,
                                                    second: 0,
                                                    of: currentDate) ?? currentDate
                    } else {
                        // Default time: 9 AM + offset
                        scheduledDate = calendar.date(bySettingHour: 9 + postIndex * 2,
                                                    minute: 0,
                                                    second: 0,
                                                    of: currentDate) ?? currentDate
                    }
                    
                    posts.append(GeneratedPost(
                        id: aiPost.id,
                        caption: aiPost.caption,
                        mediaItemId: aiPost.mediaItemId,
                        scheduledDate: scheduledDate,
                        status: .pending
                    ))
                    
                    aiPostIndex += 1
                }
            }
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return posts
    }
}

// MARK: - Request/Response Models

struct CaptionGenerationRequest: Codable {
    let mediaItems: [MediaItemRequest]
    let marketingPlan: MarketingPlanRequest
    let schedule: PostScheduleRequest
}

struct MediaItemRequest: Codable {
    let id: String
    let type: String
    let description: String
}

struct MarketingPlanRequest: Codable {
    let description: String
    let targetAudience: String
    let tone: String
    let hashtags: [String]
    let callToAction: String
}

struct PostScheduleRequest: Codable {
    let startDate: String?
    let endDate: String?
    let selectedDays: [Int]
    let postsPerDay: [Int: Int]
    let contentGuidelines: String
}

struct CaptionGenerationResponse: Codable {
    let posts: [GeneratedPostResponse]
}

struct GeneratedPostResponse: Codable {
    let id: String
    let caption: String
    let mediaItemId: String
    let scheduledDate: String
}
