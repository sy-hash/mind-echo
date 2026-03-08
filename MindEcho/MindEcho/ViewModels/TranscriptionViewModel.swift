import Foundation
import MindEchoCore
import Observation
import Speech

@Observable
final class TranscriptionViewModel {
    enum State: Equatable {
        case idle
        case loading
        case success(String)
        case failure(String)
    }

    enum SummaryState: Equatable {
        case idle
        case loading
        case success(String)
        case failure(String)
        case unavailable
    }

    private(set) var state: State = .idle
    private(set) var summaryState: SummaryState = .idle
    var vocabularyWords: [String] = []
    var transcriberType: TranscriberType = .speechTranscriber
    var openAIAPIKey: String = ""
    var summaryInstruction: String = SummaryPromptStore.defaultInstruction

    @ObservationIgnored
    var transcribe: (URL, Locale, [String], TranscriberType, String) async throws -> String = { url, locale, contextualStrings, transcriberType, openAIAPIKey in
        try await TranscriptionService().transcribe(audioFileURL: url, locale: locale, contextualStrings: contextualStrings, transcriberType: transcriberType, openAIAPIKey: openAIAPIKey)
    }
    @ObservationIgnored
    var checkAuthorization: () -> SFSpeechRecognizerAuthorizationStatus = {
        SFSpeechRecognizer.authorizationStatus()
    }
    @ObservationIgnored
    var requestAuthorization: (@escaping (SFSpeechRecognizerAuthorizationStatus) -> Void) -> Void = {
        SFSpeechRecognizer.requestAuthorization($0)
    }
    @ObservationIgnored
    var summarize: (String, String) async throws -> String = SummarizationService().summarize
    @ObservationIgnored
    var isSummarizationAvailable: () -> Bool = { SummarizationService.isAvailable }

    func retryTranscription(recording: Recording) async {
        recording.transcription = nil
        recording.summary = nil
        summaryState = .idle
        await startTranscription(recording: recording)
    }

    func startTranscription(recording: Recording) async {
        // 保存済みの書き起こしがあれば即表示
        if let existing = recording.transcription {
            state = .success(existing)
            await startSummarization(recording: recording, text: existing)
            return
        }

        state = .loading

        let status = checkAuthorization()
        if status == .notDetermined {
            let granted = await withCheckedContinuation { continuation in
                requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
            if !granted {
                state = .failure("音声認識の権限が許可されていません。設定アプリから許可してください。")
                return
            }
        } else if status != .authorized {
            state = .failure("音声認識の権限が許可されていません。設定アプリから許可してください。")
            return
        }

        let fileURL = FilePathManager.recordingsDirectory
            .appendingPathComponent(recording.audioFileName)

        do {
            let text = try await transcribe(fileURL, Locale(identifier: "ja-JP"), vocabularyWords, transcriberType, openAIAPIKey)
            if text.isEmpty {
                state = .failure("書き起こし結果が空でした。")
            } else {
                recording.transcription = text
                state = .success(text)
                await startSummarization(recording: recording, text: text)
            }
        } catch {
            state = .failure("書き起こしに失敗しました: \(error.localizedDescription)")
        }
    }

    func startSummarization(recording: Recording, text: String) async {
        // 保存済みの要約があれば即表示
        if let existing = recording.summary {
            summaryState = .success(existing)
            return
        }

        guard isSummarizationAvailable() else {
            summaryState = .unavailable
            return
        }

        summaryState = .loading

        do {
            let summary = try await summarize(text, summaryInstruction)
            if summary.isEmpty {
                summaryState = .failure("要約結果が空でした。")
            } else {
                recording.summary = summary
                summaryState = .success(summary)
            }
        } catch {
            summaryState = .failure("要約に失敗しました: \(error.localizedDescription)")
        }
    }
}
