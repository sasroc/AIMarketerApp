import SwiftUI

struct SchedulingSection: View {
    @EnvironmentObject var campaignViewModel: CampaignViewModel
    @State private var showingStartDatePicker = false
    @State private var showingEndDatePicker = false
    @State private var tempStartDate = Date()
    @State private var tempEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    
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
                    // Start Date Button
                    Button(action: { 
                        tempStartDate = campaignViewModel.schedule.startDate ?? Date()
                        showingStartDatePicker = true 
                    }) {
                        HStack {
                            Text("Start Date")
                                .foregroundColor(.gray)
                                .frame(width: 100, alignment: .leading)
                            
                            Spacer()
                            
                            if let startDate = campaignViewModel.schedule.startDate {
                                Text(formatDate(startDate))
                                    .foregroundColor(.white)
                            } else {
                                Text("Select date")
                                    .foregroundColor(.marketingPrimary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.marketingCardBackground)
                        .cornerRadius(12)
                    }
                    
                    // End Date Button
                    Button(action: { 
                        tempEndDate = campaignViewModel.schedule.endDate ?? Calendar.current.date(byAdding: .day, value: 7, to: campaignViewModel.schedule.startDate ?? Date()) ?? Date()
                        showingEndDatePicker = true 
                    }) {
                        HStack {
                            Text("End Date")
                                .foregroundColor(.gray)
                                .frame(width: 100, alignment: .leading)
                            
                            Spacer()
                            
                            if let endDate = campaignViewModel.schedule.endDate {
                                Text(formatDate(endDate))
                                    .foregroundColor(.white)
                            } else {
                                Text("Select date")
                                    .foregroundColor(.marketingPrimary)
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.marketingCardBackground)
                        .cornerRadius(12)
                    }
                }
            }
            .sheet(isPresented: $showingStartDatePicker) {
                DatePickerSheet(
                    title: "Start Date",
                    selectedDate: $tempStartDate,
                    minimumDate: Calendar.current.startOfDay(for: Date()),
                    maximumDate: nil,
                    onSave: {
                        campaignViewModel.schedule.startDate = tempStartDate
                        showingStartDatePicker = false
                    },
                    onCancel: {
                        showingStartDatePicker = false
                    }
                )
            }
            .sheet(isPresented: $showingEndDatePicker) {
                DatePickerSheet(
                    title: "End Date",
                    selectedDate: $tempEndDate,
                    minimumDate: campaignViewModel.schedule.startDate ?? Calendar.current.startOfDay(for: Date()),
                    maximumDate: nil,
                    onSave: {
                        campaignViewModel.schedule.endDate = tempEndDate
                        showingEndDatePicker = false
                    },
                    onCancel: {
                        showingEndDatePicker = false
                    }
                )
            }
            
            // Images per post selector
            VStack(alignment: .leading, spacing: 12) {
                Text("Images Per Post")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("How many images to include in each post (Instagram supports up to 10)")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(spacing: 16) {
                    Text("\(campaignViewModel.schedule.imagesPerPost) image\(campaignViewModel.schedule.imagesPerPost == 1 ? "" : "s")")
                        .foregroundColor(.white)
                        .frame(width: 80, alignment: .leading)
                    
                    Slider(
                        value: Binding(
                            get: { Double(campaignViewModel.schedule.imagesPerPost) },
                            set: { campaignViewModel.schedule.imagesPerPost = Int($0) }
                        ),
                        in: 1...10,
                        step: 1
                    )
                    .tint(.marketingPrimary)
                }
                .padding()
                .background(Color.marketingCardBackground)
                .cornerRadius(12)
                
                // Info text
                if campaignViewModel.schedule.imagesPerPost > 1 {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.marketingPrimary)
                        Text("Posts with multiple images will be published as Instagram carousels")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
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
                        .background(Color.marketingCardBackground)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
                .background(isSelected ? Color.marketingPrimary : Color.marketingCardBackground)
                .foregroundColor(isSelected ? .white : .gray)
                .cornerRadius(12)
        }
    }
}

struct DatePickerSheet: View {
    let title: String
    @Binding var selectedDate: Date
    let minimumDate: Date
    let maximumDate: Date?
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        in: minimumDate...(maximumDate ?? Date.distantFuture),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.marketingPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSave()
                    }
                    .foregroundColor(.marketingPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    SchedulingSection()
        .environmentObject(CampaignViewModel())
        .padding()
        .background(Color.black)
}

