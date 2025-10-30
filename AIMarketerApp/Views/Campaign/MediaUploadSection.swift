import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

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
                .background(Color.marketingPrimary.opacity(0.2))
                .foregroundColor(.marketingPrimary)
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
                // Check if item is a video
                let isVideo = checkIfVideo(item)
                
                if isVideo {
                    // Handle video
                    await loadVideoItem(item)
                } else {
                    // Handle image
                    await loadImageItem(item)
                }
            }
            
            // Clear selection
            await MainActor.run {
                selectedItems = []
            }
        }
    }
    
    private func checkIfVideo(_ item: PhotosPickerItem) -> Bool {
        // Check all supported content types, not just the first one
        for contentType in item.supportedContentTypes {
            let identifier = contentType.identifier
            if identifier.contains("movie") || 
               identifier.contains("video") ||
               identifier.contains("quicktime") ||
               contentType.conforms(to: .movie) ||
               contentType.conforms(to: .video) {
                return true
            }
        }
        return false
    }
    
    private func loadImageItem(_ item: PhotosPickerItem) async {
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            
            // Save to temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + ".jpg"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            do {
                try data.write(to: fileURL)
                
                let mediaItem = MediaItem(
                    type: .image,
                    thumbnail: image,
                    localURL: fileURL
                )
                
                await MainActor.run {
                    campaignViewModel.addMediaItem(mediaItem)
                }
            } catch {
                print("❌ Failed to save image: \(error)")
            }
        }
    }
    
    private func loadVideoItem(_ item: PhotosPickerItem) async {
        // Try loading as Data first (more reliable than custom Transferable)
        guard let videoData = try? await item.loadTransferable(type: Data.self) else {
            print("❌ Failed to load video data")
            return
        }
        
        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".mp4"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try videoData.write(to: fileURL)
            
            // Generate thumbnail from video
            let thumbnail = await generateVideoThumbnail(url: fileURL)
            
            let mediaItem = MediaItem(
                type: .video,
                thumbnail: thumbnail,
                localURL: fileURL
            )
            
            await MainActor.run {
                campaignViewModel.addMediaItem(mediaItem)
            }
        } catch {
            print("❌ Failed to save video: \(error)")
        }
    }
    
    private func generateVideoThumbnail(url: URL) async -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("❌ Failed to generate video thumbnail: \(error)")
            return nil
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
                
                // Video indicator
                if item.type == .video {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }
                        Spacer()
                    }
                    .frame(width: 110, height: 110)
                }
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

