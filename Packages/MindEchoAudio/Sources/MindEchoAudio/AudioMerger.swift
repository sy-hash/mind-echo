import AVFoundation
import Foundation

public enum AudioMergerError: Error {
    case noInputFiles
    case conversionFailed
}

public struct AudioMerger {
    /// Merges audio sources (optional TTS buffer + silence + recordings) into a single .m4a file.
    public static func merge(
        ttsBuffer: AVAudioPCMBuffer?,
        recordingURLs: [URL],
        silenceDuration: TimeInterval = 0.75,
        outputURL: URL
    ) async throws -> URL {
        guard !recordingURLs.isEmpty else { throw AudioMergerError.noInputFiles }

        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // Read first recording to determine format
        let firstFile = try AVAudioFile(forReading: recordingURLs[0])
        let processingFormat = firstFile.processingFormat
        let sampleRate = processingFormat.sampleRate
        let channels = processingFormat.channelCount

        let outputFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: channels
        )!

        // Collect all PCM buffers
        var allBuffers: [AVAudioPCMBuffer] = []

        // Add TTS buffer if present (convert sample rate if needed)
        if let tts = ttsBuffer {
            if tts.format.sampleRate != sampleRate {
                if let converted = try convertBuffer(tts, to: outputFormat) {
                    allBuffers.append(converted)
                }
            } else {
                allBuffers.append(tts)
            }
            // Add silence gap between TTS and recordings
            let silenceSamples = AVAudioFrameCount(silenceDuration * sampleRate)
            if let silence = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: silenceSamples) {
                silence.frameLength = silenceSamples
                // Buffer is zero-initialized by default
                allBuffers.append(silence)
            }
        }

        // Read and add recording buffers
        for url in recordingURLs {
            let file = try AVAudioFile(forReading: url)
            let frameCount = AVAudioFrameCount(file.length)
            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: file.processingFormat,
                frameCapacity: frameCount
            ) else {
                continue
            }
            try file.read(into: buffer)

            if buffer.format.sampleRate != sampleRate {
                if let converted = try convertBuffer(buffer, to: outputFormat) {
                    allBuffers.append(converted)
                }
            } else {
                allBuffers.append(buffer)
            }
        }

        // Write all buffers to output file
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
        ]
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: settings)
        for buffer in allBuffers {
            try outputFile.write(from: buffer)
        }

        return outputURL
    }

    private static func convertBuffer(
        _ buffer: AVAudioPCMBuffer,
        to format: AVAudioFormat
    ) throws -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: buffer.format, to: format) else {
            throw AudioMergerError.conversionFailed
        }
        let ratio = format.sampleRate / buffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: outputFrameCount
        ) else {
            return nil
        }

        var error: NSError?
        let inputBuffer = buffer
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }
        if let error { throw error }
        return outputBuffer
    }
}
