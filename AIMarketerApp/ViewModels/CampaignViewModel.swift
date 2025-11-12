import Foundation
import SwiftUI
import PhotosUI

@MainActor
class CampaignViewModel: ObservableObject {
    @Published var mediaItems: [MediaItem] = []
    @Published var allSavedMediaItems: [MediaItem] = [] // All saved media items from database
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
            
            // Store all saved media items (for selection in upload section and change media)
            allSavedMediaItems = allMedia
            
            // Load thumbnails for saved media items
            await loadThumbnailsForSavedMedia()
            
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
            let hadNewPosts = !changes.isEmpty && changes.contains { $0.post.status == .posted }
            generatedPosts = updatedPosts
            lastRefreshTime = Date()
            for change in changes {
                notificationManager.sendPostStatusNotification(for: change.post, previousStatus: change.previousStatus)
            }
            
            // Notify analytics view model if new posts were published
            if hadNewPosts {
                // Post a notification that analytics should refresh
                NotificationCenter.default.post(name: NSNotification.Name("PostsStatusChanged"), object: nil)
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
    
    func loadAllSavedMedia() async {
        do {
            let allMedia = try await supabaseService.fetchMediaItems()
            allSavedMediaItems = allMedia
            await loadThumbnailsForSavedMedia()
            print("✅ Loaded \(allMedia.count) saved media items")
        } catch {
            print("❌ Failed to load saved media: \(error.localizedDescription)")
        }
    }
    
    private func loadThumbnailsForSavedMedia() async {
        // Load thumbnails for media items that don't have local thumbnails
        for index in allSavedMediaItems.indices {
            let item = allSavedMediaItems[index]
            
            // If item already has thumbnail data, skip
            if item.thumbnail != nil {
                continue
            }
            
            // Try to load from thumbnail URL
            if let thumbnailURL = item.thumbnailURL, let url = URL(string: thumbnailURL) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            var updatedItem = allSavedMediaItems[index]
                            updatedItem.thumbnail = image
                            allSavedMediaItems[index] = updatedItem
                        }
                    }
                } catch {
                    // If thumbnail URL fails, try cloud URL
                    if let cloudURL = item.cloudURL, let url = URL(string: cloudURL) {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let image = UIImage(data: data) {
                                await MainActor.run {
                                    var updatedItem = allSavedMediaItems[index]
                                    updatedItem.thumbnail = image
                                    allSavedMediaItems[index] = updatedItem
                                }
                            }
                        } catch {
                            print("⚠️ Failed to load thumbnail for media \(item.id): \(error.localizedDescription)")
                        }
                    }
                }
            } else if let cloudURL = item.cloudURL, let url = URL(string: cloudURL) {
                // Fallback to cloud URL if no thumbnail URL
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        await MainActor.run {
                            var updatedItem = allSavedMediaItems[index]
                            updatedItem.thumbnail = image
                            allSavedMediaItems[index] = updatedItem
                        }
                    }
                } catch {
                    print("⚠️ Failed to load image for media \(item.id): \(error.localizedDescription)")
                }
            }
        }
    }
    
    func addMediaItem(_ item: MediaItem) {
        guard mediaItems.count < maxMediaItems else {
            errorMessage = "Maximum \(maxMediaItems) media items allowed"
            return
        }
        mediaItems.append(item)
        
        // Save and upload media immediately
        Task {
            await saveAndUploadMediaItem(item)
            // Reload saved media to include the new item
            await loadAllSavedMedia()
        }
    }
    
    func removeMediaItem(_ item: MediaItem) {
        // This method deletes from database - only use for newly uploaded items
        mediaItems.removeAll { $0.id == item.id }
        allSavedMediaItems.removeAll { $0.id == item.id }
        
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
    
    func removeMediaItemFromSelection(_ item: MediaItem) {
        // Only remove from selection, don't delete from database
        mediaItems.removeAll { $0.id == item.id }
    }
    
    func deleteMediaItemFromDatabase(_ item: MediaItem) {
        // Remove from both selection and saved media list
        mediaItems.removeAll { $0.id == item.id }
        allSavedMediaItems.removeAll { $0.id == item.id }
        
        // Delete from database
        Task {
            do {
                print("🗑️ Deleting media item from database: \(item.id)")
                try await supabaseService.deleteMediaItem(item.id)
                print("✅ Media item deleted from database")
            } catch {
                print("❌ Failed to delete media: \(error.localizedDescription)")
                errorMessage = "Failed to delete media: \(error.localizedDescription)"
            }
        }
    }
    
    func selectSavedMediaItem(_ item: MediaItem) {
        // Check if item is already selected - toggle it
        if let index = mediaItems.firstIndex(where: { $0.id == item.id }) {
            mediaItems.remove(at: index)
        } else {
            // Check if we can add more items
            guard mediaItems.count < maxMediaItems else {
                errorMessage = "Maximum \(maxMediaItems) media items allowed"
                return
            }
            mediaItems.append(item)
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
    
    func updatePostScheduledDate(postId: String, newScheduledDate: Date) {
        // Use case-insensitive comparison to avoid issues with UUID casing
        if let index = generatedPosts.firstIndex(where: { 
            $0.id.lowercased() == postId.lowercased() 
        }) {
            // Create updated post with all fields preserved, especially mediaItemIds
            let currentPost = generatedPosts[index]
            
            // If mediaItemIds is empty, reload from database to ensure we have the associations
            var mediaItemIds = currentPost.mediaItemIds
            if mediaItemIds.isEmpty {
                print("⚠️ Post has no mediaItemIds in memory, reloading from database...")
                Task {
                    do {
                        // Reload all posts to get fresh data
                        let allPosts = try await supabaseService.fetchGeneratedPosts()
                        if let reloadedPost = allPosts.first(where: { $0.id.lowercased() == postId.lowercased() }) {
                            mediaItemIds = reloadedPost.mediaItemIds
                            print("✅ Reloaded post, found \(mediaItemIds.count) media items")
                            
                            // Now update with the reloaded mediaItemIds
                            let updatedPost = GeneratedPost(
                                id: currentPost.id,
                                caption: currentPost.caption,
                                mediaItemIds: mediaItemIds,
                                scheduledDate: newScheduledDate,
                                status: currentPost.status,
                                createdAt: currentPost.createdAt,
                                instagramPostId: currentPost.instagramPostId,
                                instagramPermalink: currentPost.instagramPermalink,
                                publishedAt: currentPost.publishedAt,
                                errorMessage: currentPost.errorMessage
                            )
                            
                            // Update in-memory post
                            await MainActor.run {
                                if let newIndex = generatedPosts.firstIndex(where: { $0.id.lowercased() == postId.lowercased() }) {
                                    generatedPosts[newIndex] = updatedPost
                                }
                            }
                            
                            // Save to database
                            _ = try await supabaseService.saveGeneratedPost(updatedPost, campaignId: currentCampaignId)
                            print("✅ Updated post scheduled date: \(newScheduledDate)")
                            print("✅ Post has \(updatedPost.mediaItemIds.count) media items")
                        } else {
                            print("❌ Could not find post in database after reload")
                            await MainActor.run {
                                errorMessage = "Failed to reload post from database"
                            }
                        }
                    } catch {
                        print("❌ Failed to reload post: \(error.localizedDescription)")
                        await MainActor.run {
                            errorMessage = "Failed to save post: \(error.localizedDescription)"
                        }
                    }
                }
                return
            }
            
            let updatedPost = GeneratedPost(
                id: currentPost.id,
                caption: currentPost.caption,
                mediaItemIds: mediaItemIds,
                scheduledDate: newScheduledDate,
                status: currentPost.status,
                createdAt: currentPost.createdAt,
                instagramPostId: currentPost.instagramPostId,
                instagramPermalink: currentPost.instagramPermalink,
                publishedAt: currentPost.publishedAt,
                errorMessage: currentPost.errorMessage
            )
            
            // Update in-memory post
            generatedPosts[index] = updatedPost
            
            // Save to database
            Task {
                do {
                    _ = try await supabaseService.saveGeneratedPost(updatedPost, campaignId: currentCampaignId)
                    print("✅ Updated post scheduled date: \(newScheduledDate)")
                    print("✅ Post has \(updatedPost.mediaItemIds.count) media items")
                } catch {
                    print("❌ Failed to update post scheduled date: \(error.localizedDescription)")
                    errorMessage = "Failed to save post: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updatePostMedia(postId: String, newMediaItemIds: [String]) {
        // Use case-insensitive comparison to avoid issues with UUID casing
        if let index = generatedPosts.firstIndex(where: { 
            $0.id.lowercased() == postId.lowercased() 
        }) {
            generatedPosts[index] = GeneratedPost(
                id: generatedPosts[index].id,
                caption: generatedPosts[index].caption,
                mediaItemIds: newMediaItemIds,
                scheduledDate: generatedPosts[index].scheduledDate,
                status: generatedPosts[index].status,
                createdAt: generatedPosts[index].createdAt,
                instagramPostId: generatedPosts[index].instagramPostId,
                instagramPermalink: generatedPosts[index].instagramPermalink,
                publishedAt: generatedPosts[index].publishedAt,
                errorMessage: generatedPosts[index].errorMessage
            )
            
            // Save to database
            let post = generatedPosts[index]
            Task {
                do {
                    _ = try await supabaseService.saveGeneratedPost(post, campaignId: currentCampaignId)
                    print("✅ Updated post media: \(newMediaItemIds)")
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to save post media: \(error.localizedDescription)"
                    }
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
        // Don't clear allSavedMediaItems - they should persist for reuse
        // allSavedMediaItems = []
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

