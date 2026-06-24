import Foundation

enum RecordingLaunchRequestStore {
    static let startRecordingNotification = Notification.Name("MindEchoStartRecordingRequested")

    private static let pendingStartRecordingKey = "pendingStartRecordingFromShortcut"

    static func requestStartRecording(
        defaults: UserDefaults = .standard,
        notificationCenter: NotificationCenter = .default
    ) {
        defaults.set(true, forKey: pendingStartRecordingKey)
        notificationCenter.post(name: startRecordingNotification, object: nil)
    }

    @discardableResult
    static func consumeStartRecordingRequest(defaults: UserDefaults = .standard) -> Bool {
        let shouldStartRecording = defaults.bool(forKey: pendingStartRecordingKey)
        if shouldStartRecording {
            defaults.removeObject(forKey: pendingStartRecordingKey)
        }
        return shouldStartRecording
    }
}
