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
    @Published var lastRefreshTime: Date?
    
    private let contentService = ContentGenerationService.shared
    private let supabaseService = SupabaseService.shared
    private var refreshTimer: Timer?
    private let notificationManager = NotificationManager.shared
    private let statusTracker = PostStatusTracker.shared
    
    let maxMediaItems = 10
    
    // MARK: - Initialization
    
    init() {
        // Load data when view model is created
        Task { @MainActor in
            await loadUserData()
            startAutoRefresh()
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
            // Use case-insensitive comparison for UUID matching
            // Flatten all media item IDs from all posts (since posts can have multiple media items)
            let mediaItemIds = Set(generatedPosts.flatMap { $0.mediaItemIds.map { $0.lowercased() } })
            mediaItems = allMedia.filter { mediaItemIds.contains($0.id.lowercased()) }
            print("✅ Loaded \(mediaItems.count) media items for current posts")
            _ = await statusTracker.process(posts: generatedPosts)
        } catch {
            print("❌ Failed to load data: \(error.localizedDescription)")
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Refresh only the post statuses (lightweight refresh)
    func refreshPostStatuses() async {
        do {
            let updatedPosts = try await supabaseService.fetchGeneratedPosts()
            let changes = await statusTracker.process(posts: updatedPosts)
            generatedPosts = updatedPosts
            lastRefreshTime = Date()
            for change in changes {
                notificationManager.sendPostStatusNotification(for: change.post, previousStatus: change.previousStatus)
            }
        } catch {
            print("❌ Failed to refresh posts: \(error.localizedDescription)")
        }
    }
    
    /// Start auto-refresh timer for post statuses
    func startAutoRefresh() {
        stopAutoRefresh() // Clean up any existing timer
        
        // Create timer and add to main run loop
        let timer = Timer(timeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.refreshPostStatuses()
            }
        }
        
        // Add to run loop with common mode so it runs even during scrolling
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
        
        // Fire immediately for first refresh
        timer.fire()
    }
    
    /// Stop auto-refresh timer
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
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
            var savedItem = try await supabaseService.saveMediaItem(item)
            
            // Upload thumbnail if we have one (especially important for videos)
            var thumbnailURL: String? = nil
            if let thumbnail = item.thumbnail, let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) {
                let thumbnailFileName = "\(item.id)_thumb.jpg"
                thumbnailURL = try await supabaseService.uploadMedia(
                    data: thumbnailData,
                    fileName: thumbnailFileName,
                    contentType: "image/jpeg"
                )
            }
            
            // Then upload the file if we have local data
            if let localURL = item.localURL {
                // Load the file data
                let data = try Data(contentsOf: localURL)
                
                // Determine content type
                let contentType = item.type == .video ? "video/mp4" : "image/jpeg"
                let fileName = "\(item.id).\(item.type == .video ? "mp4" : "jpg")"
                
                // Upload to Supabase Storage
                let cloudURL = try await supabaseService.uploadMedia(
                    data: data,
                    fileName: fileName,
                    contentType: contentType
                )
                
                // Update media item with cloud URL and thumbnail URL
                if let index = mediaItems.firstIndex(where: { $0.id == item.id }) {
                    savedItem.cloudURL = cloudURL
                    savedItem.thumbnailURL = thumbnailURL
                    mediaItems[index] = savedItem
                    
                    // Update in database with cloud URL and thumbnail URL
                    _ = try await supabaseService.saveMediaItem(savedItem)
                }
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
        // Use case-insensitive comparison to avoid issues with UUID casing
        if let index = generatedPosts.firstIndex(where: { 
            $0.id.lowercased() == postId.lowercased() 
        }) {
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
        // Use case-insensitive comparison to avoid issues with UUID casing
        generatedPosts.removeAll { $0.id.lowercased() == post.id.lowercased() }
        
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
        // Don't clear generatedPosts - they should persist and be visible on home screen
        // generatedPosts = []
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
                    // Use case-insensitive comparison
                    // Check if any of the post's media items match campaign media items
                    post.mediaItemIds.contains { postMediaId in
                        mediaItems.contains { $0.id.lowercased() == postMediaId.lowercased() }
                    }
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

