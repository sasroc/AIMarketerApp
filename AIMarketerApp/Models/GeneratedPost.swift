import Foundation

struct GeneratedPost: Identifiable, Codable {
    let id: String
    var caption: String
    var mediaItemIds: [String]  // Changed from single mediaItemId to array
    var scheduledDate: Date
    var status: PostStatus
    var createdAt: Date
    
    // Instagram publishing fields
    var instagramPostId: String?
    var instagramPermalink: String?
    var publishedAt: Date?
    var errorMessage: String?
    
    // Backward compatibility - deprecated but kept for migration
    @available(*, deprecated, message: "Use mediaItemIds instead")
    var mediaItemId: String {
        get { mediaItemIds.first ?? "" }
        set { mediaItemIds = [newValue] }
    }
    
    init(
        id: String = UUID().uuidString,
        caption: String,
        mediaItemIds: [String],
        scheduledDate: Date,
        status: PostStatus = .pending,
        createdAt: Date = Date(),
        instagramPostId: String? = nil,
        instagramPermalink: String? = nil,
        publishedAt: Date? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.caption = caption
        self.mediaItemIds = mediaItemIds
        self.scheduledDate = scheduledDate
        self.status = status
        self.createdAt = createdAt
        self.instagramPostId = instagramPostId
        self.instagramPermalink = instagramPermalink
        self.publishedAt = publishedAt
        self.errorMessage = errorMessage
    }
    
    // Convenience init for single media item (backward compatibility)
    init(
        id: String = UUID().uuidString,
        caption: String,
        mediaItemId: String,
        scheduledDate: Date,
        status: PostStatus = .pending,
        createdAt: Date = Date(),
        instagramPostId: String? = nil,
        instagramPermalink: String? = nil,
        publishedAt: Date? = nil,
        errorMessage: String? = nil
    ) {
        self.init(
            id: id,
            caption: caption,
            mediaItemIds: [mediaItemId],
            scheduledDate: scheduledDate,
            status: status,
            createdAt: createdAt,
            instagramPostId: instagramPostId,
            instagramPermalink: instagramPermalink,
            publishedAt: publishedAt,
            errorMessage: errorMessage
        )
    }
    
    // Helper property to check if post is carousel (multiple images)
    var isCarousel: Bool {
        return mediaItemIds.count > 1
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

