import DSWaveformImage
import DSWaveformImageViews
import SwiftUI

struct RecordingModalView: View {
    var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.isRecording {
                    // Recording duration
                    Text(formatDuration(viewModel.recordingDuration))
                        .font(.system(.largeTitle, design: .monospaced))
                        .accessibilityIdentifier("recording.duration")

                    // Waveform
                    WaveformLiveCanvas(
                        samples: viewModel.audioLevels,
                        configuration: Waveform.Configuration(
                            style: .striped(.init(color: .red, width: 3, spacing: 3)),
                            damping: .init()
                        ),
                        shouldDrawSilencePadding: false
                    )
                    .frame(height: 80)
                    .accessibilityIdentifier("recording.waveform")

                    // Pause/Resume + Stop buttons
                    HStack(spacing: 30) {
                        if viewModel.isRecordingPaused {
                            Button {
                                viewModel.resumeRecording()
                            } label: {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 50))
                            }
                            .accessibilityIdentifier("recording.resumeButton")
                        } else {
                            Button {
                                viewModel.pauseRecording()
                            } label: {
                                Image(systemName: "pause.circle.fill")
                                    .font(.system(size: 50))
                            }
                            .accessibilityIdentifier("recording.pauseButton")
                        }

                        Button {
                            viewModel.stopRecording()
                            Task {
                                await viewModel.startTranscription()
                            }
                        } label: {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.red)
                        }
                        .accessibilityIdentifier("recording.stopButton")
                    }

                    // Live transcription area
                    if viewModel.hasLiveTranscription {
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading) {
                                    if let error = viewModel.liveTranscriptionError {
                                        Text(error)
                                            .foregroundStyle(.red)
                                            .accessibilityIdentifier("recording.liveTranscriptionError")
                                    } else if viewModel.liveTranscriptionText.isEmpty {
                                        Text("話し始めると書き起こしが表示されます")
                                            .foregroundStyle(.secondary)
                                            .accessibilityIdentifier("recording.liveTranscriptionPlaceholder")
                                    } else {
                                        Text(viewModel.liveTranscriptionText)
                                            .accessibilityIdentifier("recording.liveTranscriptionText")
                                    }
                                    Color.clear.frame(height: 1).id("bottom")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                            }
                            .frame(maxHeight: 150)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .accessibilityIdentifier("recording.liveTranscription")
                            .onChange(of: viewModel.liveTranscriptionText) {
                                withAnimation {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            }
                        }
                    }
                } else {
                    // Transcription result area
                    switch viewModel.transcriptionState {
                    case .idle:
                        EmptyView()
                    case .loading:
                        ProgressView("書き起こし中...")
                            .padding()
                    case .success(let text):
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                summarySectionView
                                Text(text)
                                    .padding()
                                    .textSelection(.enabled)
                                    .accessibilityIdentifier("recording.transcriptionResult")
                            }
                        }
                    case .failure(let message):
                        VStack(spacing: 12) {
                            Label("書き起こし失敗", systemImage: "exclamationmark.triangle")
                                .font(.headline)
                            Text(message)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .accessibilityIdentifier("recording.transcriptionResult")
                    }

                    Button("閉じる") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("録音中")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("--mock-transcription") {
                viewModel.transcribe = { _, _, _, _, _ in
                    try await Task.sleep(for: .milliseconds(500))
                    return "これはモックの書き起こし結果です。テスト用のテキストデータ。"
                }
            }
            if ProcessInfo.processInfo.arguments.contains("--mock-summarization") {
                viewModel.summarize = { _, _, _, _ in
                    try await Task.sleep(for: .milliseconds(300))
                    return "これはモックの要約結果です。"
                }
                viewModel.isSummarizationAvailable = { _, _ in true }
            }
            viewModel.startRecording()
        }
    }

    @ViewBuilder
    private var summarySectionView: some View {
        switch viewModel.summaryState {
        case .idle:
            EmptyView()
        case .loading:
            VStack(alignment: .leading, spacing: 8) {
                Label("要約", systemImage: "text.document")
                    .font(.headline)
                ProgressView("要約を生成中...")
                    .accessibilityIdentifier("recording.summaryLoading")
            }
            .padding(.horizontal)
        case .success(let summary):
            VStack(alignment: .leading, spacing: 8) {
                Label("要約", systemImage: "text.document")
                    .font(.headline)
                Text(summary)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("recording.summaryText")
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
                    .accessibilityIdentifier("recording.summaryError")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            Divider()
                .padding(.horizontal)
        case .unavailable:
            EmptyView()
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
