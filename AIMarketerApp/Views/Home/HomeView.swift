import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @EnvironmentObject var analyticsViewModel: AnalyticsViewModel
    @State private var isFirstAppear = true
    @State private var periodicRefreshTask: Task<Void, Never>?
    
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
                        
                        // Performance section - always visible
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Performance")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                if analyticsViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .marketingPrimary))
                                        .scaleEffect(0.8)
                                } else {
                                    Button(action: {
                                        Task {
                                            await analyticsViewModel.refreshAnalytics(for: campaignViewModel.generatedPosts)
                                        }
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.subheadline)
                                            .foregroundColor(.marketingPrimary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            // Show overall metrics summary
                            PerformanceMetricsSummary(analyticsViewModel: analyticsViewModel)
                                .padding(.horizontal)
                            
                            // Show individual post analytics if available
                            if !postedPostsWithAnalytics.isEmpty {
                                ForEach(postedPostsWithAnalytics.prefix(5)) { post in
                                    if let analytics = analyticsViewModel.getAnalytics(for: post.id) {
                                        PostAnalyticsCard(post: post, analytics: analytics)
                                            .padding(.horizontal)
                                    }
                                }
                            } else if analyticsViewModel.isLoading {
                                // Loading state
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .marketingPrimary))
                                    Text("Loading analytics...")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                                .padding(.vertical, 20)
                                .padding(.horizontal)
                            } else {
                                // Empty state - no posts with analytics
                                EmptyStateView(
                                    icon: "chart.bar.fill",
                                    title: "No performance data yet",
                                    message: "Analytics will appear here once you post content through the app"
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Refresh data every time the view appears (except first time since init loads it)
                if !isFirstAppear {
                    Task {
                        await campaignViewModel.loadUserData()
                        await analyticsViewModel.loadAnalytics(for: campaignViewModel.generatedPosts)
                    }
                } else {
                    // Load analytics on first appear
                    Task {
                        await analyticsViewModel.loadAnalytics(for: campaignViewModel.generatedPosts)
                    }
                    // Start periodic refresh for analytics (every 2 minutes)
                    periodicRefreshTask = Task {
                        while !Task.isCancelled {
                            try? await Task.sleep(nanoseconds: 120_000_000_000) // 2 minutes
                            if !Task.isCancelled {
                                await analyticsViewModel.loadAnalytics(for: campaignViewModel.generatedPosts)
                            }
                        }
                    }
                }
                isFirstAppear = false
            }
            .onDisappear {
                // Stop periodic refresh when view disappears to save resources
                periodicRefreshTask?.cancel()
                periodicRefreshTask = nil
                analyticsViewModel.stopAutoRefresh()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PostsStatusChanged"))) { _ in
                // Refresh analytics when posts change status (e.g., scheduled -> posted)
                Task {
                    await analyticsViewModel.checkForNewPosts(currentPosts: campaignViewModel.generatedPosts)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Refresh analytics when app comes to foreground
                Task {
                    await campaignViewModel.refreshPostStatuses()
                    await analyticsViewModel.loadAnalytics(for: campaignViewModel.generatedPosts)
                }
            }
        }
    }
    
    private var scheduledPostsCount: Int {
        campaignViewModel.generatedPosts.filter { $0.status == .scheduled }.count
    }
    
    private var postedPostsCount: Int {
        campaignViewModel.generatedPosts.filter { $0.status == .posted }.count
    }
    
    private var postedPostsWithAnalytics: [GeneratedPost] {
        campaignViewModel.generatedPosts
            .filter { $0.status == .posted && $0.instagramPostId != nil }
            .sorted { ($0.publishedAt ?? $0.scheduledDate) > ($1.publishedAt ?? $1.scheduledDate) }
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

// MARK: - Analytics Components

struct PerformanceMetricsSummary: View {
    @ObservedObject var analyticsViewModel: AnalyticsViewModel
    
    var body: some View {
        // Calculate aggregate metrics from all analytics
        let totalMetrics = aggregateMetrics()
        
        VStack(spacing: 12) {
            // First row: Impressions, Reach, Engagement Rate
            HStack(spacing: 12) {
                PerformanceMetricBox(
                    icon: "eye.fill",
                    value: formatNumber(totalMetrics.impressions),
                    label: "Impressions",
                    color: .blue
                )
                
                PerformanceMetricBox(
                    icon: "person.2.fill",
                    value: formatNumber(totalMetrics.reach),
                    label: "Reach",
                    color: .purple
                )
                
                PerformanceMetricBox(
                    icon: "chart.line.uptrend.xyaxis",
                    value: String(format: "%.1f%%", totalMetrics.engagementRate),
                    label: "Engagement",
                    color: .green
                )
            }
            
            // Second row: Likes, Comments, Saves
            HStack(spacing: 12) {
                PerformanceMetricBox(
                    icon: "heart.fill",
                    value: formatNumber(totalMetrics.likes),
                    label: "Likes",
                    color: .red
                )
                
                PerformanceMetricBox(
                    icon: "bubble.left.fill",
                    value: formatNumber(totalMetrics.comments),
                    label: "Comments",
                    color: .orange
                )
                
                PerformanceMetricBox(
                    icon: "bookmark.fill",
                    value: formatNumber(totalMetrics.saves),
                    label: "Saves",
                    color: .yellow
                )
            }
        }
    }
    
    private func aggregateMetrics() -> (impressions: Int, reach: Int, likes: Int, comments: Int, saves: Int, engagementRate: Double) {
        let allAnalytics = analyticsViewModel.analytics.values
        
        let totalImpressions = allAnalytics.reduce(0) { $0 + $1.impressions }
        let totalReach = allAnalytics.reduce(0) { $0 + $1.reach }
        let totalLikes = allAnalytics.reduce(0) { $0 + $1.likes }
        let totalComments = allAnalytics.reduce(0) { $0 + $1.comments }
        let totalSaves = allAnalytics.reduce(0) { $0 + $1.saves }
        
        // Calculate average engagement rate
        let totalEngagement = totalLikes + totalComments + totalSaves
        let denominator = totalReach > 0 ? totalReach : (totalImpressions > 0 ? totalImpressions : 1)
        let avgEngagementRate = denominator > 0 ? (Double(totalEngagement) / Double(denominator)) * 100.0 : 0.0
        
        return (
            impressions: totalImpressions,
            reach: totalReach,
            likes: totalLikes,
            comments: totalComments,
            saves: totalSaves,
            engagementRate: avgEngagementRate
        )
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000.0)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000.0)
        } else {
            return "\(number)"
        }
    }
}

