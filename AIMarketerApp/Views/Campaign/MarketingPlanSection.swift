import SwiftUI

struct MarketingPlanSection: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Marketing Plan")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Describe your marketing goals and target audience")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Marketing description
            VStack(alignment: .leading, spacing: 8) {
                Text("Campaign Description")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextEditor(text: $campaignViewModel.marketingPlan.description)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color.marketingCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.marketingPrimary.opacity(0.3), lineWidth: 1)
                    )
                    .scrollContentBackground(.hidden)
            }
            
            // Target audience
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Audience")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("e.g., Young professionals aged 25-35", text: $campaignViewModel.marketingPlan.targetAudience)
                    .padding()
                    .background(Color.marketingCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.marketingPrimary.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Tone selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Content Tone")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(ContentTone.allCases, id: \.self) { tone in
                        ToneButton(
                            tone: tone,
                            isSelected: campaignViewModel.marketingPlan.tone == tone
                        ) {
                            campaignViewModel.marketingPlan.tone = tone
                        }
                    }
                }
            }
            
            // Hashtags
            VStack(alignment: .leading, spacing: 8) {
                Text("Hashtags (optional)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Enter hashtags separated by commas", text: hashtagsBinding)
                    .padding()
                    .background(Color.marketingCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.marketingPrimary.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Call to action
            VStack(alignment: .leading, spacing: 8) {
                Text("Call to Action (optional)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("e.g., Visit our website", text: $campaignViewModel.marketingPlan.callToAction)
                    .padding()
                    .background(Color.marketingCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.marketingPrimary.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private var hashtagsBinding: Binding<String> {
        Binding(
            get: { campaignViewModel.marketingPlan.hashtags.joined(separator: ", ") },
            set: { newValue in
                campaignViewModel.marketingPlan.hashtags = newValue
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
            }
        )
    }
}

struct ToneButton: View {
    let tone: ContentTone
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: tone.icon)
                Text(tone.rawValue)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.marketingPrimary : Color.marketingCardBackground)
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(12)
        }
    }
}

#Preview {
    MarketingPlanSection()
        .environmentObject(CampaignViewModel())
        .padding()
        .background(Color.black)
}

