import AVFoundation
import Foundation

public protocol AudioRecording: AnyObject {
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    var audioLevels: [Float] { get }
    /// 録音中の音声バッファを受け取るコールバック。音声スレッドから呼ばれる。
    var onAudioBuffer: ((AVAudioPCMBuffer, AVAudioTime) -> Void)? { get set }
    func startRecording(to url: URL) throws
    func pauseRecording()
    func resumeRecording()
    func stopRecording()
}
