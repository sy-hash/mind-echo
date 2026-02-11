import AVFoundation
import Foundation
import Observation

/// Thread-safe boolean flag using os_unfair_lock for audio tap callback access.
private final class AtomicFlag: Sendable {
    nonisolated(unsafe) private var _value: Bool = false
    nonisolated(unsafe) private var _lock = os_unfair_lock()

    nonisolated var value: Bool {
        get {
            os_unfair_lock_lock(&_lock)
            defer { os_unfair_lock_unlock(&_lock) }
            return _value
        }
        set {
            os_unfair_lock_lock(&_lock)
            _value = newValue
            os_unfair_lock_unlock(&_lock)
        }
    }
}

@Observable
class AudioRecorderService: AudioRecording {
    var isRecording = false
    var isPaused = false

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    /// Thread-safe pause flag for the audio tap callback.
    private let pauseFlag = AtomicFlag()

    func startRecording(to url: URL) throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: 1,
        ]

        try FilePathManager.ensureDirectoryExists(url.deletingLastPathComponent())
        let file = try AVAudioFile(forWriting: url, settings: settings)

        self.audioEngine = engine
        self.audioFile = file

        let flag = pauseFlag
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            if !flag.value {
                try? file.write(from: buffer)
            }
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        try engine.start()
        isRecording = true
        isPaused = false
    }

    func pauseRecording() {
        guard isRecording else { return }
        pauseFlag.value = true
        isPaused = true
    }

    func resumeRecording() {
        guard isRecording, isPaused else { return }
        pauseFlag.value = false
        isPaused = false
    }

    func stopRecording() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        isRecording = false
        isPaused = false
        pauseFlag.value = false

        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
