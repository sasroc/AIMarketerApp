import SwiftUI

struct PostPreviewCard: View {
    let post: GeneratedPost
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                
                // Scheduled date
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Delete button
                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.marketingError.opacity(0.8))
                        .font(.system(size: 16))
                }
                .padding(.leading, 8)
            }
            
            // Caption
            Text(post.caption)
                .font(.body)
                .foregroundColor(.white)
                .lineLimit(3)
            
            // Media preview
            if let mediaItem = campaignViewModel.mediaItems.first(where: { $0.id == post.mediaItemId }) {
                Group {
                    if let thumbnail = mediaItem.thumbnail {
                        // Display local thumbnail if available
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .clipped()
                            .cornerRadius(12)
                    } else if let cloudURL = mediaItem.cloudURL, let url = URL(string: cloudURL) {
                        // Display from cloud URL
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
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
                    } else {
                        // Fallback placeholder
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
        .padding()
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
}

