import MindEchoAudio
import MindEchoCore
import SwiftData
import SwiftUI

private enum ShareContent: Identifiable {
    case file(URL)
    case text(String)

    var id: String {
        switch self {
        case .file(let url): return url.absoluteString
        case .text(let text): return "text:\(text.hashValue)"
        }
    }

    var activityItems: [Any] {
        switch self {
        case .file(let url): return [url]
        case .text(let text): return [text]
        }
    }
}

struct EntryDetailView: View {
    @State private var viewModel: EntryDetailViewModel
    @State private var shareContent: ShareContent?
    @State private var transcriptionTargetRecording: Recording?

    init(entry: JournalEntry, modelContext: ModelContext, audioPlayer: any AudioPlaying = AudioPlayerService()) {
        _viewModel = State(initialValue: EntryDetailViewModel(
            entry: entry,
            modelContext: modelContext,
            audioPlayer: audioPlayer
        ))
    }

    var body: some View {
        List {
            // Date header
            Section {
                Text(DateHelper.displayString(for: viewModel.entry.date))
                    .font(.title2)
                    .accessibilityIdentifier("detail.dateHeader")
            }

            // Recordings section
            if !viewModel.entry.recordings.isEmpty {
                Section("録音") {
                    ForEach(viewModel.entry.sortedRecordings) { recording in
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                if viewModel.playingRecordingId == recording.id && viewModel.isPlaying {
                                    viewModel.pausePlayback()
                                } else {
                                    viewModel.playRecording(recording)
                                }
                            } label: {
                                HStack {
                                    Text("#\(recording.sequenceNumber)")
                                        .font(.headline)

                                    Text(formatTime(recording.recordedAt))
                                        .foregroundStyle(.secondary)

                                    Text(formatDuration(recording.duration))
                                        .foregroundStyle(.secondary)

                                    Spacer()

                                    Image(systemName: viewModel.playingRecordingId == recording.id && viewModel.isPlaying ? "pause.fill" : "play.fill")
                                }
                            }
                            .buttonStyle(.borderless)
                            .accessibilityIdentifier("detail.recordingRow.\(recording.sequenceNumber)")

                            if let transcription = recording.transcription {
                                Text(transcription)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .accessibilityIdentifier("detail.transcription.\(recording.sequenceNumber)")
                            } else {
                                Button {
                                    transcriptionTargetRecording = recording
                                } label: {
                                    Label("書き起こし", systemImage: "doc.text")
                                        .font(.subheadline)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityIdentifier("detail.transcribeButton.\(recording.sequenceNumber)")
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteRecording(recording)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                            .accessibilityIdentifier("detail.deleteButton.\(recording.sequenceNumber)")
                        }
                    }
                }
            }
        }
        .navigationTitle("詳細")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        exportAndShare()
                    } label: {
                        Label("音声", systemImage: "waveform")
                    }
                    .accessibilityIdentifier("detail.shareAudioButton")

                    Button {
                        exportTranscriptionAndShare()
                    } label: {
                        Label("書き起こしテキスト", systemImage: "doc.text")
                    }
                    .disabled(!viewModel.allRecordingsTranscribed)
                    .accessibilityIdentifier("detail.shareTranscriptionButton")
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityIdentifier("detail.shareButton")
            }
        }
        .sheet(item: $shareContent) { content in
            ShareSheet(activityItems: content.activityItems)
        }
        .sheet(item: $transcriptionTargetRecording) { recording in
            TranscriptionView(recording: recording)
        }
    }

    private func exportAndShare() {
        Task {
            do {
                let url = try await viewModel.exportForSharing()
                shareContent = .file(url)
            } catch {
                // Handle error silently for now
            }
        }
    }

    private func exportTranscriptionAndShare() {
        let text = viewModel.transcriptionTextForSharing()
        guard !text.isEmpty else { return }
        shareContent = .text(text)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// UIKit ShareSheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context: Context) {}
}
