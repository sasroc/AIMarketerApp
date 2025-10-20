import SwiftUI

struct MainTabView: View {
    @StateObject private var campaignViewModel = CampaignViewModel()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            CreateCampaignView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
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
        .tint(.purple)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationViewModel())
}