struct PerformanceMetricBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.marketingCardBackground)
        .cornerRadius(12)
    }
}

struct PostAnalyticsCard: View {
    let post: GeneratedPost
    let analytics: InstagramAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Post info header
            HStack(alignment: .top, spacing: 12) {
                // Post preview icon
                Image(systemName: "photo.fill")
                    .font(.title3)
                    .foregroundColor(.marketingPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.marketingPrimary.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.caption.prefix(50) + (post.caption.count > 50 ? "..." : ""))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if let publishedAt = post.publishedAt {
                        Text(publishedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Engagement rate badge
                VStack(spacing: 4) {
                    Text(String(format: "%.1f%%", analytics.engagementRate))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Engagement")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.marketingPrimary.opacity(0.2))
                .cornerRadius(8)
            }
            
            Divider()
                .background(Color.gray.opacity(0.3))
            
            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricItem(icon: "eye.fill", value: formatNumber(analytics.impressions), label: "Impressions", color: .blue)
                MetricItem(icon: "person.2.fill", value: formatNumber(analytics.reach), label: "Reach", color: .purple)
                MetricItem(icon: "heart.fill", value: formatNumber(analytics.likes), label: "Likes", color: .red)
                MetricItem(icon: "bubble.left.fill", value: formatNumber(analytics.comments), label: "Comments", color: .orange)
            }
            
            // Secondary metrics
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(formatNumber(analytics.saves))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Saves")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("\(formatNumber(analytics.shares))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Shares")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.marketingCardBackground)
        .cornerRadius(12)
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000.0)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000.0)
        } else {
            return "\(number)"
        }
    }
}

struct MetricItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationViewModel())
        .environmentObject(CampaignViewModel())
        .environmentObject(AnalyticsViewModel())
}

