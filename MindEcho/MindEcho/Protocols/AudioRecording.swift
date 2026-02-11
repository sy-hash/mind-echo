import Foundation

protocol AudioRecording {
    var isRecording: Bool { get }
    var isPaused: Bool { get }
    func startRecording(to url: URL) throws
    func pauseRecording()
    func resumeRecording()
    func stopRecording()
}
