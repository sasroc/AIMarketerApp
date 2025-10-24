import SwiftUI
import PhotosUI

enum MediaType: String, Codable {
    case image
    case video
}

struct MediaItem: Identifiable, Equatable, Codable {
    let id: String
    let type: MediaType
    var thumbnailData: Data?
    var localURL: URL?
    var cloudURL: String?
    var createdAt: Date
    
    init(id: String = UUID().uuidString, type: MediaType, thumbnail: UIImage? = nil, localURL: URL? = nil, cloudURL: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.thumbnailData = thumbnail?.jpegData(compressionQuality: 0.8)
        self.localURL = localURL
        self.cloudURL = cloudURL
        self.createdAt = createdAt
    }
    
    var thumbnail: UIImage? {
        get {
            guard let data = thumbnailData else { return nil }
            return UIImage(data: data)
        }
        set {
            thumbnailData = newValue?.jpegData(compressionQuality: 0.8)
        }
    }
    
    static func == (lhs: MediaItem, rhs: MediaItem) -> Bool {
        lhs.id == rhs.id
    }
}

