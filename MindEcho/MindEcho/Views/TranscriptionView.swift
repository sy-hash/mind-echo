import MindEchoCore
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
            await viewModel.startTranscription(recording: recording)
        }
    }
}
