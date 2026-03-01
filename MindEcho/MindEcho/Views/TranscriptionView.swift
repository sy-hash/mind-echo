import MindEchoCore
import Speech
import SwiftUI

struct TranscriptionView: View {
    let recording: Recording
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TranscriptionViewModel()
    @State private var selectedTab: ContentTab = .original
    @State private var promptText: String = ""

    private enum ContentTab: Hashable {
        case original
        case aiResult
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    ProgressView("書き起こし中...")
                        .accessibilityIdentifier("transcription.loading")
                case .success(let text):
                    VStack(spacing: 0) {
                        if viewModel.promptState != .idle {
                            Picker("表示モード", selection: $selectedTab) {
                                Text("原文").tag(ContentTab.original)
                                Text("AI結果").tag(ContentTab.aiResult)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .accessibilityIdentifier("transcription.tabPicker")
                            Divider()
                        }
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                if selectedTab == .original {
                                    summarySection
                                    Text(text)
                                        .padding(.horizontal)
                                        .textSelection(.enabled)
                                        .accessibilityIdentifier("transcription.resultText")
                                } else {
                                    aiResultContent
                                }
                            }
                            .padding(.vertical)
                        }
                        if viewModel.isSummarizationAvailable() {
                            promptBar(transcriptionText: text)
                        }
                    }
                    .onChange(of: viewModel.promptState) { _, newState in
                        if case .success = newState {
                            selectedTab = .aiResult
                        }
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
            }
        }
        .task {
            if ProcessInfo.processInfo.arguments.contains("--mock-transcription") {
                viewModel.transcribe = { _, _ in
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
            if ProcessInfo.processInfo.arguments.contains("--mock-ai-prompt") {
                viewModel.processPrompt = { _, _ in
                    try await Task.sleep(for: .milliseconds(300))
                    return "これはモックのAIプロンプト適用結果です。"
                }
                viewModel.isSummarizationAvailable = { true }
            }
            await viewModel.startTranscription(recording: recording)
        }
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

    @ViewBuilder
    private var aiResultContent: some View {
        switch viewModel.promptState {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView("AI処理中...")
                .frame(maxWidth: .infinity)
                .padding()
                .accessibilityIdentifier("transcription.aiResultLoading")
        case .success(let result):
            Text(result)
                .padding(.horizontal)
                .textSelection(.enabled)
                .accessibilityIdentifier("transcription.aiResultText")
        case .failure(let message):
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text(message)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .accessibilityIdentifier("transcription.aiResultError")
        }
    }

    @ViewBuilder
    private func promptBar(transcriptionText: String) -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                TextField("プロンプトを入力...", text: $promptText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("transcription.promptField")
                Button("適用") {
                    let capturedPrompt = promptText
                    Task {
                        await viewModel.applyAIPrompt(transcriptionText: transcriptionText, prompt: capturedPrompt)
                    }
                }
                .disabled(promptText.isEmpty || viewModel.promptState == .loading)
                .accessibilityIdentifier("transcription.applyButton")
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.bar)
        }
    }
}
