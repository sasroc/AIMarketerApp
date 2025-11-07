import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var selectedFilter: PostStatus?
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterButton(
                                title: "All",
                                isSelected: selectedFilter == nil,
                                count: campaignViewModel.generatedPosts.count
                            ) {
                                selectedFilter = nil
                            }
                            
                            ForEach([PostStatus.scheduled, .draft, .posted, .failed], id: \.self) { status in
                                FilterButton(
                                    title: status.rawValue,
                                    isSelected: selectedFilter == status,
                                    count: status == .draft ? campaignViewModel.draftCampaigns.count : filteredPosts(for: status).count
                                ) {
                                    selectedFilter = status
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(Color.black)
                    
                    // Posts list
                    if (selectedFilter == .draft && campaignViewModel.draftCampaigns.isEmpty) || 
                       (selectedFilter != .draft && filteredPosts.isEmpty) {
                        EmptyStateView(
                            icon: selectedFilter == .draft ? "doc.text" : "calendar.badge.exclamationmark",
                            title: selectedFilter == .draft ? "No drafts" : "No posts",
                            message: selectedFilter == nil
                                ? "Create a campaign to get started"
                                : selectedFilter == .draft
                                ? "Save a draft to see it here"
                                : "No posts with this status"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Refresh indicator
                                if let lastRefresh = campaignViewModel.lastRefreshTime {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.caption)
                                        Text("Updated \(timeAgoString(from: lastRefresh))")
                                            .font(.caption)
                                        Spacer()
                                        if isRefreshing {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        }
                                    }
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                }
                                
                                if selectedFilter == .draft {
                                    ForEach(campaignViewModel.draftCampaigns) { draft in
                                        DraftCard(draft: draft)
                                            .padding(.horizontal)
                                    }
                                } else {
                                    ForEach(filteredPosts) { post in
                                        SchedulePostCard(post: post)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                        .refreshable {
                            await refreshPosts()
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await campaignViewModel.refreshPostStatuses()
            }
        }
    }
    
    private func refreshPosts() async {
        isRefreshing = true
        await campaignViewModel.refreshPostStatuses()
        isRefreshing = false
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else {
            let hours = seconds / 3600
            return "\(hours)h ago"
        }
    }
    
    private var filteredPosts: [GeneratedPost] {
        if let filter = selectedFilter {
            if filter == .draft {
                return [] // Drafts are handled separately in the view
            }
            return filteredPosts(for: filter)
        }
        return campaignViewModel.generatedPosts.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    private func filteredPosts(for status: PostStatus) -> [GeneratedPost] {
        campaignViewModel.generatedPosts
            .filter { $0.status == status }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.marketingPrimary.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.marketingPrimary : Color.marketingCardBackground)
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
        }
    }
}

