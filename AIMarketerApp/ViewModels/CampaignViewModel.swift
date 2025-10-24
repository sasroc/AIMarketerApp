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
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentStep = 0
    @Published var currentCampaignId: String?
    
    private let contentService = ContentGenerationService.shared
    private let supabaseService = SupabaseService.shared
    
    let maxMediaItems = 10
    
    // MARK: - Initialization
    
    init() {
        // Load data when view model is created
        Task {
            await loadUserData()
        }
    }
    
    // MARK: - Data Loading
    
    func loadUserData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load draft campaigns
            draftCampaigns = try await supabaseService.fetchCampaigns()
            print("✅ Loaded \(draftCampaigns.count) campaigns")
            
            // Load all generated posts
            generatedPosts = try await supabaseService.fetchGeneratedPosts()
            print("✅ Loaded \(generatedPosts.count) posts")
            
            // Load all media items
            let allMedia = try await supabaseService.fetchMediaItems()
            print("✅ Loaded \(allMedia.count) media items from database")
            
            // Store media items that are referenced by posts
            let mediaItemIds = Set(generatedPosts.map { $0.mediaItemId })
            mediaItems = allMedia.filter { mediaItemIds.contains($0.id) }
            print("✅ Loaded \(mediaItems.count) media items for current posts")
        } catch {
            print("❌ Failed to load data: \(error.localizedDescription)")
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Media Management
    
    func addMediaItem(_ item: MediaItem) {
        guard mediaItems.count < maxMediaItems else {
            errorMessage = "Maximum \(maxMediaItems) media items allowed"
            return
        }
        mediaItems.append(item)
        
        // Save and upload media immediately
        Task {
            await saveAndUploadMediaItem(item)
        }
    }
    
    func removeMediaItem(_ item: MediaItem) {
        mediaItems.removeAll { $0.id == item.id }
        
        // Delete from database
        Task {
            do {
                print("🗑️ Deleting media item: \(item.id)")
                try await supabaseService.deleteMediaItem(item.id)
                print("✅ Media item deleted from database")
            } catch {
                print("❌ Failed to delete media: \(error.localizedDescription)")
                errorMessage = "Failed to delete media: \(error.localizedDescription)"
            }
        }
    }
    
    private func saveAndUploadMediaItem(_ item: MediaItem) async {
        do {
            // First, save the media item metadata to database (without cloud URL)
            print("💾 Saving media item \(item.id) to database...")
            print("   - Type: \(item.type.rawValue)")
            print("   - Has thumbnail: \(item.thumbnail != nil)")
            print("   - Has localURL: \(item.localURL != nil)")
            print("   - LocalURL: \(item.localURL?.absoluteString ?? "nil")")
            print("   - Has cloudURL: \(item.cloudURL != nil)")
            
            var savedItem = try await supabaseService.saveMediaItem(item)
            print("✅ Media item saved to database")
            
            // Then upload the file if we have local data
            if let localURL = item.localURL {
                print("☁️ Uploading media file to storage...")
                // Load the file data
                let data = try Data(contentsOf: localURL)
                print("   - File size: \(data.count) bytes")
                
                // Determine content type
                let contentType = item.type == .video ? "video/mp4" : "image/jpeg"
                let fileName = "\(item.id).\(item.type == .video ? "mp4" : "jpg")"
                
                // Upload to Supabase Storage
                let cloudURL = try await supabaseService.uploadMedia(
                    data: data,
                    fileName: fileName,
                    contentType: contentType
                )
                print("✅ Media file uploaded to storage")
                print("   - Cloud URL: \(cloudURL)")
                
                // Update media item with cloud URL
                if let index = mediaItems.firstIndex(where: { $0.id == item.id }) {
                    savedItem.cloudURL = cloudURL
                    mediaItems[index] = savedItem
                    
                    // Update in database with cloud URL
                    _ = try await supabaseService.saveMediaItem(savedItem)
                    print("✅ Media item updated with cloud URL")
                }
            } else {
                print("⚠️ No localURL found - skipping file upload")
                print("   - This media won't have a cloud URL")
            }
        } catch {
            print("❌ Failed to save/upload media: \(error.localizedDescription)")
            errorMessage = "Failed to save media: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Post Generation
    
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
            print("📝 Generated \(posts.count) posts")
            
            // Save generated posts to database
            try await supabaseService.saveGeneratedPosts(posts, campaignId: currentCampaignId)
            print("✅ Saved \(posts.count) posts to database")
        } catch {
            print("❌ Error generating/saving posts: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    func updatePostCaption(postId: String, newCaption: String) {
        if let index = generatedPosts.firstIndex(where: { $0.id == postId }) {
            generatedPosts[index].caption = newCaption
            
            // Save to database
            let post = generatedPosts[index]
            Task {
                do {
                    _ = try await supabaseService.saveGeneratedPost(post, campaignId: currentCampaignId)
                } catch {
                    errorMessage = "Failed to save post: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func scheduleAllPosts() {
        // Update all posts to scheduled status
        for index in generatedPosts.indices {
            generatedPosts[index].status = .scheduled
        }
        
        print("📅 Scheduling \(generatedPosts.count) posts")
        
        // Save all updated statuses to database
        Task {
            do {
                for post in generatedPosts {
                    try await supabaseService.updatePostStatus(post.id, status: .scheduled)
                }
                print("✅ Successfully scheduled \(generatedPosts.count) posts in database")
            } catch {
                print("❌ Failed to schedule posts: \(error.localizedDescription)")
                errorMessage = "Failed to schedule posts: \(error.localizedDescription)"
            }
        }
    }
    
    func deletePost(_ post: GeneratedPost) {
        generatedPosts.removeAll { $0.id == post.id }
        
        // Delete from database
        Task {
            do {
                try await supabaseService.deleteGeneratedPost(post.id)
            } catch {
                errorMessage = "Failed to delete post: \(error.localizedDescription)"
            }
        }
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
        currentCampaignId = nil
        errorMessage = nil
    }
    
    // MARK: - Draft Management
    
    func saveDraft() {
        let draft = DraftCampaign(
            id: currentCampaignId ?? UUID().uuidString,
            mediaItems: mediaItems,
            marketingPlan: marketingPlan,
            schedule: schedule,
            currentStep: currentStep,
            updatedAt: Date()
        )
        
        // Save to database
        Task {
            do {
                _ = try await supabaseService.saveCampaign(draft)
                
                // Reload campaigns to get the updated list
                await loadUserData()
                
                // Reset current campaign
                await MainActor.run {
                    resetCampaign()
                }
            } catch {
                errorMessage = "Failed to save draft: \(error.localizedDescription)"
            }
        }
    }
    
    func autoSaveCampaign() async {
        // Auto-save current campaign state without resetting
        guard hasUnsavedChanges() else { return }
        
        let draft = DraftCampaign(
            id: currentCampaignId ?? UUID().uuidString,
            mediaItems: mediaItems,
            marketingPlan: marketingPlan,
            schedule: schedule,
            currentStep: currentStep,
            updatedAt: Date()
        )
        
        do {
            _ = try await supabaseService.saveCampaign(draft)
            if currentCampaignId == nil {
                currentCampaignId = draft.id
            }
        } catch {
            // Silent fail for auto-save
            print("Auto-save failed: \(error.localizedDescription)")
        }
    }
    
    func loadDraft(_ draft: DraftCampaign) {
        mediaItems = draft.mediaItems
        marketingPlan = draft.marketingPlan
        schedule = draft.schedule
        currentStep = draft.currentStep
        currentCampaignId = draft.id
        errorMessage = nil
        
        // Load associated posts
        Task {
            do {
                let posts = try await supabaseService.fetchGeneratedPosts()
                generatedPosts = posts.filter { post in
                    // Filter posts that belong to this campaign's media items
                    mediaItems.contains { $0.id == post.mediaItemId }
                }
            } catch {
                errorMessage = "Failed to load posts: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteDraft(_ draft: DraftCampaign) {
        draftCampaigns.removeAll { $0.id == draft.id }
        
        // Delete from database
        Task {
            do {
                try await supabaseService.deleteCampaign(draft.id)
            } catch {
                errorMessage = "Failed to delete draft: \(error.localizedDescription)"
            }
        }
    }
    
    func hasUnsavedChanges() -> Bool {
        return !mediaItems.isEmpty || 
               !marketingPlan.description.isEmpty || 
               !schedule.selectedDays.isEmpty ||
               currentStep > 0
    }
}

