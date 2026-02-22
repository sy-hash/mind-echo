import Foundation
import AVFAudio
import Speech

struct TranscriptionService {
    func transcribe(audioFileURL: URL, locale: Locale) async throws -> String {
        let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)

        async let transcriptionFuture: String = transcriber.results.reduce("") { partialResult, result in
            partialResult + String(result.text.characters) + " "
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])

        if let lastSample = try await analyzer.analyzeSequence(
            from: AVAudioFile(forReading: audioFileURL)
        ) {
            try await analyzer.finalizeAndFinish(through: lastSample)
        } else {
            await analyzer.cancelAndFinishNow()
        }

        let resultText = await transcriptionFuture
        return resultText.trimmingCharacters(in: CharacterSet.whitespaces)
    }
}
