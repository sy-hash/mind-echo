import Foundation
import Testing

@testable import MindEcho

struct RecordingLaunchRequestStoreTests {
    @Test func requestStartRecording_marksPendingRequestAndPostsNotification() throws {
        let defaults = try makeDefaults()
        let notificationCenter = NotificationCenter()
        var didReceiveNotification = false
        let observer = notificationCenter.addObserver(
            forName: RecordingLaunchRequestStore.startRecordingNotification,
            object: nil,
            queue: nil
        ) { _ in
            didReceiveNotification = true
        }
        defer { notificationCenter.removeObserver(observer) }

        RecordingLaunchRequestStore.requestStartRecording(
            defaults: defaults,
            notificationCenter: notificationCenter
        )

        #expect(RecordingLaunchRequestStore.consumeStartRecordingRequest(defaults: defaults) == true)
        #expect(didReceiveNotification == true)
    }

    @Test func consumeStartRecordingRequest_clearsPendingRequest() throws {
        let defaults = try makeDefaults()

        RecordingLaunchRequestStore.requestStartRecording(defaults: defaults)

        #expect(RecordingLaunchRequestStore.consumeStartRecordingRequest(defaults: defaults) == true)
        #expect(RecordingLaunchRequestStore.consumeStartRecordingRequest(defaults: defaults) == false)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "RecordingLaunchRequestStoreTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
