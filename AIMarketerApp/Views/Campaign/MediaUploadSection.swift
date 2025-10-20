import SwiftUI
import PhotosUI

struct MediaUploadSection: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Upload Media")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Select up to \(campaignViewModel.maxMediaItems) images or videos for your campaign")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Photo picker button
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: campaignViewModel.maxMediaItems,
                matching: .any(of: [.images, .videos])
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                    Text("Select Photos & Videos")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(0.2))
                .foregroundColor(.purple)
                .cornerRadius(12)
            }
            .onChange(of: selectedItems) { newItems in
                loadMedia(from: newItems)
            }
            
            // Media grid
            if !campaignViewModel.mediaItems.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(campaignViewModel.mediaItems) { item in
                        MediaItemView(item: item) {
                            campaignViewModel.removeMediaItem(item)
                        }
                    }
                }
            }
            
            // Counter
            HStack {
                Text("\(campaignViewModel.mediaItems.count) / \(campaignViewModel.maxMediaItems)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
    }
    
    private func loadMedia(from items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    let mediaItem = MediaItem(
                        type: .image,
                        thumbnail: image,
                        localURL: nil
                    )
                    await MainActor.run {
                        campaignViewModel.addMediaItem(mediaItem)
                    }
                }
            }
            
            // Clear selection
            await MainActor.run {
                selectedItems = []
            }
        }
    }
}

struct MediaItemView: View {
    let item: MediaItem
    let onDelete: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let thumbnail = item.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipped()
                    .cornerRadius(12)
            }
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(4)
        }
    }
}

#Preview {
    MediaUploadSection()
        .environmentObject(CampaignViewModel())
        .padding()
        .background(Color.black)
}

