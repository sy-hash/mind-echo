import AVFAudio
import Foundation
import Speech

protocol LiveTranscribing: Sendable {
    func transcriptionStream(locale: Locale) -> AsyncThrowingStream<String, Error>
    func stop()
}

final class LiveTranscriptionService: LiveTranscribing, @unchecked Sendable {
    private var analyzer: SpeechAnalyzer?
    private var audioEngine: AVAudioEngine?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?

    func transcriptionStream(locale: Locale) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let transcriber = SpeechTranscriber(
                        locale: locale,
                        transcriptionOptions: [],
                        reportingOptions: [.volatileResults],
                        attributeOptions: []
                    )
                    let analyzer = SpeechAnalyzer(modules: [transcriber])
                    self.analyzer = analyzer

                    // Build input stream
                    let (inputStream, inputContinuation) = AsyncStream<AnalyzerInput>.makeStream()
                    self.inputContinuation = inputContinuation

                    // Get best audio format for the analyzer
                    let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
                        compatibleWith: [transcriber]
                    )

                    // Set up AVAudioEngine
                    let audioEngine = AVAudioEngine()
                    self.audioEngine = audioEngine
                    let inputNode = audioEngine.inputNode
                    let hardwareFormat = inputNode.outputFormat(forBus: 0)

                    // Create format converter if needed
                    let converter: AVAudioConverter?
                    if let target = analyzerFormat {
                        converter = AVAudioConverter(from: hardwareFormat, to: target)
                    } else {
                        converter = nil
                    }

                    inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) {
                        [weak self] buffer, _ in
                        guard let self else { return }
                        if let converter, let targetFormat = analyzerFormat {
                            // Convert to analyzer format
                            let frameCapacity = AVAudioFrameCount(
                                Double(buffer.frameLength) * targetFormat.sampleRate
                                    / hardwareFormat.sampleRate
                            )
                            guard
                                let convertedBuffer = AVAudioPCMBuffer(
                                    pcmFormat: targetFormat, frameCapacity: frameCapacity)
                            else { return }
                            var error: NSError?
                            converter.convert(to: convertedBuffer, error: &error) { _, outStatus in
                                outStatus.pointee = .haveData
                                return buffer
                            }
                            if error == nil {
                                self.inputContinuation?.yield(AnalyzerInput(buffer: convertedBuffer))
                            }
                        } else {
                            // Copy buffer to avoid reuse issues from installTap
                            guard
                                let copy = AVAudioPCMBuffer(
                                    pcmFormat: hardwareFormat,
                                    frameCapacity: buffer.frameLength)
                            else { return }
                            copy.frameLength = buffer.frameLength
                            if let src = buffer.floatChannelData,
                                let dst = copy.floatChannelData
                            {
                                for ch in 0..<Int(hardwareFormat.channelCount) {
                                    dst[ch].update(
                                        from: src[ch], count: Int(buffer.frameLength))
                                }
                            }
                            self.inputContinuation?.yield(AnalyzerInput(buffer: copy))
                        }
                    }

                    // Collect transcription results
                    Task {
                        do {
                            var finalText = ""
                            for try await result in transcriber.results {
                                let newText = String(result.text.characters)
                                if result.isFinal {
                                    if finalText.isEmpty {
                                        finalText = newText
                                    } else {
                                        finalText += " " + newText
                                    }
                                    let combined = finalText
                                    continuation.yield(combined)
                                } else {
                                    // Volatile (partial) result — show final + partial
                                    let combined: String
                                    if finalText.isEmpty {
                                        combined = newText
                                    } else {
                                        combined = finalText + " " + newText
                                    }
                                    continuation.yield(combined)
                                }
                            }
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }

                    // Start audio engine and analyzer
                    audioEngine.prepare()
                    try audioEngine.start()
                    try await analyzer.start(inputSequence: inputStream)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func stop() {
        inputContinuation?.finish()
        inputContinuation = nil
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        Task {
            try? await analyzer?.finalizeAndFinishThroughEndOfInput()
        }
        analyzer = nil
    }
}
