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
                            Text(text)
                                .padding()
                                .textSelection(.enabled)
                                .accessibilityIdentifier("recording.transcriptionResult")
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
                viewModel.transcribe = { _, _ in
                    try await Task.sleep(for: .milliseconds(500))
                    return "これはモックの書き起こし結果です。テスト用のテキストデータ。"
                }
            }
            viewModel.startRecording()
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
