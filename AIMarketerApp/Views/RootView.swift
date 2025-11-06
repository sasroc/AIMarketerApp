import SwiftUI

struct RootView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @State private var isCheckingOnboarding = false
    @State private var showOnboarding = false
    
    // Notification name for onboarding completion
    static let onboardingCompletedNotification = Notification.Name("OnboardingCompleted")
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                if isCheckingOnboarding {
                    // Show loading while checking onboarding status
                    ZStack {
                        Color.black.ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .marketingPrimary))
                    }
                    .task {
                        await checkOnboardingStatus()
                    }
                } else if showOnboarding {
                    OnboardingFlowView()
                        .environmentObject(authViewModel)
                } else {
                    MainTabView()
                }
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .animation(.easeInOut, value: showOnboarding)
        .onChange(of: authViewModel.isAuthenticated) { isAuthenticated in
            // Reset onboarding state when authentication changes
            if isAuthenticated {
                // User just signed in - check onboarding status
                isCheckingOnboarding = true
                showOnboarding = false
            } else {
                // User signed out - reset onboarding state
                isCheckingOnboarding = false
                showOnboarding = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: RootView.onboardingCompletedNotification)) { _ in
            // Refresh onboarding status when completed
            Task {
                await checkOnboardingStatus()
            }
        }
    }
    
    private func checkOnboardingStatus() async {
        // Only check if authenticated
        guard authViewModel.isAuthenticated else {
            await MainActor.run {
                isCheckingOnboarding = false
                showOnboarding = false
            }
            return
        }
        
        do {
            let completed = try await onboardingViewModel.checkOnboardingStatus()
            await MainActor.run {
                showOnboarding = !completed
                isCheckingOnboarding = false
            }
        } catch {
            print("Error checking onboarding status: \(error)")
            
            // Check if error indicates user doesn't exist (invalid session)
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("not found") || 
               errorString.contains("invalid") || 
               errorString.contains("unauthorized") ||
               errorString.contains("jwt") {
                // User was deleted or session is invalid - sign them out
                print("⚠️ Invalid session detected - signing out user")
                Task {
                    do {
                        try await authViewModel.signOut()
                    } catch {
                        print("Error signing out: \(error)")
                    }
                }
            }
            
            // If check fails, assume onboarding is needed (but only if still authenticated)
            await MainActor.run {
                if authViewModel.isAuthenticated {
                    showOnboarding = true
                }
                isCheckingOnboarding = false
            }
        }
    }
}

