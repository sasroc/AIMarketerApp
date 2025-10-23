import Foundation
import SwiftUI
import PhotosUI

@MainActor
class CampaignViewModel: ObservableObject {
    @Published var mediaItems: [MediaItem] = []
    @Published var marketingPlan = MarketingPlan()
    @Published var schedule = PostSchedule()
    @Published var generatedPosts: [GeneratedPost] = []
    @Published var draftCampaigns: [DraftCampaign] = []
    
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var currentStep = 0
    
    private let contentService = ContentGenerationService.shared
    
    let maxMediaItems = 10
    
    func addMediaItem(_ item: MediaItem) {
        guard mediaItems.count < maxMediaItems else {
            errorMessage = "Maximum \(maxMediaItems) media items allowed"
            return
        }
        mediaItems.append(item)
    }
    
    func removeMediaItem(_ item: MediaItem) {
        mediaItems.removeAll { $0.id == item.id }
    }
    
    func generatePosts() async {
        guard !mediaItems.isEmpty else {
            errorMessage = "Please add at least one media item"
            return
        }
        
        guard !marketingPlan.description.isEmpty else {
            errorMessage = "Please provide a marketing plan description"
            return
        }
        
        guard !schedule.selectedDays.isEmpty else {
            errorMessage = "Please select at least one posting day"
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        do {
            let posts = try await contentService.generatePosts(
                mediaItems: mediaItems,
                marketingPlan: marketingPlan,
                schedule: schedule
            )
            generatedPosts = posts
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    func updatePostCaption(postId: String, newCaption: String) {
        if let index = generatedPosts.firstIndex(where: { $0.id == postId }) {
            generatedPosts[index].caption = newCaption
        }
    }
    
    func scheduleAllPosts() {
        // Update all posts to scheduled status
        for index in generatedPosts.indices {
            generatedPosts[index].status = .scheduled
        }
    }
    
    func deletePost(_ post: GeneratedPost) {
        generatedPosts.removeAll { $0.id == post.id }
    }
    
    func deletePost(at offsets: IndexSet, from posts: [GeneratedPost]) {
        let postsToDelete = offsets.map { posts[$0] }
        for post in postsToDelete {
            deletePost(post)
        }
    }
    
    func resetCampaign() {
        mediaItems = []
        marketingPlan = MarketingPlan()
        schedule = PostSchedule()
        generatedPosts = []
        currentStep = 0
        errorMessage = nil
    }
    
    // MARK: - Draft Management
    
    func saveDraft() {
        let draft = DraftCampaign(
            mediaItems: mediaItems,
            marketingPlan: marketingPlan,
            schedule: schedule,
            currentStep: currentStep,
            updatedAt: Date()
        )
        
        if let existingIndex = draftCampaigns.firstIndex(where: { $0.id == draft.id }) {
            draftCampaigns[existingIndex] = draft
        } else {
            draftCampaigns.append(draft)
        }
        
        // Reset current campaign
        resetCampaign()
    }
    
    func loadDraft(_ draft: DraftCampaign) {
        mediaItems = draft.mediaItems
        marketingPlan = draft.marketingPlan
        schedule = draft.schedule
        currentStep = draft.currentStep
        errorMessage = nil
    }
    
    func deleteDraft(_ draft: DraftCampaign) {
        draftCampaigns.removeAll { $0.id == draft.id }
    }
    
    func hasUnsavedChanges() -> Bool {
        return !mediaItems.isEmpty || 
               !marketingPlan.description.isEmpty || 
               !schedule.selectedDays.isEmpty ||
               currentStep > 0
    }
}

