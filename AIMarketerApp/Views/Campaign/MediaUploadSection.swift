import SwiftUI
import PhotosUI
import AVFoundation
import UniformTypeIdentifiers

struct MediaUploadSection: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isLoadingSavedMedia = false
    
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
            
            // Saved Media Section
            if !campaignViewModel.allSavedMediaItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Saved Media")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Tap to select from your previously uploaded media")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(campaignViewModel.allSavedMediaItems) { item in
                                SavedMediaItemView(
                                    item: item,
                                    isSelected: campaignViewModel.mediaItems.contains(where: { $0.id == item.id }),
                                    onSelect: {
                                        campaignViewModel.selectSavedMediaItem(item)
                                    },
                                    onDelete: {
                                        campaignViewModel.deleteMediaItemFromDatabase(item)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
            
            // Selected Media grid
            if !campaignViewModel.mediaItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected Media")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(campaignViewModel.mediaItems) { item in
                            MediaItemView(
                                item: item,
                                isSavedItem: campaignViewModel.allSavedMediaItems.contains(where: { $0.id == item.id })
                            ) {
                                // If it's a saved item, only remove from selection
                                // Otherwise, delete from database (newly uploaded item)
                                if campaignViewModel.allSavedMediaItems.contains(where: { $0.id == item.id }) {
                                    campaignViewModel.removeMediaItemFromSelection(item)
                                } else {
                                    campaignViewModel.removeMediaItem(item)
                                }
                            }
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
        .onAppear {
            // Load saved media when view appears
            if campaignViewModel.allSavedMediaItems.isEmpty {
                Task {
                    isLoadingSavedMedia = true
                    await campaignViewModel.loadAllSavedMedia()
                    isLoadingSavedMedia = false
                }
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
    let isSavedItem: Bool
    let onDelete: () -> Void
    
    init(item: MediaItem, isSavedItem: Bool = false, onDelete: @escaping () -> Void) {
        self.item = item
        self.isSavedItem = isSavedItem
        self.onDelete = onDelete
    }
    
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
            } else if let cloudURL = item.cloudURL, let url = URL(string: cloudURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 110, height: 110)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipped()
                            .cornerRadius(12)
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
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
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 110, height: 110)
            .overlay(
                Image(systemName: item.type == .video ? "video" : "photo")
                    .foregroundColor(.gray)
            )
    }
}

struct SavedMediaItemView: View {
    let item: MediaItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Select button (tappable area)
            Button(action: onSelect) {
                ZStack(alignment: .topTrailing) {
                    // Media preview
                    Group {
                        if let thumbnail = item.thumbnail {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .cornerRadius(12)
                        } else if let cloudURL = item.cloudURL, let url = URL(string: cloudURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 100, height: 100)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(12)
                                case .failure:
                                    placeholderView
                                @unknown default:
                                    placeholderView
                                }
                            }
                        } else {
                            placeholderView
                        }
                    }
                    
                    // Selection indicator
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.marketingPrimary, lineWidth: 3)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .fill(Color.marketingPrimary)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .bold))
                            )
                            .padding(6)
                    }
                    
                    // Video indicator
                    if item.type == .video {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .shadow(radius: 2)
                                Spacer()
                            }
                            .padding(6)
                        }
                        .frame(width: 100, height: 100)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Delete button (garbage can icon) - positioned at top trailing
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.red.opacity(0.9))
                    .clipShape(Circle())
            }
            .padding(4)
        }
        .alert("Delete Media", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete selected media from database?")
        }
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: item.type == .video ? "video" : "photo")
                    .foregroundColor(.gray)
            )
    }
}

#Preview {
    MediaUploadSection()
        .environmentObject(CampaignViewModel())
        .padding()
        .background(Color.black)
}

