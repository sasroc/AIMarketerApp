import SwiftUI

struct MediaSelectorSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    
    let post: GeneratedPost
    let maxSelection: Int
    let onSave: ([String]) -> Void
    
    @State private var selectedMediaIds: Set<String>
    @State private var mediaUsageCount: [String: Int] = [:]
    @State private var isLoadingSavedMedia = false
    
    init(post: GeneratedPost, maxSelection: Int = 10, onSave: @escaping ([String]) -> Void) {
        self.post = post
        self.maxSelection = maxSelection
        self.onSave = onSave
        self._selectedMediaIds = State(initialValue: Set(post.mediaItemIds))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Instructions
                        VStack(spacing: 8) {
                            Text("Select up to \(maxSelection) image\(maxSelection == 1 ? "" : "s") for this post")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            Text("\(selectedMediaIds.count) / \(maxSelection) selected")
                                .font(.caption)
                                .foregroundColor(selectedMediaIds.count == maxSelection ? .marketingPrimary : .gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedMediaIds.count == maxSelection ? Color.marketingPrimary.opacity(0.2) : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding(.top, 20)
                        
                        // Media grid - show all saved media items
                        if isLoadingSavedMedia {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if campaignViewModel.allSavedMediaItems.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("No saved media found")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ForEach(campaignViewModel.allSavedMediaItems) { mediaItem in
                                    MediaSelectButton(
                                        mediaItem: mediaItem,
                                        isSelected: selectedMediaIds.contains(mediaItem.id),
                                        usageCount: mediaUsageCount[mediaItem.id] ?? 0,
                                        isCurrentPost: post.mediaItemIds.contains(mediaItem.id)
                                    ) {
                                        toggleSelection(mediaItem.id)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Save button
                VStack {
                    Spacer()
                    
                    Button(action: saveSelection) {
                        Text("Save Selection")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Group {
                                    if selectedMediaIds.isEmpty {
                                        Color.gray
                                    } else {
                                        LinearGradient(
                                            colors: [Color.marketingPrimary, Color.marketingSecondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .cornerRadius(16)
                    }
                    .disabled(selectedMediaIds.isEmpty)
                    .padding()
                    .background(Color.black)
                }
            }
            .navigationTitle("Select Media")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.marketingPrimary)
                }
            }
        }
        .onAppear {
            // Load saved media if not already loaded
            if campaignViewModel.allSavedMediaItems.isEmpty {
                Task {
                    isLoadingSavedMedia = true
                    await campaignViewModel.loadAllSavedMedia()
                    isLoadingSavedMedia = false
                    calculateUsageCount()
                }
            } else {
                calculateUsageCount()
            }
        }
    }
    
    private func toggleSelection(_ mediaId: String) {
        if selectedMediaIds.contains(mediaId) {
            selectedMediaIds.remove(mediaId)
        } else {
            if selectedMediaIds.count < maxSelection {
                selectedMediaIds.insert(mediaId)
            }
        }
    }
    
    private func saveSelection() {
        // Get selected media items from all saved media items
        let orderedSelection = campaignViewModel.allSavedMediaItems
            .filter { selectedMediaIds.contains($0.id) }
            .map { $0.id }
        onSave(orderedSelection)
        dismiss()
    }
    
    private func calculateUsageCount() {
        var counts: [String: Int] = [:]
        for p in campaignViewModel.generatedPosts {
            // Skip current post when counting
            if p.id == post.id { continue }
            
            for mediaId in p.mediaItemIds {
                counts[mediaId, default: 0] += 1
            }
        }
        mediaUsageCount = counts
    }
}

struct MediaSelectButton: View {
    let mediaItem: MediaItem
    let isSelected: Bool
    let usageCount: Int
    let isCurrentPost: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // Media preview
                Group {
                    if let thumbnail = mediaItem.thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipped()
                            .cornerRadius(12)
                    } else if let cloudURL = mediaItem.cloudURL, let url = URL(string: cloudURL) {
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
                }
                
                // Selection overlay
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.marketingPrimary, lineWidth: 3)
                        .frame(width: 110, height: 110)
                    
                    Circle()
                        .fill(Color.marketingPrimary)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 14, weight: .bold))
                        )
                        .padding(6)
                }
                
                // Usage indicator (bottom left)
                if usageCount > 0 {
                    VStack {
                        Spacer()
                        HStack {
                            Text("\(usageCount)×")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(6)
                            Spacer()
                        }
                    }
                    .frame(width: 110, height: 110)
                    .padding(6)
                }
                
                // Video indicator
                if mediaItem.type == .video {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                        .frame(width: 110, height: 110)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 110, height: 110)
            .overlay(
                Image(systemName: mediaItem.type == .video ? "video" : "photo")
                    .foregroundColor(.gray)
            )
    }
}

#Preview {
    MediaSelectorSheet(
        post: GeneratedPost(
            caption: "Test post",
            mediaItemIds: [],
            scheduledDate: Date(),
            status: .pending
        ),
        maxSelection: 3
    ) { _ in }
    .environmentObject(CampaignViewModel())
}

