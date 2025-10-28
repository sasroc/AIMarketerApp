import Foundation

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var name: String
    var instagramConnection: InstagramConnection?
    var createdAt: Date
    
    var instagramConnected: Bool {
        return instagramConnection?.isConnected ?? false
    }
    
    init(id: String = UUID().uuidString, email: String, name: String, instagramConnection: InstagramConnection? = nil, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.instagramConnection = instagramConnection
        self.createdAt = createdAt
    }
}

