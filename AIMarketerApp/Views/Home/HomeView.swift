import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    
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
                                            .foregroundColor(.purple)
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
        .background(Color.gray.opacity(0.1))
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

#Preview {
    HomeView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(CampaignViewModel())
}

