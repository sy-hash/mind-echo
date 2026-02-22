import AVFoundation
import Foundation
import Speech

// MARK: - Error

enum TranscriptionError: LocalizedError {
    case notAuthorized
    case unavailable
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "音声認識の権限がありません。設定アプリから権限を許可してください。"
        case .unavailable:
            return "音声認識が現在利用できません。"
        case .failed(let message):
            return "書き起こしに失敗しました: \(message)"
        }
    }
}

// MARK: - TranscriptionService

/// SpeechAnalyzer（iOS 26+）を使ったオンデバイス音声書き起こしサービス
final class TranscriptionService: Transcribing {

    // MARK: Authorization

    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: Transcription

    /// 指定した音声ファイルを書き起こす
    /// - Parameter audioURL: 書き起こし対象の音声ファイル URL
    /// - Returns: 書き起こし結果のテキスト
    func transcribe(audioURL: URL) async throws -> String {
        guard await Self.requestAuthorization() else {
            throw TranscriptionError.notAuthorized
        }

        return try await transcribeWithSpeechAnalyzer(audioURL: audioURL)
    }

    // MARK: - Private

    private func transcribeWithSpeechAnalyzer(audioURL: URL) async throws -> String {
        let transcriber = SpeechTranscriber(locale: .current, preset: .transcription)
        let audioFile = try AVAudioFile(forReading: audioURL)
        let analyzer = SpeechAnalyzer(modules: [transcriber])

        // アナライザーの起動と結果収集を並行して実行
        return try await withThrowingTaskGroup(of: String?.self) { group in
            group.addTask {
                try await analyzer.start(inputAudioFile: audioFile, finishAfterFile: true)
                return nil
            }

            group.addTask {
                var finalText = ""
                for try await result in transcriber.results {
                    finalText = String(result.text.characters)
                }
                return finalText
            }

            var transcription = ""
            for try await result in group {
                if let text = result {
                    transcription = text
                }
            }
            return transcription
        }
    }
}
