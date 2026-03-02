import AVFoundation
import Foundation
import Speech

@Observable
class LiveTranscriptionService {
    private(set) var liveText: String = ""

    @ObservationIgnored private var speechRecognizer: SFSpeechRecognizer?
    @ObservationIgnored private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var recognitionTask: SFSpeechRecognitionTask?

    func start(locale: Locale) {
        liveText = ""
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            startRecognition(locale: locale)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { _ in
                // Permission granted after session started; will take effect next time
            }
        default:
            break
        }
    }

    func appendBuffer(_ buffer: AVAudioPCMBuffer) {
        recognitionRequest?.append(buffer)
    }

    func stop() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        speechRecognizer = nil
    }

    // MARK: - Private

    private func startRecognition(locale: Locale) {
        let recognizer = SFSpeechRecognizer(locale: locale)
        guard let recognizer, recognizer.isAvailable else { return }
        speechRecognizer = recognizer

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                let text = result.bestTranscription.formattedString
                Task { @MainActor [weak self] in
                    self?.liveText = text
                }
            }
            if error != nil || (result?.isFinal == true) {
                Task { @MainActor [weak self] in
                    self?.recognitionRequest = nil
                    self?.recognitionTask = nil
                }
            }
        }
    }
}
