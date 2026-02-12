import AVFoundation
import Foundation
import Observation

@Observable
public class AudioPlayerService: NSObject, AudioPlaying {
    public var playbackProgress: Double = 0
    @ObservationIgnored public var onPlaybackFinished: (@MainActor () -> Void)?

    private var audioPlayer: AVAudioPlayer?
    private var progressTimer: Timer?

    public override init() {}

    public func play(url: URL) throws {
        stop()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)

        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        self.audioPlayer = player
        player.play()
        startProgressTimer()
    }

    public func pause() {
        audioPlayer?.pause()
        stopProgressTimer()
    }

    public func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        playbackProgress = 0
        stopProgressTimer()
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let player = self.audioPlayer else { return }
            if player.duration > 0 {
                self.playbackProgress = player.currentTime / player.duration
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

extension AudioPlayerService: AVAudioPlayerDelegate {
    nonisolated public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.playbackProgress = 1.0
            self.audioPlayer = nil
            self.stopProgressTimer()
            self.onPlaybackFinished?()
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
}
