import Foundation
import SwiftUI
import Supabase
import UIKit

@MainActor
class AutoGenerateViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var currentStep: GenerationStep = .loadingProfile
    @Published var progressMessage = "Loading your business information..."
    @Published var errorMessage: String?
    @Published var generatedPosts: [GeneratedPost] = []
    
    // Track completed steps explicitly to prevent resets
    @Published var completedSteps: Set<GenerationStep> = []
    
    private let userProfileService = UserProfileService.shared
    private let imageService = AIImageGenerationService.shared
    private let contentService = ContentGenerationService.shared
    private let supabaseService = SupabaseService.shared
    
    enum GenerationStep: Hashable {
        case loadingProfile
        case generatingImages
        case generatingCaptions
        case saving
        case completed
    }
    
    func generateWeekOfPosts() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            completedSteps = []
            currentStep = .loadingProfile
            progressMessage = "Loading your business information..."
        }
        
        do {
            // Step 1: Fetch user profile
            await MainActor.run {
                currentStep = .loadingProfile
                progressMessage = "Loading your business information..."
            }
            
            guard let profile = try await userProfileService.fetchUserProfile() else {
                throw AutoGenerateError.noProfileData
            }
            
            guard let businessSummary = profile.businessSummary,
                  !businessSummary.isEmpty else {
                throw AutoGenerateError.insufficientData
            }
            
            // Mark loading profile as complete
            await MainActor.run {
                completedSteps.insert(.loadingProfile)
            }
            
            // Step 2: Create marketing plan from business data
            let marketingPlan = createMarketingPlan(from: profile)
            
            // Step 3: Create schedule for one week
            let schedule = createWeekSchedule()
            
            // Step 4: Generate images
            await MainActor.run {
                currentStep = .generatingImages
                progressMessage = "Generating images for your posts..."
            }
            // For testing: Generate 1 post per day (1 image)
            // TODO: Change back to 7 for full week generation
            let mediaItems = try await generateImages(profile: profile, count: 1)
            
            // Mark generating images as complete
            await MainActor.run {
                completedSteps.insert(.generatingImages)
            }
            
            // Step 5: Generate captions
            await MainActor.run {
                currentStep = .generatingCaptions
                progressMessage = "Creating captions for your posts..."
            }
            let posts = try await contentService.generatePosts(
                mediaItems: mediaItems,
                marketingPlan: marketingPlan,
                schedule: schedule
            )
            
            // Mark generating captions as complete
            await MainActor.run {
                completedSteps.insert(.generatingCaptions)
                generatedPosts = posts
            }
            
            // Step 6: Save to database
            await MainActor.run {
                currentStep = .saving
                progressMessage = "Saving your posts..."
            }
            try await supabaseService.saveGeneratedPosts(posts, campaignId: nil)
            
            // Mark saving as complete
            await MainActor.run {
                completedSteps.insert(.saving)
                currentStep = .completed
                completedSteps.insert(.completed)
                progressMessage = "All done! Generated \(posts.count) post for today." // Testing: 1 day
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            print("❌ Auto generation error: \(error)")
        }
    }
    
    private func createMarketingPlan(from profile: UserProfile) -> MarketingPlan {
        let description = profile.businessSummary ?? profile.businessDescription ?? "Social media content"
        let targetAudience = inferTargetAudience(from: profile.businessCategory)
        let tone = ContentTone.friendly // Default, could be made configurable
        
        // Generate hashtags based on business category
        let hashtags = generateHashtags(for: profile.businessCategory)
        
        let callToAction = profile.businessValueProposition ?? "Learn more"
        
        return MarketingPlan(
            description: description,
            targetAudience: targetAudience,
            tone: tone,
            hashtags: hashtags,
            callToAction: callToAction
        )
    }
    
    private func createWeekSchedule() -> PostSchedule {
        let calendar = Calendar.current
        let now = Date()
        
        // For testing: Start from tomorrow, end same day (1 day only)
        guard let startDate = calendar.date(byAdding: .day, value: 1, to: now) else {
            return PostSchedule()
        }
        
        // End same day at end of day (1 day schedule for testing)
        let startOfDay = calendar.startOfDay(for: startDate)
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return PostSchedule()
        }
        
        // Get the weekday for tomorrow
        let weekdayComponent = calendar.component(.weekday, from: startDate)
        guard let weekDay = WeekDay.from(calendarWeekday: weekdayComponent) else {
            return PostSchedule()
        }
        
        // Select only tomorrow's day (1 day for testing)
        let selectedDays: Set<WeekDay> = [weekDay]
        
        // Default: 1 post at 9 AM
        var postsPerDay: [WeekDay: Int] = [:]
        var postTimes: [WeekDay: [Date]] = [:]
        
        postsPerDay[weekDay] = 1
        
        // Set default time to 9 AM
        if let date = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: startDate) {
            postTimes[weekDay] = [date]
        }
        
        let contentGuidelines = "Create engaging, authentic content that reflects our brand values and resonates with our audience."
        
        return PostSchedule(
            startDate: startDate,
            endDate: endDate,
            selectedDays: selectedDays,
            postTimes: postTimes,
            postsPerDay: postsPerDay,
            contentGuidelines: contentGuidelines,
            imagesPerPost: 1
        )
    }
    
    private func generateImages(profile: UserProfile, count: Int) async throws -> [MediaItem] {
        // Ensure we're still on generatingImages step
        await MainActor.run {
            currentStep = .generatingImages
        }
        
        var mediaItems: [MediaItem] = []
        
        // Create image prompts based on business data
        let prompts = generateImagePrompts(profile: profile, count: count)
        
        for (index, prompt) in prompts.enumerated() {
            await MainActor.run {
                currentStep = .generatingImages // Keep step consistent
                progressMessage = "Generating image \(index + 1) of \(count)..."
            }
            
            do {
                print("🖼️ Generating image \(index + 1) with prompt: \(prompt)")
                let result = try await imageService.generateImage(
                    prompt: prompt,
                    size: .square
                )
                
                print("✅ Image \(index + 1) generated successfully")
                
                // Upload image to Supabase storage
                let mediaItem = try await uploadImageToStorage(
                    image: result.image,
                    imageData: result.imageData,
                    index: index
                )
                
                mediaItems.append(mediaItem)
            } catch {
                print("⚠️ Failed to generate image \(index + 1): \(error)")
                print("⚠️ Error details: \(error.localizedDescription)")
                if let httpError = error as? any Error {
                    print("⚠️ Full error: \(String(describing: httpError))")
                }
                // Continue with other images even if one fails
            }
        }
        
        if mediaItems.isEmpty {
            throw AutoGenerateError.imageGenerationFailed
        }
        
        return mediaItems
    }
    
    private func generateImagePrompts(profile: UserProfile, count: Int) -> [String] {
        var prompts: [String] = []
        
        // Get business category or use default
        let businessCategory = profile.businessCategory ?? "business"
        
        // Simplify brand colors - only use first 2-3 colors and keep it short
        let brandColorsText: String
        if !profile.brandColors.isEmpty {
            let colors = Array(profile.brandColors.prefix(2))
            brandColorsText = "Brand colors: \(colors.joined(separator: ", ")). "
        } else {
            brandColorsText = ""
        }
        
        // Create simpler, more focused prompts
        // DALL-E 3 works best with concise, descriptive prompts
        let variations = [
            "Professional social media post for \(businessCategory) business. Modern, clean design with vibrant colors. Instagram-ready graphic.",
            "Engaging social media content for \(businessCategory). Professional photography style, bright and appealing. Perfect for Instagram feed.",
            "Eye-catching social media post showcasing \(businessCategory) services. Modern design, professional quality, Instagram-optimized.",
            "Creative social media graphic for \(businessCategory) brand. Contemporary style, high-quality visual, Instagram-friendly format.",
            "Attractive social media content featuring \(businessCategory) business. Professional design, vibrant colors, optimized for Instagram.",
            "Modern social media post design for \(businessCategory). Clean layout, professional aesthetic, perfect for Instagram.",
            "Engaging visual content for \(businessCategory) marketing. High-quality design, Instagram-ready format, professional style."
        ]
        
        // Use variations, repeating if needed
        for i in 0..<count {
            var prompt = variations[i % variations.count]
            
            // Add brand colors if available (keep it short)
            if !brandColorsText.isEmpty {
                prompt = prompt.replacingOccurrences(of: "vibrant colors", with: brandColorsText + "vibrant colors")
            }
            
            // Ensure prompt is not too long (DALL-E 3 max is 4000 chars, but shorter is better)
            if prompt.count > 500 {
                prompt = String(prompt.prefix(500))
            }
            
            prompts.append(prompt)
        }
        
        return prompts
    }
    
    private func uploadImageToStorage(image: UIImage, imageData: Data, index: Int) async throws -> MediaItem {
        // Convert UIImage to JPEG for better compatibility
        guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw AutoGenerateError.imageGenerationFailed
        }
        
        let fileName = "auto-generated-\(UUID().uuidString).jpg"
        
        // Upload to Supabase Storage using the service method
        let cloudURL = try await supabaseService.uploadMedia(
            data: jpegData,
            fileName: fileName,
            contentType: "image/jpeg"
        )
        
        // Create thumbnail
        let thumbnail = image.resize(to: CGSize(width: 300, height: 300))
        
        // Save to media_items table
        let mediaItem = MediaItem(
            id: UUID().uuidString,
            type: .image,
            thumbnail: thumbnail,
            cloudURL: cloudURL,
            createdAt: Date()
        )
        
        let savedItem = try await supabaseService.saveMediaItem(mediaItem)
        return savedItem
    }
    
    private func getCurrentUserId() async throws -> UUID {
        guard let session = try? await supabaseService.client.auth.session,
              let userId = UUID(uuidString: session.user.id.uuidString) else {
            throw AutoGenerateError.notAuthenticated
        }
        return userId
    }
    
    private func inferTargetAudience(from category: String?) -> String {
        guard let category = category else {
            return "General audience"
        }
        
        // Map business categories to target audiences
        let audienceMap: [String: String] = [
            "Restaurant & Food": "Food enthusiasts and local diners",
            "Fashion & Apparel": "Fashion-conscious individuals",
            "Fitness & Wellness": "Health and fitness enthusiasts",
            "Beauty & Cosmetics": "Beauty and skincare enthusiasts",
            "Technology": "Tech-savvy professionals",
            "Real Estate": "Home buyers and investors",
            "Education": "Students and lifelong learners",
            "Healthcare": "Health-conscious individuals",
            "Retail & E-commerce": "Online shoppers",
            "Entertainment": "Entertainment seekers",
            "Travel & Tourism": "Travel enthusiasts",
            "Professional Services": "Business professionals",
            "Home & Garden": "Homeowners and DIY enthusiasts",
            "Automotive": "Car enthusiasts",
            "Sports & Recreation": "Sports and recreation enthusiasts"
        ]
        
        return audienceMap[category] ?? "General audience interested in \(category.lowercased())"
    }
    
    private func generateHashtags(for category: String?) -> [String] {
        guard let category = category else {
            return ["business", "marketing", "socialmedia"]
        }
        
        // Generate relevant hashtags based on category
        let hashtagMap: [String: [String]] = [
            "Restaurant & Food": ["foodie", "foodlover", "restaurant", "dining", "food"],
            "Fashion & Apparel": ["fashion", "style", "ootd", "fashionista", "trending"],
            "Fitness & Wellness": ["fitness", "health", "wellness", "workout", "fitlife"],
            "Beauty & Cosmetics": ["beauty", "skincare", "makeup", "selfcare", "glowup"],
            "Technology": ["tech", "innovation", "technology", "digital", "technews"],
            "Real Estate": ["realestate", "property", "home", "investment", "housing"],
            "Education": ["education", "learning", "knowledge", "study", "academic"],
            "Healthcare": ["health", "wellness", "medical", "healthcare", "wellbeing"],
            "Retail & E-commerce": ["shopping", "retail", "ecommerce", "deals", "shop"],
            "Entertainment": ["entertainment", "fun", "lifestyle", "culture", "events"],
            "Travel & Tourism": ["travel", "wanderlust", "adventure", "explore", "vacation"],
            "Professional Services": ["business", "professional", "services", "consulting", "expert"],
            "Home & Garden": ["home", "garden", "diy", "decor", "homestyle"],
            "Automotive": ["cars", "automotive", "vehicle", "driving", "auto"],
            "Sports & Recreation": ["sports", "fitness", "recreation", "active", "athletic"]
        ]
        
        return hashtagMap[category] ?? ["business", "marketing", category.lowercased().replacingOccurrences(of: " ", with: "")]
    }
}

// MARK: - UIImage Extension for Resizing
extension UIImage {
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

enum AutoGenerateError: LocalizedError {
    case noProfileData
    case insufficientData
    case imageGenerationFailed
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .noProfileData:
            return "No business profile found. Please complete onboarding first."
        case .insufficientData:
            return "Insufficient business data. Please complete onboarding with website analysis."
        case .imageGenerationFailed:
            return "Failed to generate images. Please try again."
        case .notAuthenticated:
            return "You must be signed in to generate posts."
        }
    }
}

