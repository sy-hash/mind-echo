import MindEchoAudio
import MindEchoCore
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

private enum ShareContent: Identifiable {
    case audioFile(URL)
    case textFile(URL)

    var id: String {
        switch self {
        case .audioFile(let url): return url.absoluteString
        case .textFile(let url): return url.absoluteString
        }
    }

    var activityItems: [Any] {
        switch self {
        case .audioFile(let url):
            return [url]
        case .textFile(let url):
            return [TextFileActivityItemSource(url: url)]
        }
    }
}

/// UIActivityItemSource that passes text content directly while using file URL as placeholder.
/// The placeholder URL ensures NotebookLM appears in the share sheet,
/// but itemForActivityType returns the String content so it doesn't try to fetch a file:// URL.
private class TextFileActivityItemSource: NSObject, UIActivityItemSource {
    let url: URL
    private let textContent: String

    init(url: URL) {
        self.url = url
        self.textContent = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return textContent
    }

    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.utf8PlainText.identifier
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
                shareContent = .audioFile(url)
            } catch {
                // Handle error silently for now
            }
        }
    }

    private func exportTranscriptionAndShare() {
        do {
            let url = try viewModel.exportTranscriptionForSharing()
            shareContent = .textFile(url)
        } catch {
            // Handle error silently for now
        }
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
