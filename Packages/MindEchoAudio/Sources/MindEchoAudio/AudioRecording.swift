import AVFoundation
import Foundation

public protocol AudioRecording {
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    var audioLevels: [Float] { get }
    var onAudioBuffer: (@MainActor (AVAudioPCMBuffer) -> Void)? { get set }
    func startRecording(to url: URL) throws
    func pauseRecording()
    func resumeRecording()
    func stopRecording()
}
