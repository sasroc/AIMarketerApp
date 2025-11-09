import SwiftUI

struct WelcomeOnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingWebsiteInput = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Welcome Header
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 60))
                            .foregroundColor(.marketingPrimary)
                        
                        Text("Welcome \(authViewModel.currentUser?.name ?? "")!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Let's generate some posts")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 40)
                    
                    // Options
                    VStack(spacing: 16) {
                        Button(action: {
                            showingWebsiteInput = true
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.title3)
                                Text("Enter Business Website")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.marketingPrimary, Color.marketingSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            viewModel.currentStep = .customInfoInput
                        }) {
                            Text("Continue without website")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 32)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingWebsiteInput) {
                WebsiteInputView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    WelcomeOnboardingView(viewModel: OnboardingViewModel())
        .environmentObject(AuthenticationViewModel())
}

