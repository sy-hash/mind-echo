import Foundation

/// 音声書き起こしサービスの抽象プロトコル
protocol Transcribing {
    func transcribe(audioURL: URL) async throws -> String
}
