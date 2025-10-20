import Foundation

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var name: String
    var instagramConnected: Bool
    var createdAt: Date
    
    init(id: String = UUID().uuidString, email: String, name: String, instagramConnected: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.instagramConnected = instagramConnected
        self.createdAt = createdAt
    }
}

