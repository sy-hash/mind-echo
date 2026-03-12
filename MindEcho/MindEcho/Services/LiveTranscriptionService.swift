import AVFAudio
import Foundation
import Speech

protocol LiveTranscribing: Sendable {
    func start(locale: Locale, contextualStrings: [String], transcriberType: TranscriberType) -> AsyncThrowingStream<
        String, Error
    >
    func feedAudioBuffer(_ buffer: AVAudioPCMBuffer, format: AVAudioFormat)
    func stop()
}

extension LiveTranscribing {
    func start(locale: Locale, contextualStrings: [String]) -> AsyncThrowingStream<String, Error> {
        start(locale: locale, contextualStrings: contextualStrings, transcriberType: .speechTranscriber)
    }
}

final class LiveTranscriptionService: LiveTranscribing, @unchecked Sendable {
    private var analyzer: SpeechAnalyzer?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    private var converter: AVAudioConverter?
    private var analyzerFormat: AVAudioFormat?
    private var isSetupComplete = false
    nonisolated(unsafe) private var lock = os_unfair_lock()

    func start(locale: Locale, contextualStrings: [String] = [], transcriberType: TranscriberType = .speechTranscriber)
        -> AsyncThrowingStream<String, Error>
    {
        switch transcriberType {
        case .speechTranscriber, .whisperAPI:
            startWithSpeechTranscriber(locale: locale, contextualStrings: contextualStrings)
        case .dictationTranscriber:
            startWithDictationTranscriber(locale: locale, contextualStrings: contextualStrings)
        }
    }

    private func startWithSpeechTranscriber(locale: Locale, contextualStrings: [String]) -> AsyncThrowingStream<
        String, Error
    > {
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

                    if !contextualStrings.isEmpty {
                        let context = AnalysisContext()
                        context.contextualStrings = [
                            AnalysisContext.ContextualStringsTag("vocabulary"): contextualStrings
                        ]
                        try await analyzer.setContext(context)
                    }

                    let (inputStream, inputContinuation) = AsyncStream<AnalyzerInput>.makeStream()
                    self.inputContinuation = inputContinuation

                    self.analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
                        compatibleWith: [transcriber]
                    )

                    self.markSetupComplete()

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
                                    continuation.yield(finalText)
                                } else {
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

                    try await analyzer.start(inputSequence: inputStream)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func startWithDictationTranscriber(locale: Locale, contextualStrings: [String]) -> AsyncThrowingStream<
        String, Error
    > {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let transcriber = DictationTranscriber(locale: locale, preset: .progressiveLongDictation)
                    let analyzer = SpeechAnalyzer(modules: [transcriber])
                    self.analyzer = analyzer

                    if !contextualStrings.isEmpty {
                        let context = AnalysisContext()
                        context.contextualStrings = [
                            AnalysisContext.ContextualStringsTag("vocabulary"): contextualStrings
                        ]
                        try await analyzer.setContext(context)
                    }

                    let (inputStream, inputContinuation) = AsyncStream<AnalyzerInput>.makeStream()
                    self.inputContinuation = inputContinuation

                    self.analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
                        compatibleWith: [transcriber]
                    )

                    self.markSetupComplete()

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
                                    continuation.yield(finalText)
                                } else {
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

                    try await analyzer.start(inputSequence: inputStream)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func markSetupComplete() {
        os_unfair_lock_lock(&lock)
        isSetupComplete = true
        os_unfair_lock_unlock(&lock)
    }

    func feedAudioBuffer(_ buffer: AVAudioPCMBuffer, format: AVAudioFormat) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }

        guard isSetupComplete, let inputContinuation else { return }

        if let targetFormat = analyzerFormat {
            // Create or reuse converter for the source format
            if converter == nil || converter?.inputFormat != format {
                converter = AVAudioConverter(from: format, to: targetFormat)
            }
            guard let converter else { return }

            let frameCapacity = AVAudioFrameCount(
                Double(buffer.frameLength) * targetFormat.sampleRate / format.sampleRate
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
                inputContinuation.yield(AnalyzerInput(buffer: convertedBuffer))
            }
        } else {
            // Copy buffer to avoid reuse issues from installTap
            guard
                let copy = AVAudioPCMBuffer(
                    pcmFormat: format, frameCapacity: buffer.frameLength)
            else { return }
            copy.frameLength = buffer.frameLength
            if let src = buffer.floatChannelData, let dst = copy.floatChannelData {
                for ch in 0..<Int(format.channelCount) {
                    dst[ch].update(from: src[ch], count: Int(buffer.frameLength))
                }
            }
            inputContinuation.yield(AnalyzerInput(buffer: copy))
        }
    }

    func stop() {
        os_unfair_lock_lock(&lock)
        let currentAnalyzer = analyzer
        inputContinuation?.finish()
        inputContinuation = nil
        converter = nil
        analyzerFormat = nil
        isSetupComplete = false
        analyzer = nil
        os_unfair_lock_unlock(&lock)

        Task {
            try? await currentAnalyzer?.finalizeAndFinishThroughEndOfInput()
        }
    }
}
