import Foundation
import Observation

@Observable
class MockLiveTranscriptionService: LiveTranscribing, @unchecked Sendable {
    func transcriptionStream(locale: Locale) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                // Initial delay must be long enough for XCTest to detect the placeholder state.
                try? await Task.sleep(for: .milliseconds(3000))
                continuation.yield("これは")
                try? await Task.sleep(for: .milliseconds(300))
                continuation.yield("これはモックの")
                try? await Task.sleep(for: .milliseconds(300))
                continuation.yield("これはモックのリアルタイム書き起こしです。")
                continuation.finish()
            }
        }
    }

    func stop() {}
}
