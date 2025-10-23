import SwiftUI

struct MainTabView: View {
    @StateObject private var campaignViewModel = CampaignViewModel()
    
    var body: some View {
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
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}

