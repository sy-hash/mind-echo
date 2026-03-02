import AVFoundation
import Foundation
import Speech

protocol LiveTranscribing: Sendable {
    func transcriptionStream(locale: Locale) -> AsyncThrowingStream<String, Error>
    func stop()
}

final class LiveTranscriptionService: LiveTranscribing {
    nonisolated(unsafe) private var audioEngine: AVAudioEngine?
    nonisolated(unsafe) private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    nonisolated(unsafe) private var recognitionTask: SFSpeechRecognitionTask?

    func transcriptionStream(locale: Locale) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            guard let recognizer = SFSpeechRecognizer(locale: locale),
                  recognizer.isAvailable else {
                continuation.finish(throwing: LiveTranscriptionError.recognizerUnavailable)
                return
            }

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.recognitionRequest = request

            let engine = AVAudioEngine()
            self.audioEngine = engine
            let inputNode = engine.inputNode
            let format = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }

            self.recognitionTask = recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.finish(throwing: error)
                    return
                }
                if let result {
                    continuation.yield(result.bestTranscription.formattedString)
                    if result.isFinal {
                        continuation.finish()
                    }
                }
            }

            do {
                try engine.start()
            } catch {
                continuation.finish(throwing: error)
                return
            }

            continuation.onTermination = { [weak self] _ in
                self?.stop()
            }
        }
    }

    func stop() {
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
    }
}

enum LiveTranscriptionError: Error, LocalizedError {
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "音声認識が利用できません"
        }
    }
}
