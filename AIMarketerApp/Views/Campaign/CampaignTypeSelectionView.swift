import SwiftUI

struct CampaignTypeSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var selectedType: CampaignType?
    @State private var showAutoGenerate = false
    @State private var showSpecifiedGenerate = false
    
    enum CampaignType {
        case autoGenerate
        case specifiedGenerate
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.marketingPrimary)
                        
                        Text("Create Campaign")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Choose how you'd like to generate your posts")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Options
                    VStack(spacing: 16) {
                        // Auto Generate Option
                        Button(action: {
                            selectedType = .autoGenerate
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                        .font(.title2)
                                        .foregroundColor(.marketingPrimary)
                                    
                                    Text("Auto Generate")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("AI will automatically generate a week's worth of posts using your business information")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedType == .autoGenerate ? Color.marketingPrimary.opacity(0.2) : Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedType == .autoGenerate ? Color.marketingPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                        }
                        
                        // Specified Generate Option
                        Button(action: {
                            selectedType = .specifiedGenerate
                        }) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.title2)
                                        .foregroundColor(.marketingSecondary)
                                    
                                    Text("Specified Generate")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Manually configure your campaign with custom media, marketing plan, and schedule")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedType == .specifiedGenerate ? Color.marketingSecondary.opacity(0.2) : Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedType == .specifiedGenerate ? Color.marketingSecondary : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Continue Button
                    if selectedType != nil {
                        Button(action: {
                            if selectedType == .autoGenerate {
                                showAutoGenerate = true
                            } else {
                                showSpecifiedGenerate = true
                            }
                        }) {
                            Text("Continue")
                                .font(.headline)
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
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.marketingPrimary)
                }
            }
            .fullScreenCover(isPresented: $showAutoGenerate) {
                AutoGenerateView()
                    .environmentObject(campaignViewModel)
            }
            .fullScreenCover(isPresented: $showSpecifiedGenerate) {
                CreateCampaignView()
                    .environmentObject(campaignViewModel)
            }
        }
    }
}

#Preview {
    CampaignTypeSelectionView()
}

