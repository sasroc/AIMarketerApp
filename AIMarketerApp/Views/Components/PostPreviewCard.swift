import SwiftUI

struct PostPreviewCard: View {
    let post: GeneratedPost
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var showingDeleteConfirmation = false
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Collapsed header - always visible
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    // Status badge
                    HStack(spacing: 6) {
                        Image(systemName: post.status.icon)
                            .font(.caption)
                        Text(post.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    // Scheduled date and time
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .fontWeight(.medium)
                    
                    // Chevron icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
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
                    
                    // Caption
                    Text(post.caption)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(nil)
                    
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
                                    
                                    // Video indicator
                                    if mediaItem.type == .video {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white)
                                            .shadow(radius: 5)
                                    }
                                }
                            } else if mediaItem.type == .image, let cloudURL = mediaItem.cloudURL, let url = URL(string: cloudURL) {
                                // For images, display from cloud URL
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(height: 200)
                                            .frame(maxWidth: .infinity)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 200)
                                            .cornerRadius(12)
                                    case .failure:
                                        VStack {
                                            Image(systemName: "photo")
                                            Text("Failed to load")
                                        }
                                        .frame(height: 200)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else if mediaItem.type == .video, let thumbnailURL = mediaItem.thumbnailURL, let url = URL(string: thumbnailURL) {
                                // For videos, display thumbnail from thumbnailURL
                                ZStack {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(height: 200)
                                                .frame(maxWidth: .infinity)
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
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                        .shadow(radius: 5)
                                }
                            } else {
                                // Fallback placeholder
                                if mediaItem.type == .video {
                                    videoPlaceholder
                                } else {
                                    VStack {
                                        Image(systemName: "photo")
                                        Text("No image")
                                    }
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                    
                    // Delete button
                    Button(action: { showingDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Post")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.marketingError)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.marketingError.opacity(0.1))
                        .cornerRadius(8)
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
            Text("Are you sure you want to delete this scheduled post?")
        }
    }
    
    private var statusColor: Color {
        switch post.status {
        case .draft: return .marketingWarning
        case .pending: return .marketingWarning
        case .scheduled: return .marketingInfo
        case .posted: return .marketingSuccess
        case .failed: return .marketingError
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: post.scheduledDate)
    }
    
    private var videoPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.3)
            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .shadow(radius: 5)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .cornerRadius(12)
    }
}

