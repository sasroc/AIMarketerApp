import Foundation
import SwiftUI
import Supabase

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .categorySelection
    @Published var selectedCategory: String?
    @Published var customCategory: String = ""
    @Published var websiteUrl: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var businessAnalysis: BusinessAnalysisResult?
    @Published var userProfile: UserProfile?
    
    private let supabaseService = SupabaseService.shared
    
    enum OnboardingStep {
        case categorySelection
        case customCategoryInput
        case welcome
        case websiteInput
        case analyzing
        case results
    }
    
    // Business categories
    let businessCategories = [
        "Restaurant & Food",
        "Fashion & Apparel",
        "Fitness & Wellness",
        "Beauty & Cosmetics",
        "Technology",
        "Real Estate",
        "Education",
        "Healthcare",
        "Retail & E-commerce",
        "Entertainment",
        "Travel & Tourism",
        "Professional Services",
        "Home & Garden",
        "Automotive",
        "Sports & Recreation",
        "Other"
    ]
    
    func selectCategory(_ category: String) {
        selectedCategory = category
        if category == "Other" {
            currentStep = .customCategoryInput
        } else {
            currentStep = .welcome
        }
    }
    
    func saveCustomCategory() {
        if !customCategory.trimmingCharacters(in: .whitespaces).isEmpty {
            selectedCategory = customCategory.trimmingCharacters(in: .whitespaces)
            currentStep = .welcome
        }
    }
    
    func saveCategory() async throws {
        guard let category = selectedCategory,
              let userId = await getCurrentUserId() else {
            throw OnboardingError.missingData
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let supabase = supabaseService.client
            
            // Check if profile exists
            let existingProfile: [UserProfile] = try await supabase
                .from("user_profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if let profile = existingProfile.first {
                // Update existing profile
                let updatedProfile = UserProfile(
                    id: profile.id,
                    userId: profile.userId,
                    onboardingCompleted: profile.onboardingCompleted,
                    businessCategory: category,
                    websiteUrl: profile.websiteUrl,
                    businessSummary: profile.businessSummary,
                    businessValueProposition: profile.businessValueProposition,
                    businessDescription: profile.businessDescription,
                    brandColors: profile.brandColors,
                    logoUrl: profile.logoUrl,
                    brandImages: profile.brandImages,
                    websiteAnalyzedAt: profile.websiteAnalyzedAt,
                    createdAt: profile.createdAt,
                    updatedAt: Date()
                )
                
                struct CategoryUpdate: Encodable {
                    let business_category: String
                    let updated_at: String
                }
                
                let formatter = ISO8601DateFormatter()
                try await supabase
                    .from("user_profiles")
                    .update(CategoryUpdate(
                        business_category: category,
                        updated_at: formatter.string(from: Date())
                    ))
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                
                userProfile = updatedProfile
            } else {
                // Create new profile
                let newProfile = UserProfile(
                    userId: userId,
                    businessCategory: category
                )
                
                struct ProfileInsert: Encodable {
                    let user_id: String
                    let business_category: String
                    let onboarding_completed: Bool
                }
                
                try await supabase
                    .from("user_profiles")
                    .insert(ProfileInsert(
                        user_id: userId.uuidString,
                        business_category: category,
                        onboarding_completed: false
                    ))
                    .execute()
                
                userProfile = newProfile
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func analyzeWebsite(_ url: String) async throws {
        isLoading = true
        errorMessage = nil
        currentStep = .analyzing
        
        do {
            let supabase = supabaseService.client
            guard let userId = await getCurrentUserId() else {
                throw OnboardingError.notAuthenticated
            }
            
            // Call Supabase Edge Function to analyze website
            let request = ["url": url]
            let response: BusinessAnalysisResult = try await supabase.functions
                .invoke("analyze-website", options: FunctionInvokeOptions(body: request))
            
            businessAnalysis = response
            
            // Save analysis results to user profile
            try await saveBusinessAnalysis(url: url, analysis: response)
            
            currentStep = .results
        } catch {
            errorMessage = error.localizedDescription
            currentStep = .websiteInput
            throw error
        }
        
        isLoading = false
    }
    
    private func saveBusinessAnalysis(url: String, analysis: BusinessAnalysisResult) async throws {
        guard let userId = await getCurrentUserId() else {
            throw OnboardingError.notAuthenticated
        }
        
        let supabase = supabaseService.client
        
        // Ensure profile exists first
        try await ensureProfileExists(userId: userId)
        
        struct ProfileUpdate: Encodable {
            let website_url: String
            let business_summary: String
            let business_value_proposition: String
            let business_description: String
            let brand_colors: [String]
            let logo_url: String?
            let brand_images: [String]
            let website_analyzed_at: String
            let updated_at: String
        }
        
        let formatter = ISO8601DateFormatter()
        try await supabase
            .from("user_profiles")
            .update(ProfileUpdate(
                website_url: url,
                business_summary: analysis.summary,
                business_value_proposition: analysis.valueProposition,
                business_description: analysis.description,
                brand_colors: analysis.colors,
                logo_url: analysis.logoUrl,
                brand_images: analysis.images,
                website_analyzed_at: formatter.string(from: Date()),
                updated_at: formatter.string(from: Date())
            ))
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    func completeOnboarding() async throws {
        guard let userId = await getCurrentUserId() else {
            throw OnboardingError.notAuthenticated
        }
        
        let supabase = supabaseService.client
        
        // Ensure profile exists first
        try await ensureProfileExists(userId: userId)
        
        struct OnboardingCompleteUpdate: Encodable {
            let onboarding_completed: Bool
            let updated_at: String
        }
        
        let formatter = ISO8601DateFormatter()
        try await supabase
            .from("user_profiles")
            .update(OnboardingCompleteUpdate(
                onboarding_completed: true,
                updated_at: formatter.string(from: Date())
            ))
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    private func ensureProfileExists(userId: UUID) async throws {
        let supabase = supabaseService.client
        
        // Check if profile exists
        let existingProfile: [UserProfile] = try await supabase
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        if existingProfile.isEmpty {
            // Profile doesn't exist - create it
            struct ProfileInsert: Encodable {
                let user_id: String
                let onboarding_completed: Bool
            }
            
            try await supabase
                .from("user_profiles")
                .insert(ProfileInsert(
                    user_id: userId.uuidString,
                    onboarding_completed: false
                ))
                .execute()
        }
    }
    
    func checkOnboardingStatus() async throws -> Bool {
        guard let userId = await getCurrentUserId() else {
            throw OnboardingError.notAuthenticated
        }
        
        let supabase = supabaseService.client
        
        do {
            let profiles: [UserProfile] = try await supabase
                .from("user_profiles")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if let profile = profiles.first {
                userProfile = profile
                return profile.onboardingCompleted
            }
            
            // No profile found - user might have been deleted
            // Return false to trigger onboarding (which will create a new profile)
            return false
        } catch {
            // If we get an error, it might mean the user doesn't exist
            // Re-throw to let RootView handle it (sign out)
            throw error
        }
    }
    
    private func getCurrentUserId() async -> UUID? {
        do {
            let session = try await supabaseService.client.auth.session
            return UUID(uuidString: session.user.id.uuidString)
        } catch {
            return nil
        }
    }
}

enum OnboardingError: LocalizedError {
    case missingData
    case notAuthenticated
    case invalidUrl
    case analysisFailed
    
    var errorDescription: String? {
        switch self {
        case .missingData:
            return "Missing required data"
        case .notAuthenticated:
            return "User not authenticated"
        case .invalidUrl:
            return "Invalid website URL"
        case .analysisFailed:
            return "Failed to analyze website"
        }
    }
}

