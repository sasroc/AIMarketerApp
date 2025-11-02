import SwiftUI
import PhotosUI

struct AIImageGenerationSection: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var prompt: String = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var sourceImage: UIImage?
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var selectedSize: ImageSize = .square
    @State private var generatedImage: UIImage?
    @State private var showingPreview = false
    @FocusState private var isPromptFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Compact Header
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.title3)
                    .foregroundColor(.marketingPrimary)
                Text("AI Image Generator")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Mode tabs
            HStack(spacing: 0) {
                Button(action: {
                    sourceImage = nil
                    selectedImage = nil
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.subheadline)
                        Text("Generate")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(sourceImage == nil ? Color.marketingPrimary : Color.clear)
                    .foregroundColor(sourceImage == nil ? .white : .gray)
                }
                
                Button(action: {
                    // Edit mode - will trigger photo picker
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "paintbrush")
                            .font(.subheadline)
                        Text("Edit")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(sourceImage != nil ? Color.marketingPrimary : Color.clear)
                    .foregroundColor(sourceImage != nil ? .white : .gray)
                }
            }
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            
            // Image picker for edit mode
            if sourceImage == nil {
                PhotosPicker(
                    selection: $selectedImage,
                    matching: .images
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.subheadline)
                        Text("Select Image to Edit")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.marketingPrimary.opacity(0.15))
                    .foregroundColor(.marketingPrimary)
                    .cornerRadius(10)
                }
                .onChange(of: selectedImage) { newItem in
                    loadSelectedImage(from: newItem)
                }
            }
            
            // Source image preview (for edit mode)
            if let unwrappedSourceImage = sourceImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: unwrappedSourceImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(10)
                    
                    Button(action: {
                        sourceImage = nil
                        selectedImage = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
            }
            
            // Prompt input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(sourceImage == nil ? "What do you want to create?" : "How should we edit it?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                ZStack(alignment: .topLeading) {
                    if prompt.isEmpty {
                        Text(sourceImage == nil ? 
                            "A modern minimalist product photo..." :
                            "Add warm lighting and vibrant colors...")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $prompt)
                        .focused($isPromptFocused)
                        .font(.subheadline)
                        .frame(minHeight: 80)
                        .padding(8)
                        .scrollContentBackground(.hidden)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isPromptFocused ? Color.marketingPrimary : Color.gray.opacity(0.2), lineWidth: 1.5)
                        )
                }
            }
            
            // Error message
            if let errorMessage = errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                    Text(errorMessage)
                        .font(.caption)
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.15))
                .cornerRadius(8)
            }
            
            // Generate button
            Button(action: generateImage) {
                HStack(spacing: 8) {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.85)
                            .tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.subheadline)
                    }
                    Text(isGenerating ? "Generating..." : (sourceImage == nil ? "Generate Image" : "Edit Image"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.marketingPrimary, Color.marketingSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isGenerating || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity((isGenerating || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1)
        }
        .padding(18)
        .background(Color.marketingCardBackground)
        .cornerRadius(14)
        .sheet(isPresented: $showingPreview) {
            if let generatedImage = generatedImage {
                GeneratedImagePreviewSheet(
                    image: generatedImage,
                    prompt: prompt,
                    onSave: {
                        addGeneratedImageToMedia()
                        showingPreview = false
                    },
                    onCancel: {
                        showingPreview = false
                    }
                )
            }
        }
    }
    
    private func loadSelectedImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    sourceImage = image
                }
            }
        }
    }
    
    private func generateImage() {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a prompt"
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let result: GeneratedImageResult
                
                if let sourceImage = sourceImage {
                    // Edit mode
                    result = try await AIImageGenerationService.shared.editImage(
                        prompt: prompt,
                        sourceImage: sourceImage
                    )
                } else {
                    // Generate mode
                    result = try await AIImageGenerationService.shared.generateImage(
                        prompt: prompt,
                        size: selectedSize
                    )
                }
                
                await MainActor.run {
                    generatedImage = result.image
                    showingPreview = true
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
    
    private func addGeneratedImageToMedia() {
        guard let generatedImage = generatedImage else { return }
        
        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            if let data = generatedImage.jpegData(compressionQuality: 0.8) {
                try data.write(to: fileURL)
                
                let mediaItem = MediaItem(
                    type: .image,
                    thumbnail: generatedImage,
                    localURL: fileURL
                )
                
                campaignViewModel.addMediaItem(mediaItem)
                
                // Reset form
                prompt = ""
                sourceImage = nil
                selectedImage = nil
                self.generatedImage = nil
            }
        } catch {
            errorMessage = "Failed to save generated image: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Views

struct GeneratedImagePreviewSheet: View {
    let image: UIImage
    let prompt: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Generated image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding()
                    
                    // Prompt used
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generated from prompt:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: onCancel) {
                            Text("Discard")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: onSave) {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Use Image")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.marketingPrimary, Color.marketingSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Generated Image")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AIImageGenerationSection()
        .environmentObject(CampaignViewModel())
        .padding()
        .background(Color.black)
}