struct DraftCard: View {
    let draft: DraftCampaign
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.marketingPrimary)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Draft Campaign")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Step \(draft.currentStep + 1) of 4")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            if !draft.marketingPlan.description.isEmpty {
                Text(draft.marketingPlan.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            HStack {
                Label("\(draft.mediaItems.count) media items", systemImage: "photo")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if !draft.schedule.selectedDays.isEmpty {
                    Label("\(draft.schedule.selectedDays.count) days", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 12) {
                NavigationLink(destination: CreateCampaignView()) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Continue")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.marketingPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.marketingPrimary.opacity(0.1))
                    .cornerRadius(8)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    campaignViewModel.loadDraft(draft)
                })
                
                Button(action: { campaignViewModel.deleteDraft(draft) }) {
                    Image(systemName: "trash")
                        .foregroundColor(.marketingError)
                        .padding(8)
                        .background(Color.marketingError.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.marketingCardBackground)
        .cornerRadius(12)
    }
}

struct SchedulePostCard: View {
    let post: GeneratedPost
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var isEditing = false
    @State private var editedCaption: String
    @FocusState private var isTextEditorFocused: Bool
    @State private var showingDeleteConfirmation = false
    @State private var isExpanded = false
    
    init(post: GeneratedPost) {
        self.post = post
        self._editedCaption = State(initialValue: post.caption)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed header - always visible
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.marketingPrimary)
                    
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Chevron icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
            
            // Expanded content - shows when isExpanded is true
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Caption content with edit functionality
                    Group {
                        if isEditing {
                            SimpleTextEditor(text: $editedCaption)
                                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 300)
                                .focused($isTextEditorFocused)
                        } else {
                            Text(post.caption)
                                .font(.body)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Error message if post failed
                    if post.status == .failed, let errorMessage = post.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.marketingError)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.marketingError)
                        }
                        .padding(12)
                        .background(Color.marketingError.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Media preview
                    if let mediaItem = campaignViewModel.mediaItems.first(where: { $0.id == post.mediaItemId }) {
                        Group {
                            if let thumbnail = mediaItem.thumbnail {
                                // Display local thumbnail if available (works for both images and videos)
                                ZStack {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 200)
                                        .cornerRadius(12)
                                        .allowsHitTesting(false)
                                    
                                    // Video indicator
                                    if mediaItem.type == .video {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(.white)
                                            .shadow(radius: 5)
                                    }
                                }
                            } else if let cloudURL = mediaItem.cloudURL, let url = URL(string: cloudURL) {
                                // Display from cloud URL
                                if mediaItem.type == .image {
                                    // For images, use AsyncImage
                                    ZStack {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(maxWidth: .infinity)
                                                    .frame(height: 200)
                                                    .background(Color.gray.opacity(0.3))
                                                    .cornerRadius(12)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(maxWidth: .infinity)
                                                    .frame(height: 200)
                                                    .cornerRadius(12)
                                                    .allowsHitTesting(false)
                                            case .failure:
                                                VStack {
                                                    Image(systemName: "photo")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 50, height: 50)
                                                        .foregroundColor(.gray)
                                                    Text("Failed to load")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 200)
                                                .background(Color.gray.opacity(0.3))
                                                .cornerRadius(12)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                } else {
                                    // For videos, try to load thumbnail from thumbnailURL
                                    if let thumbnailURL = mediaItem.thumbnailURL, let thumbUrl = URL(string: thumbnailURL) {
                                        ZStack {
                                            AsyncImage(url: thumbUrl) { phase in
                                                switch phase {
                                                case .empty:
                                                    ProgressView()
                                                        .frame(maxWidth: .infinity)
                                                        .frame(height: 200)
                                                        .background(Color.gray.opacity(0.3))
                                                        .cornerRadius(12)
                                                case .success(let image):
                                                    image
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(maxWidth: .infinity)
                                                        .frame(height: 200)
                                                        .cornerRadius(12)
                                                case .failure:
                                                    videoPlaceholder
                                                @unknown default:
                                                    EmptyView()
                                                }
                                            }
                                            
                                            // Play icon overlay
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.white)
                                                .shadow(radius: 5)
                                        }
                                    } else {
                                        // No thumbnail URL, show placeholder
                                        videoPlaceholder
                                    }
                                }
                            } else {
                                // Fallback placeholder
                                VStack {
                                    Image(systemName: mediaItem.type == .video ? "video" : "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                    Text(mediaItem.type == .video ? "Video (no preview)" : "No image")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            }
                        }
                    } else {
                        // No media item found
                        VStack {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                            Text("Media not found")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                    }
                    
                    // Edit and Delete buttons
                    HStack(spacing: 12) {
                        // Edit button
                        Button(action: {
                            toggleEdit()
                        }) {
                            HStack {
                                Image(systemName: isEditing ? "checkmark" : "pencil")
                                Text(isEditing ? "Done" : "Edit")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.marketingPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.marketingPrimary.opacity(0.15))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.marketingPrimary.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Delete button
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.marketingError)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.marketingError.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color.marketingCardBackground)
        .cornerRadius(16)
        .alert("Delete Post", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                withAnimation {
                    campaignViewModel.deletePost(post)
                }
            }
        } message: {
            Text("Are you sure you'd like to delete this post?")
        }
    }
    
    private func toggleEdit() {
        if isEditing {
            // Save changes and exit edit mode
            campaignViewModel.updatePostCaption(postId: post.id, newCaption: editedCaption)
            isTextEditorFocused = false
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing = false
            }
        } else {
            // Enter edit mode
            withAnimation(.easeInOut(duration: 0.2)) {
                isEditing = true
            }
            
            // Focus the text editor after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isTextEditorFocused = true
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: post.scheduledDate)
    }
    
    private var videoPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: "play.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.white)
                .shadow(radius: 5)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .cornerRadius(12)
    }
}

#Preview {
    ScheduleView()
        .environmentObject(CampaignViewModel())
}

