import Foundation

struct GeneratedPost: Identifiable, Codable {
    let id: String
    var caption: String
    var mediaItemId: String
    var scheduledDate: Date
    var status: PostStatus
    var createdAt: Date
    
    init(id: String = UUID().uuidString, caption: String, mediaItemId: String, scheduledDate: Date, status: PostStatus = .pending, createdAt: Date = Date()) {
        self.id = id
        self.caption = caption
        self.mediaItemId = mediaItemId
        self.scheduledDate = scheduledDate
        self.status = status
        self.createdAt = createdAt
    }
}

enum PostStatus: String, Codable {
    case pending = "pending"
    case draft = "draft"
    case scheduled = "scheduled"
    case posted = "posted"
    case failed = "failed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .draft: return "Draft"
        case .scheduled: return "Scheduled"
        case .posted: return "Posted"
        case .failed: return "Failed"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "gray"
        case .draft: return "orange"
        case .scheduled: return "blue"
        case .posted: return "green"
        case .failed: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .draft: return "doc.text"
        case .scheduled: return "calendar"
        case .posted: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}

