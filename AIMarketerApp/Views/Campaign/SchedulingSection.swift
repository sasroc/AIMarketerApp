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
            
            // Date range selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Campaign Date Range")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    HStack {
                        Text("Start Date")
                            .foregroundColor(.gray)
                            .frame(width: 100, alignment: .leading)
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { campaignViewModel.schedule.startDate ?? Date() },
                                set: { campaignViewModel.schedule.startDate = $0 }
                            ),
                            in: Date()...,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    HStack {
                        Text("End Date")
                            .foregroundColor(.gray)
                            .frame(width: 100, alignment: .leading)
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { campaignViewModel.schedule.endDate ?? Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date() },
                                set: { campaignViewModel.schedule.endDate = $0 }
                            ),
                            in: (campaignViewModel.schedule.startDate ?? Date())...,
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
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
            
            // Time selection and posts per day for selected days
            if !campaignViewModel.schedule.selectedDays.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Posting Times & Frequency")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ForEach(Array(campaignViewModel.schedule.selectedDays).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { day in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(day.displayName)
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                HStack {
                                    Text("Posts per day:")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                    
                                    Stepper(
                                        "\(campaignViewModel.schedule.postsPerDay[day] ?? 1)",
                                        value: postsPerDayBinding(for: day),
                                        in: 1...10,
                                        onEditingChanged: { _ in
                                            updateTimesForDay(day)
                                        }
                                    )
                                }
                            }
                            
                            // Show time picker for each post
                            let postsCount = campaignViewModel.schedule.postsPerDay[day] ?? 1
                            ForEach(0..<postsCount, id: \.self) { postIndex in
                                HStack {
                                    Text("Post \(postIndex + 1) time:")
                                        .foregroundColor(.gray)
                                        .font(.subheadline)
                                        .frame(width: 120, alignment: .leading)
                                    
                                    DatePicker(
                                        "",
                                        selection: timeBinding(for: day, at: postIndex),
                                        displayedComponents: .hourAndMinute
                                    )
                                    .labelsHidden()
                                }
                            }
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
            campaignViewModel.schedule.postsPerDay.removeValue(forKey: day)
        } else {
            campaignViewModel.schedule.selectedDays.insert(day)
            // Set default time to 9:00 AM
            let calendar = Calendar.current
            let defaultTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            campaignViewModel.schedule.postTimes[day] = [defaultTime]
            // Set default posts per day to 1
            campaignViewModel.schedule.postsPerDay[day] = 1
        }
    }
    
    private func updateTimesForDay(_ day: WeekDay) {
        let postsCount = campaignViewModel.schedule.postsPerDay[day] ?? 1
        var times = campaignViewModel.schedule.postTimes[day] ?? []
        
        let calendar = Calendar.current
        
        // Add or remove times based on posts count
        if times.count < postsCount {
            // Add more times
            for i in times.count..<postsCount {
                let baseTime = times.first ?? calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
                // Space new times 2 hours apart
                let newTime = calendar.date(byAdding: .hour, value: i * 2, to: baseTime) ?? baseTime
                times.append(newTime)
            }
        } else if times.count > postsCount {
            // Remove excess times
            times = Array(times.prefix(postsCount))
        }
        
        campaignViewModel.schedule.postTimes[day] = times
    }
    
    private func timeBinding(for day: WeekDay, at index: Int) -> Binding<Date> {
        Binding(
            get: {
                let times = campaignViewModel.schedule.postTimes[day] ?? []
                if index < times.count {
                    return times[index]
                }
                let calendar = Calendar.current
                return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            },
            set: { newValue in
                var times = campaignViewModel.schedule.postTimes[day] ?? []
                if index < times.count {
                    times[index] = newValue
                } else {
                    // Shouldn't happen, but handle it
                    while times.count <= index {
                        times.append(newValue)
                    }
                }
                campaignViewModel.schedule.postTimes[day] = times
            }
        )
    }
    
    private func postsPerDayBinding(for day: WeekDay) -> Binding<Int> {
        Binding(
            get: {
                campaignViewModel.schedule.postsPerDay[day] ?? 1
            },
            set: { newValue in
                campaignViewModel.schedule.postsPerDay[day] = newValue
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

