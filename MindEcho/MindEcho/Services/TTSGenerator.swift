import AVFoundation
import Foundation

struct TTSGenerator {
    /// Generates a TTS audio buffer for the date announcement in Japanese.
    static func generateDateAnnouncement(for date: Date) async throws -> AVAudioPCMBuffer {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let text = "これは\(components.year!)年\(components.month!)月\(components.day!)日の録音です。"

        let synthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate

        return try await withCheckedThrowingContinuation { continuation in
            var buffers: [AVAudioBuffer] = []
            synthesizer.write(utterance) { buffer in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }
                if pcmBuffer.frameLength > 0 {
                    buffers.append(pcmBuffer)
                } else {
                    // Empty buffer signals completion
                    if let combined = Self.combineBuffers(buffers) {
                        continuation.resume(returning: combined)
                    } else {
                        continuation.resume(throwing: AudioMergerError.conversionFailed)
                    }
                }
            }
        }
    }

    private static func combineBuffers(_ buffers: [AVAudioBuffer]) -> AVAudioPCMBuffer? {
        guard let first = buffers.first as? AVAudioPCMBuffer else { return nil }
        let format = first.format
        let totalFrames = buffers.compactMap { $0 as? AVAudioPCMBuffer }.reduce(0) { $0 + $1.frameLength }
        guard let combined = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames) else { return nil }

        var offset: AVAudioFrameCount = 0
        for buf in buffers.compactMap({ $0 as? AVAudioPCMBuffer }) {
            let src = buf.floatChannelData!
            let dst = combined.floatChannelData!
            for ch in 0..<Int(format.channelCount) {
                dst[ch].advanced(by: Int(offset)).update(from: src[ch], count: Int(buf.frameLength))
            }
            offset += buf.frameLength
        }
        combined.frameLength = totalFrames
        return combined
    }
}
