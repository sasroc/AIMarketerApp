import Foundation

struct PostSchedule: Codable {
    var postsPerWeek: Int
    var selectedDays: Set<WeekDay>
    var postTimes: [WeekDay: [Date]]
    var contentGuidelines: String
    
    init(postsPerWeek: Int = 3, selectedDays: Set<WeekDay> = [], postTimes: [WeekDay: [Date]] = [:], contentGuidelines: String = "") {
        self.postsPerWeek = postsPerWeek
        self.selectedDays = selectedDays
        self.postTimes = postTimes
        self.contentGuidelines = contentGuidelines
    }
}

enum WeekDay: Int, Codable, CaseIterable, Identifiable {
    case monday = 1
    case tuesday = 2
    case wednesday = 3
    case thursday = 4
    case friday = 5
    case saturday = 6
    case sunday = 7
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
    
    var shortName: String {
        switch self {
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        case .sunday: return "Sun"
        }
    }
}

