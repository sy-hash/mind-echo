import Foundation
import Observation

@Observable
class MockAudioPlayerService: AudioPlaying {
    var playbackProgress: Double = 0
    @ObservationIgnored var onPlaybackFinished: (@MainActor () -> Void)?
    private(set) var isPlaying = false
    private(set) var currentURL: URL?

    func play(url: URL) throws {
        currentURL = url
        isPlaying = true
        playbackProgress = 0
    }

    func pause() {
        isPlaying = false
    }

    func stop() {
        isPlaying = false
        playbackProgress = 0
        currentURL = nil
    }

    /// Test helper: simulate playback completion
    func simulatePlaybackFinished() {
        isPlaying = false
        playbackProgress = 1.0
        onPlaybackFinished?()
    }
}
