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
        
        // Get business information
        let businessCategory = profile.businessCategory ?? "business"
        let businessSummary = profile.businessSummary ?? ""
        let valueProposition = profile.businessValueProposition ?? ""
        let businessDescription = profile.businessDescription ?? ""
        
        // Build what the image should show based on business details
        let imageContent = determineImageContent(
            category: businessCategory,
            summary: businessSummary,
            valueProposition: valueProposition,
            description: businessDescription
        )
        
        // Brand colors - use first 2-3 colors
        let brandColorsText: String
        if !profile.brandColors.isEmpty {
            let colors = Array(profile.brandColors.prefix(3))
            brandColorsText = "Use colors \(colors.joined(separator: ", ")). "
        } else {
            brandColorsText = ""
        }
        
        // Create natural, descriptive prompts that describe what the image should contain
        let baseVariations = [
            "\(brandColorsText)\(imageContent). Professional photography, modern and clean design, high quality.",
            "\(brandColorsText)\(imageContent). Contemporary style, visually appealing, professional quality.",
            "\(brandColorsText)\(imageContent). Eye-catching design, modern aesthetic, polished finish.",
            "\(brandColorsText)\(imageContent). Professional composition, engaging visuals, contemporary style.",
            "\(brandColorsText)\(imageContent). Clean design, high visual impact, modern presentation.",
            "\(brandColorsText)\(imageContent). Compelling imagery, professional quality, visually striking.",
            "\(brandColorsText)\(imageContent). Dynamic design, contemporary aesthetic, polished appearance."
        ]
        
        // Generate prompts
        for i in 0..<count {
            var prompt = baseVariations[i % baseVariations.count]
            
            // Ensure prompt is within DALL-E 3 limits (keep under 1000 for best results)
            if prompt.count > 1000 {
                prompt = String(prompt.prefix(1000))
            }
            
            prompts.append(prompt)
        }
        
        return prompts
    }
    
    private func determineImageContent(category: String, summary: String, valueProposition: String, description: String) -> String {
        // Combine all business text to analyze
        let allText = "\(summary) \(valueProposition) \(description)".lowercased()
        let categoryLower = category.lowercased()
        
        // Extract what the business does (visual subject)
        let visualSubject = extractBusinessActivity(from: allText, category: categoryLower)
        
        // Get the main business message (value prop or summary) - keep it concise
        var businessMessage = ""
        if !valueProposition.isEmpty {
            businessMessage = cleanAndCompleteSentence(valueProposition, maxLength: 60)
        } else if !summary.isEmpty {
            businessMessage = extractFirstCompleteSentence(from: summary, maxLength: 60)
        }
        
        // Build natural, concise prompt
        if !businessMessage.isEmpty && businessMessage.count > 15 {
            // Use business message as the main focus
            return "A marketing image showcasing \(businessMessage), \(visualSubject)"
        } else {
            // Fallback to visual subject with category
            return "A marketing image \(visualSubject) for a \(category.lowercased()) business"
        }
    }
    
    private func extractBusinessActivity(from text: String, category: String) -> String {
        // Look for specific business activities and map to visual descriptions
        let activityMap: [String: String] = [
            "photography": "featuring professional photography work and visual storytelling",
            "restaurant": "showing delicious food, dining atmosphere, and culinary excellence",
            "fitness": "displaying fitness activities, wellness lifestyle, and healthy living",
            "beauty": "featuring beauty products, skincare routines, and cosmetic services",
            "technology": "showcasing technology solutions, digital innovation, and modern tech",
            "real estate": "displaying properties, homes, and real estate opportunities",
            "education": "showing learning environments, educational content, and knowledge",
            "healthcare": "featuring healthcare services, wellness, and medical care",
            "retail": "displaying products, shopping experience, and retail offerings",
            "entertainment": "showing entertainment experiences, events, and fun activities",
            "travel": "featuring travel destinations, adventures, and vacation experiences",
            "consulting": "showcasing professional services, expertise, and business solutions",
            "automotive": "displaying vehicles, automotive services, and car-related content",
            "sports": "showing sports activities, athleticism, and recreation",
            "home maintenance": "featuring home repair, maintenance services, and DIY solutions",
            "home repair": "displaying home improvement, repair work, and maintenance",
            "ai": "showcasing artificial intelligence, technology innovation, and smart solutions",
            "software": "featuring software solutions, digital tools, and technology"
        ]
        
        // Check for matches (case insensitive)
        for (keyword, description) in activityMap {
            if text.contains(keyword) || category.contains(keyword) {
                return description
            }
        }
        
        // Generic fallback based on category
        return "representing \(category) services and offerings"
    }
    
    private func cleanAndCompleteSentence(_ text: String, maxLength: Int) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        
        // Try to extract the core value proposition (remove company name if present, get to the essence)
        // For example: "QuickFix AI offers an innovative solution for home maintenance" 
        // -> "an innovative solution for home maintenance"
        if let offersIndex = cleaned.lowercased().range(of: " offers ") {
            let afterOffers = String(cleaned[offersIndex.upperBound...])
            if !afterOffers.isEmpty && afterOffers.count < cleaned.count {
                cleaned = afterOffers.trimmingCharacters(in: .whitespaces)
            }
        }
        
        // Remove incomplete endings (like "by", "for", "with" at the end)
        let incompleteEndings = [" by", " for", " with", " to", " in", " on", " at"]
        for ending in incompleteEndings {
            if cleaned.lowercased().hasSuffix(ending) {
                cleaned = String(cleaned.dropLast(ending.count))
            }
        }
        
        // Remove trailing periods if we're going to add more context
        cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: ". "))
        
        // Truncate at word boundary if needed
        if cleaned.count > maxLength {
            let truncated = String(cleaned.prefix(maxLength))
            if let lastSpace = truncated.lastIndex(of: " ") {
                cleaned = String(truncated[..<lastSpace])
            } else {
                cleaned = truncated
            }
        }
        
        return cleaned
    }
    
    private func extractFirstCompleteSentence(from text: String, maxLength: Int) -> String {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        
        // Split by sentence endings
        let sentences = cleaned.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count > 15 } // Filter out very short fragments
        
        // Get first complete sentence
        if let firstSentence = sentences.first {
            let complete = cleanAndCompleteSentence(firstSentence, maxLength: maxLength)
            if !complete.isEmpty {
                return complete
            }
        }
        
        // Fallback: clean the whole text
        return cleanAndCompleteSentence(cleaned, maxLength: maxLength)
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

