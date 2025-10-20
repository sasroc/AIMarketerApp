import SwiftUI

struct ContentGuidelinesSection: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Content Guidelines")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Specify what the AI should include in your posts")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Guidelines text editor
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Instructions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextEditor(text: $campaignViewModel.schedule.contentGuidelines)
                    .frame(height: 200)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                    .scrollContentBackground(.hidden)
                
                if campaignViewModel.schedule.contentGuidelines.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example guidelines:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("• Include product descriptions\n• Use emojis sparingly\n• Ask engaging questions\n• Keep captions under 150 characters\n• Maintain a friendly tone")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Summary card
            VStack(alignment: .leading, spacing: 12) {
                Text("Campaign Summary")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    SummaryRow(
                        icon: "photo",
                        label: "Media Items",
                        value: "\(campaignViewModel.mediaItems.count)"
                    )
                    
                    SummaryRow(
                        icon: "calendar",
                        label: "Posts per Week",
                        value: "\(campaignViewModel.schedule.postsPerWeek)"
                    )
                    
                    SummaryRow(
                        icon: "clock",
                        label: "Posting Days",
                        value: "\(campaignViewModel.schedule.selectedDays.count)"
                    )
                    
                    SummaryRow(
                        icon: "doc.text",
                        label: "Total Posts to Generate",
                        value: "\(campaignViewModel.schedule.postsPerWeek * 4)"
                    )
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ContentGuidelinesSection()
        .environmentObject(CampaignViewModel())
        .padding()
        .background(Color.black)
}

