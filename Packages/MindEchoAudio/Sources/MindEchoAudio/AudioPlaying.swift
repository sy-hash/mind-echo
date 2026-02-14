import Foundation

public protocol AudioPlaying {
    var playbackProgress: Double { get }
    var onPlaybackFinished: (@MainActor () -> Void)? { get set }
    func play(url: URL) throws
    func pause()
    func stop()
}
