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
                    Text(post.status.rawValue)
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
                        .foregroundColor(.red.opacity(0.8))
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
            if let mediaItem = campaignViewModel.mediaItems.first(where: { $0.id == post.mediaItemId }),
               let thumbnail = mediaItem.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
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
        case .pending: return .gray
        case .scheduled: return .blue
        case .posted: return .green
        case .failed: return .red
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: post.scheduledDate)
    }
}

