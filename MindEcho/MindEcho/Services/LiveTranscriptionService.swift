import AVFoundation
import Foundation
import Speech

/// 録音中のリアルタイム書き起こしを行うサービス。
/// SFSpeechRecognizer を使ってオーディオバッファから随時テキストを生成する。
final class LiveTranscriptionService: @unchecked Sendable {
    /// 書き起こしテキストが更新されたときに呼ばれるコールバック（メインスレッドから呼ばれる）。
    var onTextUpdate: ((String) -> Void)?

    private let speechRecognizer: SFSpeechRecognizer?
    nonisolated(unsafe) private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    init(locale: Locale = Locale(identifier: "ja-JP")) {
        speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    /// 音声認識セッションを開始する。
    func start() {
        guard let speechRecognizer, speechRecognizer.isAvailable else { return }

        recognitionTask?.cancel()
        recognitionTask = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result {
                    self?.onTextUpdate?(result.bestTranscription.formattedString)
                }
                if error != nil || result?.isFinal == true {
                    self?.recognitionTask = nil
                    self?.recognitionRequest = nil
                }
            }
        }
    }

    /// 音声バッファを認識エンジンに送る。音声スレッドから呼ばれる。
    func processBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        recognitionRequest?.append(buffer)
    }

    /// 音声入力の終了を通知し、最終結果を受け取れる状態にする。
    func stop() {
        recognitionRequest?.endAudio()
    }

    /// セッションをキャンセルする。
    func cancel() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}
