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

    func transcriptionStream(locale: Locale) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
            let analyzer = SpeechAnalyzer(modules: [transcriber])
            self.analyzer = analyzer

            // Set up AVAudioEngine for microphone capture
            let audioEngine = AVAudioEngine()
            self.audioEngine = audioEngine
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            let bufferStream = AsyncStream<AnalyzerInput> { bufferContinuation in
                inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                    bufferContinuation.yield(AnalyzerInput(buffer: buffer))
                }
            }

            // Collect transcription results
            Task {
                do {
                    var accumulated = ""
                    for try await result in transcriber.results {
                        accumulated += String(result.text.characters) + " "
                        let trimmed = accumulated.trimmingCharacters(in: .whitespaces)
                        continuation.yield(trimmed)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            // Start the audio engine and analyzer
            Task {
                do {
                    audioEngine.prepare()
                    try audioEngine.start()
                    try await analyzer.start(inputSequence: bufferStream)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func stop() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        Task {
            await analyzer?.cancelAndFinishNow()
        }
        analyzer = nil
    }
}
