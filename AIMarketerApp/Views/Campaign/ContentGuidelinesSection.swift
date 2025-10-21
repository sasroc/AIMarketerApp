import SwiftUI

struct ContentGuidelinesSection: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    
    private var totalPostsToGenerate: Int {
        guard let startDate = campaignViewModel.schedule.startDate,
              let endDate = campaignViewModel.schedule.endDate else {
            return 0
        }
        
        let calendar = Calendar.current
        var currentDate = startDate
        var totalPosts = 0
        
        // Iterate through each day in the range
        while currentDate <= endDate {
            let weekdayComponent = calendar.component(.weekday, from: currentDate)
            
            // Check if this day is in the selected days
            if let weekDay = WeekDay.from(calendarWeekday: weekdayComponent),
               campaignViewModel.schedule.selectedDays.contains(weekDay) {
                totalPosts += campaignViewModel.schedule.postsPerDay[weekDay] ?? 1
            }
            
            // Move to next day
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return totalPosts
    }
    
    private var dateRangeDuration: String {
        guard let startDate = campaignViewModel.schedule.startDate,
              let endDate = campaignViewModel.schedule.endDate else {
            return "Not set"
        }
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let weeks = Int(ceil(Double(days) / 7.0))
        
        if weeks == 1 {
            return "1 week"
        } else {
            return "\(weeks) weeks"
        }
    }
    
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
                        label: "Campaign Duration",
                        value: dateRangeDuration
                    )
                    
                    SummaryRow(
                        icon: "clock",
                        label: "Posting Days",
                        value: "\(campaignViewModel.schedule.selectedDays.count)"
                    )
                    
                    SummaryRow(
                        icon: "doc.text",
                        label: "Total Posts to Generate",
                        value: "\(totalPostsToGenerate)"
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

