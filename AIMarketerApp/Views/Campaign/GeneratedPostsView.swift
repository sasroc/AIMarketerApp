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
                                        colors: [Color.purple, Color.blue],
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
                    .foregroundColor(.purple)
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
    
    init(post: GeneratedPost) {
        self.post = post
        self._editedCaption = State(initialValue: post.caption)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.purple)
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button(action: { isEditing.toggle() }) {
                    Text(isEditing ? "Done" : "Edit")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                }
            }
            
            // Caption
            if isEditing {
                TextEditor(text: $editedCaption)
                    .frame(minHeight: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .scrollContentBackground(.hidden)
                    .onChange(of: isEditing) { newValue in
                        if !newValue {
                            campaignViewModel.updatePostCaption(postId: post.id, newCaption: editedCaption)
                        }
                    }
            } else {
                Text(post.caption)
                    .font(.body)
                    .foregroundColor(.white)
            }
            
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
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d 'at' h:mm a"
        return formatter.string(from: post.scheduledDate)
    }
}

#Preview {
    GeneratedPostsView()
        .environmentObject(CampaignViewModel())
}

