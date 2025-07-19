@preconcurrency import UserNotifications

enum Notifier {
    @MainActor
    static func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    @MainActor
    static func show(title: String, body: String) {
        Task { // fire-and-forget
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            let req = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
            try? await UNUserNotificationCenter.current().add(req)
        }
    }
}