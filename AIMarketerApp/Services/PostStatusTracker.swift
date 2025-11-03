import Foundation

struct PostStatusChange {
    let post: GeneratedPost
    let previousStatus: PostStatus?
}

actor PostStatusTracker {
    static let shared = PostStatusTracker()
    
    private let storageKey = "postStatusTracker.statuses"
    private var statuses: [String: String]
    private var hasBootstrapped: Bool
    
    private init() {
        if let stored = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: String] {
            statuses = stored
            hasBootstrapped = true
        } else {
            statuses = [:]
            hasBootstrapped = false
        }
    }
    
    func process(posts: [GeneratedPost]) -> [PostStatusChange] {
        var changes: [PostStatusChange] = []
        let isFirstProcess = !hasBootstrapped && statuses.isEmpty
        hasBootstrapped = true
        
        let lowercasedPosts = posts.map { ($0.id.lowercased(), $0) }
        let currentKeys = Set(lowercasedPosts.map { $0.0 })
        
        for (key, post) in lowercasedPosts {
            let previous = statuses[key].flatMap(PostStatus.init(rawValue:))
            if previous?.rawValue != post.status.rawValue {
                statuses[key] = post.status.rawValue
                if !isFirstProcess && (post.status == .posted || post.status == .failed) {
                    changes.append(PostStatusChange(post: post, previousStatus: previous))
                }
            }
        }
        
        // Remove statuses for posts that no longer exist to keep storage tidy
        for key in statuses.keys where !currentKeys.contains(key) {
            statuses.removeValue(forKey: key)
        }
        
        persist()
        return changes
    }
    
    private func persist() {
        UserDefaults.standard.setValue(statuses, forKey: storageKey)
    }
}


