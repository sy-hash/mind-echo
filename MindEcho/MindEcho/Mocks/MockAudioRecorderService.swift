import Foundation
import Observation

@Observable
class MockAudioRecorderService: AudioRecording {
    var isRecording = false
    var isPaused = false
    private(set) var recordingURL: URL?

    func startRecording(to url: URL) throws {
        recordingURL = url
        isRecording = true
        isPaused = false
    }

    func pauseRecording() {
        guard isRecording else { return }
        isPaused = true
    }

    func resumeRecording() {
        guard isRecording, isPaused else { return }
        isPaused = false
    }

    func stopRecording() {
        isRecording = false
        isPaused = false
        recordingURL = nil
    }
}
