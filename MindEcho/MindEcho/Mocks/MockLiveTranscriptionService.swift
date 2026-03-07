import AVFAudio
import Foundation
import Observation

@Observable
class MockLiveTranscriptionService: LiveTranscribing, @unchecked Sendable {
    func start(locale: Locale, contextualStrings: [String] = [], transcriberType: TranscriberType = .speechTranscriber) -> AsyncThrowingStream<String, Error> {
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

    func feedAudioBuffer(_ buffer: AVAudioPCMBuffer, format: AVAudioFormat) {
        // No-op for mock — text is emitted on a timer
    }

    func stop() {}
}
