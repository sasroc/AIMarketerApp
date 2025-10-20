import SwiftUI

struct CreateCampaignView: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var showingGeneratedPosts = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress indicator
                        ProgressSteps(currentStep: $campaignViewModel.currentStep)
                            .padding(.top, 20)
                        
                        // Step content
                        Group {
                            switch campaignViewModel.currentStep {
                            case 0:
                                MediaUploadSection()
                            case 1:
                                MarketingPlanSection()
                            case 2:
                                SchedulingSection()
                            case 3:
                                ContentGuidelinesSection()
                            default:
                                MediaUploadSection()
                            }
                        }
                        .padding(.horizontal)
                        
                        // Navigation buttons
                        HStack(spacing: 16) {
                            if campaignViewModel.currentStep > 0 {
                                Button(action: previousStep) {
                                    HStack {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            
                            Button(action: nextStep) {
                                HStack {
                                    Text(campaignViewModel.currentStep == 3 ? "Generate Posts" : "Next")
                                    if campaignViewModel.currentStep < 3 {
                                        Image(systemName: "chevron.right")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.purple, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!canProceed)
                            .opacity(canProceed ? 1 : 0.5)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Create Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { campaignViewModel.resetCampaign() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.purple)
                    }
                }
            }
            .sheet(isPresented: $showingGeneratedPosts) {
                GeneratedPostsView()
            }
        }
    }
    
    private var canProceed: Bool {
        switch campaignViewModel.currentStep {
        case 0:
            return !campaignViewModel.mediaItems.isEmpty
        case 1:
            return !campaignViewModel.marketingPlan.description.isEmpty
        case 2:
            return !campaignViewModel.schedule.selectedDays.isEmpty
        case 3:
            return true
        default:
            return false
        }
    }
    
    private func previousStep() {
        withAnimation {
            campaignViewModel.currentStep = max(0, campaignViewModel.currentStep - 1)
        }
    }
    
    private func nextStep() {
        if campaignViewModel.currentStep == 3 {
            generatePosts()
        } else {
            withAnimation {
                campaignViewModel.currentStep = min(3, campaignViewModel.currentStep + 1)
            }
        }
    }
    
    private func generatePosts() {
        Task {
            await campaignViewModel.generatePosts()
            if !campaignViewModel.generatedPosts.isEmpty {
                showingGeneratedPosts = true
            }
        }
    }
}

struct ProgressSteps: View {
    @Binding var currentStep: Int
    let steps = ["Media", "Plan", "Schedule", "Guidelines"]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 8) {
                    Circle()
                        .fill(index <= currentStep ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    Text(steps[index])
                        .font(.caption)
                        .foregroundColor(index <= currentStep ? .white : .gray)
                }
                
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? Color.purple : Color.gray.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    CreateCampaignView()
        .environmentObject(CampaignViewModel())
}

