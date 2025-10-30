import SwiftUI

struct CreateCampaignView: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingGeneratedPosts = false
    @State private var shouldDismissToHome = false
    
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
                        
                        // Navigation button
                        Button(action: nextStep) {
                            HStack {
                                if campaignViewModel.currentStep == 3 && campaignViewModel.isGenerating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Text(campaignViewModel.currentStep == 3 ? "Generate Posts" : "Next")
                                }
                                
                                if campaignViewModel.currentStep < 3 && !campaignViewModel.isGenerating {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.marketingPrimary, Color.marketingSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!canProceed || campaignViewModel.isGenerating)
                        .opacity((canProceed && !campaignViewModel.isGenerating) ? 1 : 0.5)
                        .padding(.horizontal)
                        
                        // Save Draft button
                        if campaignViewModel.hasUnsavedChanges() {
                            Button(action: saveDraft) {
                                HStack {
                                    Image(systemName: "doc.text")
                                    Text("Save Draft")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.marketingCardBackground)
                                .foregroundColor(.marketingPrimary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.marketingPrimary.opacity(0.3), lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                            .frame(height: 32)
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded { _ in
                            hideKeyboard()
                        }
                    )
                }
            }
            .navigationTitle("Create Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if campaignViewModel.currentStep > 0 {
                        Button(action: previousStep) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(.marketingPrimary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { campaignViewModel.resetCampaign() }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.marketingPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingGeneratedPosts) {
                GeneratedPostsView(shouldDismissToHome: $shouldDismissToHome)
            }
            .onChange(of: shouldDismissToHome) { newValue in
                if newValue {
                    // Dismiss the entire campaign creation flow
                    dismiss()
                    // Reset the flag and the campaign
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        shouldDismissToHome = false
                        campaignViewModel.resetCampaign()
                    }
                }
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
            return campaignViewModel.schedule.startDate != nil && 
                   campaignViewModel.schedule.endDate != nil && 
                   !campaignViewModel.schedule.selectedDays.isEmpty
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
        showingGeneratedPosts = true
        Task {
            await campaignViewModel.generatePosts()
        }
    }
    
    private func saveDraft() {
        campaignViewModel.saveDraft()
        dismiss() // Navigate back to home tab
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                        .fill(index <= currentStep ? Color.marketingPrimary : Color.gray.opacity(0.3))
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
                        .fill(index < currentStep ? Color.marketingPrimary : Color.gray.opacity(0.3))
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

