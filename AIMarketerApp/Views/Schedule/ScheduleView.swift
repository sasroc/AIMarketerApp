import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var selectedFilter: PostStatus?
    
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
                            
                            ForEach([PostStatus.scheduled, .pending, .posted, .failed], id: \.self) { status in
                                FilterButton(
                                    title: status.rawValue,
                                    isSelected: selectedFilter == status,
                                    count: filteredPosts(for: status).count
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
                    if filteredPosts.isEmpty {
                        EmptyStateView(
                            icon: "calendar.badge.exclamationmark",
                            title: "No posts",
                            message: selectedFilter == nil
                                ? "Create a campaign to get started"
                                : "No posts with this status"
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredPosts) { post in
                                    PostPreviewCard(post: post)
                                        .padding(.horizontal)
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
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var filteredPosts: [GeneratedPost] {
        if let filter = selectedFilter {
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
                        .background(isSelected ? Color.white.opacity(0.3) : Color.purple.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.purple : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(20)
        }
    }
}

#Preview {
    ScheduleView()
        .environmentObject(CampaignViewModel())
}

