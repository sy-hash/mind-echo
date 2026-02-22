import Foundation

/// UIテスト用の書き起こしサービスモック
final class MockTranscriptionService: Transcribing {
    enum MockResult {
        case success(String)
        case failure
    }

    private let mockResult: MockResult

    init(mockResult: MockResult) {
        self.mockResult = mockResult
    }

    func transcribe(audioURL: URL) async throws -> String {
        // シート表示のアニメーションを確認できるよう短いディレイを入れる
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s
        switch mockResult {
        case .success(let text):
            return text
        case .failure:
            throw TranscriptionError.unavailable
        }
    }
}
