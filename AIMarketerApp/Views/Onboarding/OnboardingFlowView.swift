import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .categorySelection:
                BusinessCategorySelectionView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            case .customCategoryInput:
                CustomCategoryInputView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            case .welcome:
                WelcomeOnboardingView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            case .websiteInput:
                WebsiteInputView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            case .analyzing:
                WebsiteAnalysisLoadingView()
            case .results:
                BusinessAnalysisResultsView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            case .customInfoInput:
                CustomBusinessInfoView(viewModel: viewModel)
                    .environmentObject(authViewModel)
            }
        }
        .onChange(of: viewModel.currentStep) { newStep in
            // Save category when moving to welcome screen
            if newStep == .welcome && viewModel.selectedCategory != nil {
                Task {
                    try? await viewModel.saveCategory()
                }
            }
        }
    }
}

#Preview {
    OnboardingFlowView()
        .environmentObject(AuthenticationViewModel())
}

