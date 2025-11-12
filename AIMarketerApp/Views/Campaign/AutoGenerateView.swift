import SwiftUI

struct AutoGenerateView: View {
    @StateObject private var viewModel = AutoGenerateViewModel()
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var showGeneratedPosts = false
    @State private var shouldDismissToHome = false
    @State private var hasStartedGeneration = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Progress Indicator
                    VStack(spacing: 24) {
                        // Animated Icon
                        ZStack {
                            Circle()
                                .stroke(Color.marketingPrimary.opacity(0.2), lineWidth: 4)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: progressValue)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.marketingPrimary, Color.marketingSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.3), value: progressValue)
                            
                            Image(systemName: iconForStep)
                                .font(.system(size: 40))
                                .foregroundColor(.marketingPrimary)
                        }
                        
                        // Progress Message
                        VStack(spacing: 12) {
                            Text(viewModel.progressMessage)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            if viewModel.currentStep != .completed {
                                Text("This may take a few minutes...")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        // Progress Steps
                        VStack(alignment: .leading, spacing: 12) {
                            ProgressStepRow(
                                title: "Loading business data",
                                isCompleted: viewModel.completedSteps.contains(.loadingProfile),
                                isActive: viewModel.currentStep == .loadingProfile && !viewModel.completedSteps.contains(.loadingProfile)
                            )
                            
                            ProgressStepRow(
                                title: "Generating images",
                                isCompleted: viewModel.completedSteps.contains(.generatingImages),
                                isActive: viewModel.currentStep == .generatingImages && !viewModel.completedSteps.contains(.generatingImages)
                            )
                            
                            ProgressStepRow(
                                title: "Creating captions",
                                isCompleted: viewModel.completedSteps.contains(.generatingCaptions),
                                isActive: viewModel.currentStep == .generatingCaptions && !viewModel.completedSteps.contains(.generatingCaptions)
                            )
                            
                            ProgressStepRow(
                                title: "Saving posts",
                                isCompleted: viewModel.completedSteps.contains(.saving),
                                isActive: viewModel.currentStep == .saving && !viewModel.completedSteps.contains(.saving)
                            )
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 40)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Success Message
                    if viewModel.currentStep == .completed {
                        VStack(spacing: 16) {
                            Text("✅ Success!")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.marketingSuccess)
                            
                            Text("Generated \(viewModel.generatedPosts.count) post for today") // Testing: 1 day
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .onAppear {
                            // Load posts into campaign view model and show generated posts view
                            Task {
                                // First, update campaign view model with generated posts
                                campaignViewModel.generatedPosts = viewModel.generatedPosts
                                
                                // Load all media items from database
                                do {
                                    let supabaseService = SupabaseService.shared
                                    let allMedia = try await supabaseService.fetchMediaItems()
                                    
                                    // Filter media items that are referenced by the generated posts
                                    let mediaItemIds = Set(viewModel.generatedPosts.flatMap { $0.mediaItemIds.map { $0.lowercased() } })
                                    campaignViewModel.mediaItems = allMedia.filter { mediaItemIds.contains($0.id.lowercased()) }
                                    
                                    print("✅ Loaded \(campaignViewModel.mediaItems.count) media items for generated posts")
                                } catch {
                                    print("⚠️ Failed to load media items: \(error)")
                                }
                                
                                // Small delay to ensure UI updates
                                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                                
                                // Show the generated posts view
                                showGeneratedPosts = true
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // If posts were generated, show them instead of just dismissing
                        if !viewModel.generatedPosts.isEmpty {
                            Task {
                                // Update campaign view model with generated posts
                                campaignViewModel.generatedPosts = viewModel.generatedPosts
                                
                                // Load media items
                                do {
                                    let supabaseService = SupabaseService.shared
                                    let allMedia = try await supabaseService.fetchMediaItems()
                                    let mediaItemIds = Set(viewModel.generatedPosts.flatMap { $0.mediaItemIds.map { $0.lowercased() } })
                                    campaignViewModel.mediaItems = allMedia.filter { mediaItemIds.contains($0.id.lowercased()) }
                                } catch {
                                    print("⚠️ Failed to load media items: \(error)")
                                }
                                
                                showGeneratedPosts = true
                            }
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.marketingPrimary)
                    .disabled(viewModel.isLoading && viewModel.generatedPosts.isEmpty)
                }
            }
            .task {
                // Only start generation once
                if !hasStartedGeneration && !viewModel.isLoading && viewModel.generatedPosts.isEmpty {
                    hasStartedGeneration = true
                    await viewModel.generateWeekOfPosts()
                }
            }
            .sheet(isPresented: $showGeneratedPosts) {
                GeneratedPostsView(shouldDismissToHome: $shouldDismissToHome)
                    .environmentObject(campaignViewModel)
                    .onDisappear {
                        if shouldDismissToHome {
                            dismiss()
                        }
                    }
            }
        }
    }
    
    private var progressValue: Double {
        switch viewModel.currentStep {
        case .loadingProfile: return 0.25
        case .generatingImages: return 0.5
        case .generatingCaptions: return 0.75
        case .saving: return 0.9
        case .completed: return 1.0
        }
    }
    
    private var iconForStep: String {
        switch viewModel.currentStep {
        case .loadingProfile: return "doc.text.fill"
        case .generatingImages: return "photo.fill"
        case .generatingCaptions: return "text.bubble.fill"
        case .saving: return "square.and.arrow.down.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
}

struct ProgressStepRow: View {
    let title: String
    let isCompleted: Bool
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.marketingSuccess)
            } else if isActive {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .marketingPrimary))
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(isCompleted || isActive ? .white : .gray)
        }
    }
}

#Preview {
    AutoGenerateView()
        .environmentObject(CampaignViewModel())
}

