import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var selectedFilter: PostStatus?
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterButton(
                                title: "All",
                                isSelected: selectedFilter == nil,
                                count: campaignViewModel.generatedPosts.count
                            ) {
                                selectedFilter = nil
                            }
                            
                            ForEach([PostStatus.scheduled, .draft, .posted, .failed], id: \.self) { status in
                                FilterButton(
                                    title: status.rawValue,
                                    isSelected: selectedFilter == status,
                                    count: status == .draft ? campaignViewModel.draftCampaigns.count : filteredPosts(for: status).count
                                ) {
                                    selectedFilter = status
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(Color.black)
                    
                    // Posts list
                    if (selectedFilter == .draft && campaignViewModel.draftCampaigns.isEmpty) || 
                       (selectedFilter != .draft && filteredPosts.isEmpty) {
                        EmptyStateView(
                            icon: selectedFilter == .draft ? "doc.text" : "calendar.badge.exclamationmark",
                            title: selectedFilter == .draft ? "No drafts" : "No posts",
                            message: selectedFilter == nil
                                ? "Create a campaign to get started"
                                : selectedFilter == .draft
                                ? "Save a draft to see it here"
                                : "No posts with this status"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Refresh indicator
                                if let lastRefresh = campaignViewModel.lastRefreshTime {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .font(.caption)
                                        Text("Updated \(timeAgoString(from: lastRefresh))")
                                            .font(.caption)
                                        Spacer()
                                        if isRefreshing {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                        }
                                    }
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                }
                                
                                if selectedFilter == .draft {
                                    ForEach(campaignViewModel.draftCampaigns) { draft in
                                        DraftCard(draft: draft)
                                            .padding(.horizontal)
                                    }
                                } else {
                                    ForEach(filteredPosts) { post in
                                        EditablePostCard(post: post)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                        .refreshable {
                            await refreshPosts()
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Start auto-refresh when view appears
                campaignViewModel.startAutoRefresh()
                
                // Do an immediate refresh
                Task {
                    await campaignViewModel.refreshPostStatuses()
                }
            }
            .onDisappear {
                // Stop auto-refresh when view disappears to save resources
                campaignViewModel.stopAutoRefresh()
            }
        }
    }
    
    private func refreshPosts() async {
        isRefreshing = true
        await campaignViewModel.refreshPostStatuses()
        isRefreshing = false
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else {
            let hours = seconds / 3600
            return "\(hours)h ago"
        }
    }
    
    private var filteredPosts: [GeneratedPost] {
        if let filter = selectedFilter {
            if filter == .draft {
                return [] // Drafts are handled separately in the view
            }
            return filteredPosts(for: filter)
        }
        return campaignViewModel.generatedPosts.sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    private func filteredPosts(for status: PostStatus) -> [GeneratedPost] {
        campaignViewModel.generatedPosts
            .filter { $0.status == status }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.marketingPrimary.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.marketingPrimary : Color.marketingCardBackground)
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
        }
    }
}

struct DraftCard: View {
    let draft: DraftCampaign
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.marketingPrimary)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Draft Campaign")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Step \(draft.currentStep + 1) of 4")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            if !draft.marketingPlan.description.isEmpty {
                Text(draft.marketingPlan.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            HStack {
                Label("\(draft.mediaItems.count) media items", systemImage: "photo")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if !draft.schedule.selectedDays.isEmpty {
                    Label("\(draft.schedule.selectedDays.count) days", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 12) {
                NavigationLink(destination: CreateCampaignView()) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Continue")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.marketingPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.marketingPrimary.opacity(0.1))
                    .cornerRadius(8)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    campaignViewModel.loadDraft(draft)
                })
                
                Button(action: { campaignViewModel.deleteDraft(draft) }) {
                    Image(systemName: "trash")
                        .foregroundColor(.marketingError)
                        .padding(8)
                        .background(Color.marketingError.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.marketingCardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    ScheduleView()
        .environmentObject(CampaignViewModel())
}

