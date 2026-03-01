import MindEchoCore
import Speech
import SwiftUI

struct TranscriptionView: View {
    let recording: Recording
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TranscriptionViewModel()
    @State private var selectedTab: ContentTab = .original
    @State private var promptText: String = ""

    enum ContentTab: String, CaseIterable {
        case original = "原文"
        case aiResult = "AI結果"
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
                            Picker("表示切替", selection: $selectedTab) {
                                ForEach(ContentTab.allCases, id: \.self) { tab in
                                    Text(tab.rawValue).tag(tab)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .accessibilityIdentifier("transcription.tabPicker")
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
                                    aiResultSection
                                }
                            }
                            .padding(.vertical)
                        }

                        if viewModel.isSummarizationAvailable() {
                            promptBar(transcriptionText: text)
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
                viewModel.processPrompt = { text, prompt in
                    try await Task.sleep(for: .milliseconds(300))
                    return "これはモックのAI適用結果です。"
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
    private var aiResultSection: some View {
        switch viewModel.promptState {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView("AI処理中...")
                .padding(.horizontal)
                .accessibilityIdentifier("transcription.aiResultLoading")
        case .success(let result):
            Text(result)
                .padding(.horizontal)
                .textSelection(.enabled)
                .accessibilityIdentifier("transcription.aiResultText")
        case .failure(let message):
            Text(message)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .accessibilityIdentifier("transcription.aiResultError")
        }
    }

    private func promptBar(transcriptionText: String) -> some View {
        HStack(spacing: 8) {
            TextField("プロンプトを入力...", text: $promptText)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("transcription.promptField")
            Button("適用") {
                let currentPrompt = promptText
                Task {
                    await viewModel.applyAIPrompt(
                        transcriptionText: transcriptionText,
                        prompt: currentPrompt
                    )
                    selectedTab = .aiResult
                }
            }
            .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.promptState == .loading)
            .accessibilityIdentifier("transcription.applyButton")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
