import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private override init() {
        super.init()
        DispatchQueue.main.async {
            self.center.delegate = self
        }
    }

    func requestAuthorizationIfNeeded() {
        Task {
            let settings = await currentSettings()

            guard settings.authorizationStatus == .notDetermined else {
                return
            }

            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if !granted {
                    print("🔕 Notification permission was not granted")
                }
            } catch {
                print("❌ Failed to request notification authorization: \(error.localizedDescription)")
            }
        }
    }

    func sendPostStatusNotification(for post: GeneratedPost, previousStatus: PostStatus?) {
        guard post.status == .posted || post.status == .failed else { return }
        if let previousStatus, previousStatus == post.status { return }

        Task {
            let settings = await currentSettings()
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
                return
            }

            let content = UNMutableNotificationContent()
            if post.status == .posted {
                content.title = "Post Published"
                content.body = "Successfully posted to Instagram."
            } else {
                content.title = "Post Failed"
                content.body = "Failed to post to Instagram."
            }
            content.sound = .default
            content.threadIdentifier = "post-status-updates"
            content.userInfo = [
                "postId": post.id,
                "status": post.status.rawValue
            ]

            let identifier = "post-status-\(post.id)-\(post.status.rawValue)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

            do {
                try await center.add(request)
            } catch {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    // MARK: - Helpers

    private func currentSettings() async -> UNNotificationSettings {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings)
            }
        }
    }
}


