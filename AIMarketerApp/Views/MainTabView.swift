import SwiftUI

struct MainTabView: View {
    @StateObject private var campaignViewModel = CampaignViewModel()
    @State private var showingCreateCampaign = false
    @State private var hasRequestedNotifications = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                ScheduleView()
                    .tabItem {
                        Label("Schedule", systemImage: "calendar")
                    }
                
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
            }
            .environmentObject(campaignViewModel)
            .tint(.marketingPrimary)
            
            // + button attached to top right of tab bar
            Button(action: {
                showingCreateCampaign = true
            }) {
                Image(systemName: "plus")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(
                            colors: [Color.marketingPrimary, Color.marketingSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(.trailing, 24)
            .offset(x: -20) // Move button to the left
            .padding(.bottom, 49 - 26) // 49 = tab bar height, 26 = half button (52/2), positions center at top edge of tab bar
        }
        .sheet(isPresented: $showingCreateCampaign) {
            CampaignTypeSelectionView()
                .environmentObject(campaignViewModel)
        }
        .task {
            requestNotificationAuthorization()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}

private extension MainTabView {
    func requestNotificationAuthorization() {
        guard !hasRequestedNotifications else { return }
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }
        hasRequestedNotifications = true
        NotificationManager.shared.requestAuthorizationIfNeeded()
    }
}

