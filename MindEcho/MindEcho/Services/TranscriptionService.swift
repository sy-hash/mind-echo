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
final class TranscriptionService {

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
        // SpeechAnalyzer (iOS 26+) を使用してオンデバイスで書き起こす
        let analyzer = SpeechAnalyzer()

        // 音声ファイルを AVAudioFile として開く
        let audioFile = try AVAudioFile(forReading: audioURL)
        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw TranscriptionError.failed("音声バッファの作成に失敗しました")
        }
        try audioFile.read(into: buffer)

        // バッファを AsyncStream に変換して SpeechAnalyzer に渡す
        let (stream, continuation) = AsyncStream<AVAudioPCMBuffer>.makeStream()
        continuation.yield(buffer)
        continuation.finish()

        var finalText = ""
        for try await result in analyzer.results(for: stream, audioFormat: format) {
            if let transcription = result.speechRecognitionResult?.bestTranscription {
                finalText = transcription.formattedString
            }
        }

        return finalText
    }
}
