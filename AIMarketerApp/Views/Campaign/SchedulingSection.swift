import SwiftUI

struct SchedulingSection: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Posting Schedule")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose when and how often to post")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Posts per week
            VStack(alignment: .leading, spacing: 12) {
                Text("Posts per Week")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Stepper(
                        "\(campaignViewModel.schedule.postsPerWeek) posts",
                        value: $campaignViewModel.schedule.postsPerWeek,
                        in: 1...14
                    )
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // Day selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Posting Days")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(WeekDay.allCases) { day in
                        DayButton(
                            day: day,
                            isSelected: campaignViewModel.schedule.selectedDays.contains(day)
                        ) {
                            toggleDay(day)
                        }
                    }
                }
            }
            
            // Time selection for selected days
            if !campaignViewModel.schedule.selectedDays.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Posting Times")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(Array(campaignViewModel.schedule.selectedDays).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { day in
                        HStack {
                            Text(day.displayName)
                                .foregroundColor(.white)
                                .frame(width: 100, alignment: .leading)
                            
                            DatePicker(
                                "",
                                selection: timeBinding(for: day),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func toggleDay(_ day: WeekDay) {
        if campaignViewModel.schedule.selectedDays.contains(day) {
            campaignViewModel.schedule.selectedDays.remove(day)
            campaignViewModel.schedule.postTimes.removeValue(forKey: day)
        } else {
            campaignViewModel.schedule.selectedDays.insert(day)
            // Set default time to 9:00 AM
            let calendar = Calendar.current
            let defaultTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            campaignViewModel.schedule.postTimes[day] = [defaultTime]
        }
    }
    
    private func timeBinding(for day: WeekDay) -> Binding<Date> {
        Binding(
            get: {
                campaignViewModel.schedule.postTimes[day]?.first ?? Date()
            },
            set: { newValue in
                campaignViewModel.schedule.postTimes[day] = [newValue]
            }
        )
    }
}

struct DayButton: View {
    let day: WeekDay
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day.shortName)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.purple : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(12)
        }
    }
}

#Preview {
    SchedulingSection()
        .environmentObject(CampaignViewModel())
        .padding()
        .background(Color.black)
}

