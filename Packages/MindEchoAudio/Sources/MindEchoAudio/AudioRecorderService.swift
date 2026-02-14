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
public class AudioRecorderService: AudioRecording {
    public var isRecording = false
    public var isPaused = false
    public var audioLevels: [Float] = []

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    /// Thread-safe pause flag for the audio tap callback.
    private let pauseFlag = AtomicFlag()

    public init() {}

    public func startRecording(to url: URL) throws {
        // Set up audio session BEFORE accessing inputNode so the microphone
        // permission is resolved and the node returns a valid format.
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        guard format.sampleRate > 0, format.channelCount > 0 else {
            try session.setActive(false)
            throw NSError(domain: "AudioRecorderService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "マイクが利用できません"])
        }

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: 1,
        ]

        let parentDir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        let file = try AVAudioFile(forWriting: url, settings: settings)

        self.audioEngine = engine
        self.audioFile = file

        let flag = pauseFlag
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, _ in
            if !flag.value {
                try? file.write(from: buffer)
            }

            // Calculate RMS level from audio buffer
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frameLength {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameLength))

            // Convert to dB and normalize to 0.0-1.0
            let db = 20 * log10(max(rms, 1e-6))
            let minDb: Float = -60
            let maxDb: Float = 0
            let normalized = max(0, min(1, (db - minDb) / (maxDb - minDb)))

            DispatchQueue.main.async {
                self?.audioLevels.append(normalized)
            }
        }

        try engine.start()
        isRecording = true
        isPaused = false
    }

    public func pauseRecording() {
        guard isRecording else { return }
        pauseFlag.value = true
        isPaused = true
    }

    public func resumeRecording() {
        guard isRecording, isPaused else { return }
        pauseFlag.value = false
        isPaused = false
    }

    public func stopRecording() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        isRecording = false
        isPaused = false
        pauseFlag.value = false
        audioLevels = []

        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
