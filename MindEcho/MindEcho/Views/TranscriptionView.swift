import MindEchoCore
import Speech
import SwiftUI

struct TranscriptionView: View {
    let recording: Recording
    @State private var viewModel = TranscriptionViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("書き起こし中...")
                        .accessibilityIdentifier("transcription.loading")
                case .success(let text):
                    ScrollView {
                        Text(text)
                            .padding()
                            .textSelection(.enabled)
                            .accessibilityIdentifier("transcription.resultText")
                    }
                case .failure(let message):
                    ContentUnavailableView {
                        Label("エラー", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    }
                    .accessibilityIdentifier("transcription.error")
                }
            }
            .navigationTitle("書き起こし #\(recording.sequenceNumber)")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            if ProcessInfo.processInfo.arguments.contains("--mock-transcription") {
                viewModel.transcribe = { _, _ in
                    try await Task.sleep(for: .milliseconds(500))
                    return "これはモックの書き起こし結果です。テスト用のテキストデータ。"
                }
                viewModel.checkAuthorization = { .authorized }
            }
            await viewModel.startTranscription(recording: recording)
        }
    }
}
