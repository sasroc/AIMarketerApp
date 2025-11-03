import Foundation

struct PostSchedule: Codable {
    var startDate: Date?
    var endDate: Date?
    var selectedDays: Set<WeekDay>
    var postTimes: [WeekDay: [Date]]
    var postsPerDay: [WeekDay: Int]
    var contentGuidelines: String
    var imagesPerPost: Int  // Number of images to include in each post (1-10 for Instagram carousel support)
    
    init(startDate: Date? = nil, endDate: Date? = nil, selectedDays: Set<WeekDay> = [], postTimes: [WeekDay: [Date]] = [:], postsPerDay: [WeekDay: Int] = [:], contentGuidelines: String = "", imagesPerPost: Int = 1) {
        self.startDate = startDate
        self.endDate = endDate
        self.selectedDays = selectedDays
        self.postTimes = postTimes
        self.postsPerDay = postsPerDay
        self.contentGuidelines = contentGuidelines
        self.imagesPerPost = min(max(1, imagesPerPost), 10)  // Clamp between 1-10
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
    
    // Calendar.component(.weekday) returns: 1=Sunday, 2=Monday, 3=Tuesday, etc.
    var calendarWeekday: Int {
        switch self {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }
    
    static func from(calendarWeekday: Int) -> WeekDay? {
        switch calendarWeekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return nil
        }
    }
    
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

