import AVFAudio
import Foundation
import Speech

struct TranscriptionService {
    func transcribe(
        audioFileURL: URL,
        locale: Locale,
        contextualStrings: [String] = [],
        transcriberType: TranscriberType = .speechTranscriber,
        openAIAPIKey: String = ""
    ) async throws -> String {
        switch transcriberType {
        case .speechTranscriber:
            try await transcribeWithSpeech(
                audioFileURL: audioFileURL, locale: locale, contextualStrings: contextualStrings)
        case .dictationTranscriber:
            try await transcribeWithDictation(
                audioFileURL: audioFileURL, locale: locale, contextualStrings: contextualStrings)
        case .whisperAPI:
            try await WhisperAPIService().transcribe(
                audioFileURL: audioFileURL, apiKey: openAIAPIKey, contextualStrings: contextualStrings)
        }
    }

    private func transcribeWithSpeech(audioFileURL: URL, locale: Locale, contextualStrings: [String]) async throws
        -> String
    {
        let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)

        async let transcriptionFuture: String = transcriber.results.reduce("") { partialResult, result in
            partialResult + String(result.text.characters) + " "
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])

        if !contextualStrings.isEmpty {
            let context = AnalysisContext()
            context.contextualStrings = [
                AnalysisContext.ContextualStringsTag("vocabulary"): contextualStrings
            ]
            try await analyzer.setContext(context)
        }

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

    private func transcribeWithDictation(audioFileURL: URL, locale: Locale, contextualStrings: [String]) async throws
        -> String
    {
        let transcriber = DictationTranscriber(locale: locale, preset: .longDictation)

        async let transcriptionFuture: String = transcriber.results.reduce("") { partialResult, result in
            partialResult + String(result.text.characters) + " "
        }

        let analyzer = SpeechAnalyzer(modules: [transcriber])

        if !contextualStrings.isEmpty {
            let context = AnalysisContext()
            context.contextualStrings = [
                AnalysisContext.ContextualStringsTag("vocabulary"): contextualStrings
            ]
            try await analyzer.setContext(context)
        }

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
