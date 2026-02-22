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

    private(set) var state: State = .idle

    @ObservationIgnored
    var transcribe: (URL, Locale) async throws -> String = TranscriptionService().transcribe
    @ObservationIgnored
    var checkAuthorization: () -> SFSpeechRecognizerAuthorizationStatus = {
        SFSpeechRecognizer.authorizationStatus()
    }
    @ObservationIgnored
    var requestAuthorization: (@escaping (SFSpeechRecognizerAuthorizationStatus) -> Void) -> Void = {
        SFSpeechRecognizer.requestAuthorization($0)
    }

    func startTranscription(recording: Recording) async {
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
            let text = try await transcribe(fileURL, Locale(identifier: "ja-JP"))
            state = text.isEmpty ? .failure("書き起こし結果が空でした。") : .success(text)
        } catch {
            state = .failure("書き起こしに失敗しました: \(error.localizedDescription)")
        }
    }
}
