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
    
    var client: SupabaseClient {
        return supabase
    }
    
    // MARK: - User ID Helper
    
    private func getCurrentUserId() async throws -> UUID {
        guard let session = try? await supabase.auth.session,
              let userId = UUID(uuidString: session.user.id.uuidString) else {
            print("❌ No authenticated session found")
            throw SupabaseError.notAuthenticated
        }
        print("✅ Current user ID: \(userId.uuidString)")
        return userId
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

// MARK: - Database Operations

extension SupabaseService {
    
    // MARK: - Media Items
    
    func saveMediaItem(_ item: MediaItem) async throws -> MediaItem {
        let userId = try await getCurrentUserId()
        
        let dbMedia = DatabaseMediaItem(
            id: UUID(uuidString: item.id),
            user_id: userId,
            type: item.type.rawValue,
            cloud_url: item.cloudURL,
            created_at: item.createdAt
        )
        
        print("💾 Upserting media item: \(item.id)")
        let response: DatabaseMediaItem = try await supabase
            .from("media_items")
            .upsert(dbMedia)
            .select()
            .single()
            .execute()
            .value
        
        print("✅ Media item upserted successfully")
        return MediaItem(
            id: response.id?.uuidString ?? item.id,
            type: MediaType(rawValue: response.type) ?? .image,
            thumbnail: item.thumbnail,
            localURL: item.localURL,
            cloudURL: response.cloud_url,
            createdAt: response.created_at
        )
    }
    
    func fetchMediaItems() async throws -> [MediaItem] {
        let userId = try await getCurrentUserId()
        
        let response: [DatabaseMediaItem] = try await supabase
            .from("media_items")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response.map { dbItem in
            MediaItem(
                id: dbItem.id?.uuidString ?? UUID().uuidString,
                type: MediaType(rawValue: dbItem.type) ?? .image,
                cloudURL: dbItem.cloud_url,
                createdAt: dbItem.created_at
            )
        }
    }
    
    func deleteMediaItem(_ id: String) async throws {
        try await supabase
            .from("media_items")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Campaigns
    
    func saveCampaign(_ campaign: DraftCampaign) async throws -> DraftCampaign {
        let userId = try await getCurrentUserId()
        let campaignId = UUID(uuidString: campaign.id) ?? UUID()
        
        // Encode arrays and dictionaries to JSON
        let selectedDaysArray = Array(campaign.schedule.selectedDays.map { $0.rawValue })
        let hashtagsArray = campaign.marketingPlan.hashtags
        
        let dbCampaign = DatabaseCampaign(
            id: campaignId,
            user_id: userId,
            marketing_description: campaign.marketingPlan.description,
            target_audience: campaign.marketingPlan.targetAudience,
            tone: campaign.marketingPlan.tone.rawValue,
            hashtags: hashtagsArray,
            call_to_action: campaign.marketingPlan.callToAction,
            schedule_start_date: campaign.schedule.startDate,
            schedule_end_date: campaign.schedule.endDate,
            selected_days: selectedDaysArray,
            post_times: [:], // We'll store this as simplified format
            posts_per_day: campaign.schedule.postsPerDay.mapKeys { $0.rawValue },
            content_guidelines: campaign.schedule.contentGuidelines,
            current_step: campaign.currentStep,
            is_draft: true,
            updated_at: campaign.updatedAt
        )
        
        // Upsert campaign
        let _: DatabaseCampaign = try await supabase
            .from("campaigns")
            .upsert(dbCampaign)
            .execute()
            .value
        
        // Save campaign media items
        try await saveCampaignMediaItems(campaignId: campaignId, mediaItems: campaign.mediaItems)
        
        return campaign
    }
    
    private func saveCampaignMediaItems(campaignId: UUID, mediaItems: [MediaItem]) async throws {
        // First delete existing associations
        try await supabase
            .from("campaign_media_items")
            .delete()
            .eq("campaign_id", value: campaignId.uuidString)
            .execute()
        
        // Insert new associations
        for (index, item) in mediaItems.enumerated() {
            let association = CampaignMediaItemAssociation(
                campaign_id: campaignId,
                media_item_id: UUID(uuidString: item.id) ?? UUID(),
                position: index
            )
            
            try await supabase.database
                .from("campaign_media_items")
                .insert(association)
                .execute()
        }
    }
    
    func fetchCampaigns() async throws -> [DraftCampaign] {
        let userId = try await getCurrentUserId()
        
        let response: [DatabaseCampaign] = try await supabase
            .from("campaigns")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_draft", value: true)
            .order("updated_at", ascending: false)
            .execute()
            .value
        
        var campaigns: [DraftCampaign] = []
        
        for dbCampaign in response {
            let mediaItems = try await fetchCampaignMediaItems(campaignId: dbCampaign.id)
            
            let marketingPlan = MarketingPlan(
                description: dbCampaign.marketing_description,
                targetAudience: dbCampaign.target_audience,
                tone: ContentTone(rawValue: dbCampaign.tone) ?? .casual,
                hashtags: dbCampaign.hashtags,
                callToAction: dbCampaign.call_to_action
            )
            
            let selectedDays = Set(dbCampaign.selected_days.compactMap { WeekDay(rawValue: $0) })
            let postsPerDay: [WeekDay: Int] = Dictionary(uniqueKeysWithValues: 
                dbCampaign.posts_per_day.compactMap { (key, value) -> (WeekDay, Int)? in
                    guard let weekDay = WeekDay(rawValue: key) else { return nil }
                    return (weekDay, value)
                }
            )
            
            let schedule = PostSchedule(
                startDate: dbCampaign.schedule_start_date,
                endDate: dbCampaign.schedule_end_date,
                selectedDays: selectedDays,
                postTimes: [:],
                postsPerDay: postsPerDay,
                contentGuidelines: dbCampaign.content_guidelines
            )
            
            campaigns.append(DraftCampaign(
                id: dbCampaign.id.uuidString,
                mediaItems: mediaItems,
                marketingPlan: marketingPlan,
                schedule: schedule,
                currentStep: dbCampaign.current_step,
                updatedAt: dbCampaign.updated_at
            ))
        }
        
        return campaigns
    }
    
    private func fetchCampaignMediaItems(campaignId: UUID) async throws -> [MediaItem] {
        let associations: [CampaignMediaItemAssociation] = try await supabase
            .from("campaign_media_items")
            .select()
            .eq("campaign_id", value: campaignId.uuidString)
            .order("position", ascending: true)
            .execute()
            .value
        
        var mediaItems: [MediaItem] = []
        for association in associations {
            if let dbMedia: DatabaseMediaItem = try? await supabase.database
                .from("media_items")
                .select()
                .eq("id", value: association.media_item_id.uuidString)
                .single()
                .execute()
                .value {
                
                mediaItems.append(MediaItem(
                    id: dbMedia.id?.uuidString ?? UUID().uuidString,
                    type: MediaType(rawValue: dbMedia.type) ?? .image,
                    cloudURL: dbMedia.cloud_url,
                    createdAt: dbMedia.created_at
                ))
            }
        }
        
        return mediaItems
    }
    
    func deleteCampaign(_ id: String) async throws {
        try await supabase
            .from("campaigns")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Generated Posts
    
    func saveGeneratedPost(_ post: GeneratedPost, campaignId: String?) async throws -> GeneratedPost {
        let userId = try await getCurrentUserId()
        
        let dbPost = DatabaseGeneratedPost(
            id: UUID(uuidString: post.id) ?? UUID(),
            user_id: userId,
            campaign_id: campaignId != nil ? UUID(uuidString: campaignId!) : nil,
            media_item_id: UUID(uuidString: post.mediaItemId),
            caption: post.caption,
            scheduled_date: post.scheduledDate,
            status: post.status.rawValue,
            created_at: post.createdAt,
            updated_at: Date()
        )
        
        print("💾 Upserting post: \(post.id) with status: \(post.status.rawValue)")
        
        do {
            let response: DatabaseGeneratedPost = try await supabase
                .from("generated_posts")
                .upsert(dbPost)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Post upserted successfully")
            
            return GeneratedPost(
                id: response.id.uuidString,
                caption: response.caption,
                mediaItemId: response.media_item_id?.uuidString ?? post.mediaItemId,
                scheduledDate: response.scheduled_date,
                status: PostStatus(rawValue: response.status) ?? .pending,
                createdAt: response.created_at
            )
        } catch {
            print("❌ Failed to upsert post: \(error)")
            print("   Post ID: \(post.id)")
            print("   Status: \(post.status.rawValue)")
            print("   Media Item ID: \(post.mediaItemId)")
            throw error
        }
    }
    
    func saveGeneratedPosts(_ posts: [GeneratedPost], campaignId: String?) async throws {
        print("💾 Saving \(posts.count) posts to database...")
        for post in posts {
            _ = try await saveGeneratedPost(post, campaignId: campaignId)
        }
        print("✅ All posts saved successfully")
    }
    
    func fetchGeneratedPosts(status: PostStatus? = nil) async throws -> [GeneratedPost] {
        let userId = try await getCurrentUserId()
        
        print("🔍 Fetching posts for user: \(userId.uuidString)")
        
        var query = supabase
            .from("generated_posts")
            .select()
            .eq("user_id", value: userId.uuidString)
        
        if let status = status {
            query = query.eq("status", value: status.rawValue)
            print("🔍 Filtering by status: \(status.rawValue)")
        }
        
        let response: [DatabaseGeneratedPost] = try await query
            .order("scheduled_date", ascending: true)
            .execute()
            .value
        
        print("✅ Fetched \(response.count) posts from database")
        
        return response.map { dbPost in
            GeneratedPost(
                id: dbPost.id.uuidString,
                caption: dbPost.caption,
                mediaItemId: dbPost.media_item_id?.uuidString ?? "",
                scheduledDate: dbPost.scheduled_date,
                status: PostStatus(rawValue: dbPost.status) ?? .pending,
                createdAt: dbPost.created_at
            )
        }
    }
    
    func updatePostStatus(_ postId: String, status: PostStatus) async throws {
        try await supabase
            .from("generated_posts")
            .update(["status": status.rawValue, "updated_at": Date().ISO8601Format()])
            .eq("id", value: postId)
            .execute()
    }
    
    func deleteGeneratedPost(_ id: String) async throws {
        try await supabase
            .from("generated_posts")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Media Upload/Download
    
    func uploadMedia(data: Data, fileName: String, contentType: String) async throws -> String {
        let userId = try await getCurrentUserId()
        let userIdString = userId.uuidString.lowercased()  // Use lowercase to match PostgreSQL
        let filePath = "\(userIdString)/\(fileName)"
        
        print("☁️ Attempting storage upload:")
        print("   - User ID: \(userIdString)")
        print("   - File path: \(filePath)")
        print("   - Content type: \(contentType)")
        print("   - File size: \(data.count) bytes")
        
        do {
            try await supabase.storage
                .from("media-uploads")
                .upload(
                    path: filePath,
                    file: data,
                    options: FileOptions(contentType: contentType)
                )
            
            print("✅ Storage upload successful")
            
            // Get public URL
            let publicURL = try supabase.storage
                .from("media-uploads")
                .getPublicURL(path: filePath)
            
            print("   - Public URL: \(publicURL.absoluteString)")
            return publicURL.absoluteString
        } catch {
            print("❌ Storage upload failed: \(error)")
            print("   - Error type: \(type(of: error))")
            print("   - Error description: \(error.localizedDescription)")
            throw SupabaseError.uploadFailed
        }
    }
    
    func downloadMedia(url: String) async throws -> Data {
        // Extract file path from URL
        guard let urlComponents = URLComponents(string: url),
              let path = urlComponents.path.components(separatedBy: "/media-uploads/").last else {
            throw SupabaseError.invalidURL
        }
        
        let data = try await supabase.storage
            .from("media-uploads")
            .download(path: path)
        
        return data
    }
}

// MARK: - Database Models

struct DatabaseMediaItem: Codable {
    let id: UUID?
    let user_id: UUID
    let type: String
    let cloud_url: String?
    let created_at: Date
}

struct DatabaseCampaign: Codable {
    let id: UUID
    let user_id: UUID
    let marketing_description: String
    let target_audience: String
    let tone: String
    let hashtags: [String]
    let call_to_action: String
    let schedule_start_date: Date?
    let schedule_end_date: Date?
    let selected_days: [Int]
    let post_times: [String: [String]]
    let posts_per_day: [Int: Int]
    let content_guidelines: String
    let current_step: Int
    let is_draft: Bool
    let updated_at: Date
}

struct CampaignMediaItemAssociation: Codable {
    let campaign_id: UUID
    let media_item_id: UUID
    let position: Int
}

struct DatabaseGeneratedPost: Codable {
    let id: UUID
    let user_id: UUID
    let campaign_id: UUID?
    let media_item_id: UUID?
    let caption: String
    let scheduled_date: Date
    let status: String
    let created_at: Date
    let updated_at: Date
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case uploadFailed
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .invalidURL:
            return "Invalid URL provided"
        case .uploadFailed:
            return "Failed to upload media"
        case .downloadFailed:
            return "Failed to download media"
        }
    }
}

// MARK: - Helper Extensions

extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        return Dictionary<T, Value>(uniqueKeysWithValues: self.map { (transform($0.key), $0.value) })
    }
}
