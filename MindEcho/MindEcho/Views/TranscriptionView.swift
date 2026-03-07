import MindEchoCore
import Speech
import SwiftUI

struct TranscriptionView: View {
    let recording: Recording
    var vocabularyWords: [String] = []
    var transcriberType: TranscriberType = .speechTranscriber
    @Environment(\.dismiss) private var dismiss
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
                        VStack(alignment: .leading, spacing: 16) {
                            summarySection
                            Text(text)
                                .padding(.horizontal)
                                .textSelection(.enabled)
                                .accessibilityIdentifier("transcription.resultText")
                        }
                        .padding(.vertical)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityIdentifier("transcription.closeButton")
                }
                if case .success = viewModel.state {
                    ToolbarItem(placement: .primaryAction) {
                        retryButton
                    }
                }
                if case .failure = viewModel.state {
                    ToolbarItem(placement: .primaryAction) {
                        retryButton
                    }
                }
            }
        }
        .task {
            viewModel.vocabularyWords = vocabularyWords
            viewModel.transcriberType = transcriberType
            if ProcessInfo.processInfo.arguments.contains("--mock-transcription") {
                viewModel.transcribe = { _, _, _, _ in
                    try await Task.sleep(for: .milliseconds(500))
                    return "これはモックの書き起こし結果です。テスト用のテキストデータ。"
                }
                viewModel.checkAuthorization = { .authorized }
            }
            if ProcessInfo.processInfo.arguments.contains("--mock-summarization") {
                viewModel.summarize = { text in
                    try await Task.sleep(for: .milliseconds(300))
                    return "これはモックの要約結果です。"
                }
                viewModel.isSummarizationAvailable = { true }
            }
            await viewModel.startTranscription(recording: recording)
        }
    }

    private var retryButton: some View {
        Button {
            viewModel.transcriberType = transcriberType
            Task {
                await viewModel.retryTranscription(recording: recording)
            }
        } label: {
            Image(systemName: "arrow.clockwise")
        }
        .accessibilityIdentifier("transcription.retryButton")
    }

    @ViewBuilder
    private var summarySection: some View {
        switch viewModel.summaryState {
        case .idle:
            EmptyView()
        case .loading:
            VStack(alignment: .leading, spacing: 8) {
                Label("要約", systemImage: "text.document")
                    .font(.headline)
                ProgressView("要約を生成中...")
                    .accessibilityIdentifier("transcription.summaryLoading")
            }
            .padding(.horizontal)
        case .success(let summary):
            VStack(alignment: .leading, spacing: 8) {
                Label("要約", systemImage: "text.document")
                    .font(.headline)
                Text(summary)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("transcription.summaryText")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            Divider()
                .padding(.horizontal)
        case .failure(let message):
            VStack(alignment: .leading, spacing: 8) {
                Label("要約", systemImage: "text.document")
                    .font(.headline)
                Text(message)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("transcription.summaryError")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            Divider()
                .padding(.horizontal)
        case .unavailable:
            EmptyView()
        }
    }
}
