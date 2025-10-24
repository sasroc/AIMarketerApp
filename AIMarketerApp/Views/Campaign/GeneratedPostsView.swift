import SwiftUI

struct GeneratedPostsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var showingScheduleConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if campaignViewModel.isGenerating {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.purple)
                        
                        Text("Generating posts with AI...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("This may take a moment")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            VStack(spacing: 8) {
                                Text("\(campaignViewModel.generatedPosts.count) Posts Generated")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Review and edit captions before scheduling")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 20)
                            
                            // Posts list
                            ForEach(campaignViewModel.generatedPosts) { post in
                                EditablePostCard(post: post)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                campaignViewModel.deletePost(post)
                                            }
                                        } label: {
                                            Label("Delete Post", systemImage: "trash")
                                        }
                                    }
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding()
                    }
                    
                    // Schedule button
                    VStack {
                        Spacer()
                        
                        Button(action: { showingScheduleConfirmation = true }) {
                            Text("Schedule All Posts")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.marketingPrimary, Color.marketingSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }
                        .padding()
                        .background(Color.black)
                    }
                }
            }
            .navigationTitle("Generated Posts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.marketingPrimary)
                }
            }
            .alert("Schedule Posts", isPresented: $showingScheduleConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Schedule") {
                    schedulePosts()
                }
            } message: {
                Text("Are you sure you want to schedule all \(campaignViewModel.generatedPosts.count) posts?")
            }
        }
    }
    
    private func schedulePosts() {
        campaignViewModel.scheduleAllPosts()
        dismiss()
    }
}

struct EditablePostCard: View {
    let post: GeneratedPost
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var isEditing = false
    @State private var editedCaption: String
    @FocusState private var isTextEditorFocused: Bool
    @State private var showingDeleteConfirmation = false
    
    init(post: GeneratedPost) {
        self.post = post
        self._editedCaption = State(initialValue: post.caption)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and buttons
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundColor(.marketingPrimary)
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Edit button
                    Button(action: {
                        toggleEdit()
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.marketingPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
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
                        Image(systemName: "trash")
                            .foregroundColor(.marketingError)
                            .font(.system(size: 16, weight: .medium))
                            .padding(8)
                            .background(Color.marketingError.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Caption content
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
            
            // Media preview
            if let mediaItem = campaignViewModel.mediaItems.first(where: { $0.id == post.mediaItemId }) {
                Group {
                    if let thumbnail = mediaItem.thumbnail {
                        // Display local thumbnail if available
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(12)
                            .allowsHitTesting(false)
                            .onAppear {
                                print("🖼️ Displaying local thumbnail for post: \(post.id)")
                            }
                    } else if let cloudURL = mediaItem.cloudURL, let url = URL(string: cloudURL) {
                        // Display from cloud URL
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(12)
                                    .onAppear {
                                        print("⏳ Loading image from cloud: \(cloudURL)")
                                    }
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                                    .allowsHitTesting(false)
                                    .onAppear {
                                        print("✅ Successfully loaded image from cloud for post: \(post.id)")
                                    }
                            case .failure(let error):
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
                                .onAppear {
                                    print("❌ Failed to load image from cloud: \(cloudURL)")
                                    print("   Error: \(error)")
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        // Fallback placeholder
                        VStack {
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                            Text("No image")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(12)
                        .onAppear {
                            print("⚠️ No image source for post: \(post.id)")
                            print("   Media item has no thumbnail or cloud URL")
                        }
                    }
                }
            } else {
                // No media item found
                VStack {
                    Image(systemName: "photo.slash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.red)
                    Text("Media not found")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(12)
                .onAppear {
                    print("❌ No media item found for post: \(post.id)")
                    print("   Post media_item_id: \(post.mediaItemId)")
                    print("   Available media items: \(campaignViewModel.mediaItems.map { $0.id })")
                }
            }
        }
        .frame(maxWidth: .infinity)
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
}

// Simple TextEditor that works reliably
struct SimpleTextEditor: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.white
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.delegate = context.coordinator
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .yes
        textView.keyboardAppearance = .dark
        textView.returnKeyType = .default
        textView.text = text
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.textContainer.lineFragmentPadding = 0
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        if textView.text != text {
            textView.text = text
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SimpleTextEditor
        
        init(_ parent: SimpleTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            // Move cursor to end when editing starts
            DispatchQueue.main.async {
                let endPosition = textView.endOfDocument
                if let newRange = textView.textRange(from: endPosition, to: endPosition) {
                    textView.selectedTextRange = newRange
                }
            }
        }
    }
}

#Preview {
    GeneratedPostsView()
        .environmentObject(CampaignViewModel())
}

