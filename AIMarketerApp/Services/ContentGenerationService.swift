import Foundation

class ContentGenerationService {
    static let shared = ContentGenerationService()
    
    private let supabaseService = SupabaseService.shared
    
    private init() {}
    
    // AI-powered content generation using Supabase Edge Functions
    func generatePosts(
        mediaItems: [MediaItem],
        marketingPlan: MarketingPlan,
        schedule: PostSchedule
    ) async throws -> [GeneratedPost] {
        do {
            // Use Supabase service to generate AI-powered captions
            let posts = try await supabaseService.generateCaptions(
                mediaItems: mediaItems,
                marketingPlan: marketingPlan,
                schedule: schedule
            )
            
            // Apply custom scheduling times if specified
            return applyCustomSchedulingTimes(posts: posts, schedule: schedule)
            
        } catch {
            // Fallback to mock generation if AI service fails
            print("AI generation failed, falling back to mock: \(error)")
            return try await generateMockPosts(
                mediaItems: mediaItems,
                marketingPlan: marketingPlan,
                schedule: schedule
            )
        }
    }
    
    private func applyCustomSchedulingTimes(posts: [GeneratedPost], schedule: PostSchedule) -> [GeneratedPost] {
        let calendar = Calendar.current
        var updatedPosts: [GeneratedPost] = []
        
        for post in posts {
            let weekdayComponent = calendar.component(.weekday, from: post.scheduledDate)
            
            if let weekDay = WeekDay.from(calendarWeekday: weekdayComponent),
               let times = schedule.postTimes[weekDay], !times.isEmpty {
                
                // Find the appropriate time for this post
                let dayStart = calendar.startOfDay(for: post.scheduledDate)
                let postIndex = updatedPosts.filter { 
                    calendar.isDate($0.scheduledDate, inSameDayAs: post.scheduledDate) 
                }.count
                
                var scheduledDate = post.scheduledDate
                if postIndex < times.count {
                    let time = times[postIndex]
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    scheduledDate = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: dayStart) ?? post.scheduledDate
                } else {
                    // Use last available time + offset
                    let lastTime = times.last!
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: lastTime)
                    scheduledDate = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: dayStart) ?? post.scheduledDate
                    scheduledDate = calendar.date(byAdding: .hour, value: (postIndex - times.count + 1) * 2, to: scheduledDate) ?? scheduledDate
                }
                
                let updatedPost = GeneratedPost(
                    id: post.id,
                    caption: post.caption,
                    mediaItemIds: post.mediaItemIds,
                    scheduledDate: scheduledDate,
                    status: post.status,
                    createdAt: post.createdAt
                )
                updatedPosts.append(updatedPost)
            } else {
                updatedPosts.append(post)
            }
        }
        
        return updatedPosts
    }
    
    // Fallback mock generation (keeping original logic as backup)
    private func generateMockPosts(
        mediaItems: [MediaItem],
        marketingPlan: MarketingPlan,
        schedule: PostSchedule
    ) async throws -> [GeneratedPost] {
        // Simulate network delay for AI processing
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        var posts: [GeneratedPost] = []
        
        // Calculate total number of posts based on date range, days, and posts per day
        guard let startDate = schedule.startDate, let endDate = schedule.endDate else {
            return []
        }
        
        let calendar = Calendar.current
        var currentDate = startDate
        var mediaIndex = 0
        
        // Iterate through each day in the range
        while currentDate <= endDate {
            let weekdayComponent = calendar.component(.weekday, from: currentDate)
            
            // Check if this day is in the selected days
            if let weekDay = WeekDay.from(calendarWeekday: weekdayComponent),
               schedule.selectedDays.contains(weekDay) {
                
                // Get number of posts for this day
                let postsForThisDay = schedule.postsPerDay[weekDay] ?? 1
                let times = schedule.postTimes[weekDay] ?? []
                
                // Generate posts for this day
                for postIndex in 0..<postsForThisDay {
                    // Collect media items for this post based on imagesPerPost setting
                    let imagesPerPost = schedule.imagesPerPost
                    var mediaItemIds: [String] = []
                    
                    for _ in 0..<imagesPerPost {
                        let mediaItem = mediaItems[mediaIndex % mediaItems.count]
                        mediaItemIds.append(mediaItem.id)
                        mediaIndex += 1
                    }
                    
                    let caption = generateMockCaption(
                        index: postIndex,
                        marketingPlan: marketingPlan,
                        tone: marketingPlan.tone
                    )
                    
                    // Set the scheduled time
                    var scheduledDate = currentDate
                    if postIndex < times.count {
                        let time = times[postIndex]
                        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                        scheduledDate = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: currentDate) ?? currentDate
                    } else if !times.isEmpty {
                        // Fallback: use first time + offset
                        let time = times[0]
                        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                        scheduledDate = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: currentDate) ?? currentDate
                        scheduledDate = calendar.date(byAdding: .hour, value: postIndex * 2, to: scheduledDate) ?? scheduledDate
                    } else {
                        // Default time: 9 AM + offset
                        scheduledDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: currentDate) ?? currentDate
                        scheduledDate = calendar.date(byAdding: .hour, value: postIndex * 2, to: scheduledDate) ?? scheduledDate
                    }
                    
                    let post = GeneratedPost(
                        caption: caption,
                        mediaItemIds: mediaItemIds,
                        scheduledDate: scheduledDate,
                        status: .pending
                    )
                    
                    posts.append(post)
                }
            }
            
            // Move to next day
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return posts
    }
    
    private func generateMockCaption(index: Int, marketingPlan: MarketingPlan, tone: ContentTone) -> String {
        let emojis = ["✨", "🚀", "💡", "🎯", "💪", "🌟", "🔥", "💼", "📱", "🎨"]
        let randomEmoji = emojis.randomElement() ?? "✨"
        
        let baseCaption = marketingPlan.description.isEmpty
            ? "Exciting update coming your way!"
            : String(marketingPlan.description.prefix(80))
        
        let hashtags = marketingPlan.hashtags.isEmpty
            ? ["#marketing", "#socialmedia", "#contentcreation"]
            : marketingPlan.hashtags
        
        let hashtagString = hashtags.prefix(5).map { $0.hasPrefix("#") ? $0 : "#\($0)" }.joined(separator: " ")
        
        var caption = "\(randomEmoji) \(baseCaption)\n\n"
        
        if !marketingPlan.callToAction.isEmpty {
            caption += "\(marketingPlan.callToAction)\n\n"
        }
        
        caption += hashtagString
        
        return caption
    }
    
}

