import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var isFirstAppear = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Welcome header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome back,")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            Text(authViewModel.currentUser?.name ?? "User")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Stats cards
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Scheduled",
                                value: "\(scheduledPostsCount)",
                                icon: "calendar",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Posted",
                                value: "\(postedPostsCount)",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                        
                        // Drafts section
                        if !campaignViewModel.draftCampaigns.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Drafts")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    NavigationLink(destination: ScheduleView()) {
                                        Text("View All")
                                            .font(.subheadline)
                                            .foregroundColor(.marketingPrimary)
                                    }
                                }
                                .padding(.horizontal)
                                
                                ForEach(campaignViewModel.draftCampaigns.prefix(3)) { draft in
                                    DraftPreviewCard(draft: draft)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                        }
                        
                        // Recent posts section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Upcoming Posts")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                if !campaignViewModel.generatedPosts.isEmpty {
                                    NavigationLink(destination: ScheduleView()) {
                                        Text("View All")
                                            .font(.subheadline)
                                            .foregroundColor(.marketingPrimary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            if campaignViewModel.generatedPosts.isEmpty {
                                EmptyStateView(
                                    icon: "calendar.badge.plus",
                                    title: "No posts yet",
                                    message: "Create your first campaign to get started"
                                )
                                .padding(.horizontal)
                            } else {
                                ForEach(upcomingPosts.prefix(5)) { post in
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
                        }
                        .padding(.top, 8)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CreateCampaignView()) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                            Text("New Post")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.marketingPrimary)
                    }
                }
            }
            .onAppear {
                // Refresh data every time the view appears (except first time since init loads it)
                if !isFirstAppear {
                    Task {
                        await campaignViewModel.loadUserData()
                    }
                }
                isFirstAppear = false
            }
        }
    }
    
    private var scheduledPostsCount: Int {
        campaignViewModel.generatedPosts.filter { $0.status == .scheduled }.count
    }
    
    private var postedPostsCount: Int {
        campaignViewModel.generatedPosts.filter { $0.status == .posted }.count
    }
    
    private var upcomingPosts: [GeneratedPost] {
        campaignViewModel.generatedPosts
            .filter { $0.status == .scheduled || $0.status == .pending }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.marketingCardBackground)
        .cornerRadius(16)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct DraftPreviewCard: View {
    let draft: DraftCampaign
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    
    var body: some View {
        NavigationLink(destination: CreateCampaignView()) {
            HStack(spacing: 12) {
                // Draft icon
                Image(systemName: "doc.text")
                    .font(.title2)
                    .foregroundColor(.marketingPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.marketingPrimary.opacity(0.1))
                    .cornerRadius(8)
                
                // Draft info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Draft Campaign")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Step \(draft.currentStep + 1) of 4")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if !draft.marketingPlan.description.isEmpty {
                        Text(draft.marketingPlan.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Navigation arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.marketingCardBackground)
            .cornerRadius(12)
        }
        .simultaneousGesture(TapGesture().onEnded {
            campaignViewModel.loadDraft(draft)
        })
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(CampaignViewModel())
}

