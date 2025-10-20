import Foundation

class ContentGenerationService {
    static let shared = ContentGenerationService()
    
    private init() {}
    
    // Mock content generation - replace with real OpenAI API calls via backend
    func generatePosts(
        mediaItems: [MediaItem],
        marketingPlan: MarketingPlan,
        schedule: PostSchedule
    ) async throws -> [GeneratedPost] {
        // Simulate network delay for AI processing
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        var posts: [GeneratedPost] = []
        let numberOfPosts = schedule.postsPerWeek * 4 // 4 weeks worth
        
        // Generate mock posts
        for i in 0..<numberOfPosts {
            let mediaItem = mediaItems[i % mediaItems.count]
            let caption = generateMockCaption(
                index: i,
                marketingPlan: marketingPlan,
                tone: marketingPlan.tone
            )
            
            // Calculate scheduled date based on selected days
            let scheduledDate = calculateScheduledDate(
                for: i,
                schedule: schedule
            )
            
            let post = GeneratedPost(
                caption: caption,
                mediaItemId: mediaItem.id,
                scheduledDate: scheduledDate,
                status: .pending
            )
            
            posts.append(post)
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
    
    private func calculateScheduledDate(for index: Int, schedule: PostSchedule) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        let sortedDays = schedule.selectedDays.sorted { $0.rawValue < $1.rawValue }
        guard !sortedDays.isEmpty else {
            return calendar.date(byAdding: .day, value: index, to: today) ?? today
        }
        
        let weekNumber = index / sortedDays.count
        let dayIndex = index % sortedDays.count
        let weekDay = sortedDays[dayIndex]
        
        // Calculate the date
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: today)
        let currentWeekday = components.weekday ?? 1
        
        var daysToAdd = (weekDay.rawValue - currentWeekday + 7) % 7
        if daysToAdd == 0 && index > 0 {
            daysToAdd = 7
        }
        daysToAdd += (weekNumber * 7)
        
        guard var scheduledDate = calendar.date(byAdding: .day, value: daysToAdd, to: today) else {
            return today
        }
        
        // Add time if specified
        if let times = schedule.postTimes[weekDay], !times.isEmpty {
            let time = times[0]
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            scheduledDate = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: scheduledDate) ?? scheduledDate
        }
        
        return scheduledDate
    }
}

