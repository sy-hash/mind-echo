import MindEchoAudio
import MindEchoCore
import SwiftData
import SwiftUI

struct EntryDetailView: View {
    @State private var viewModel: EntryDetailViewModel
    @State private var shareURL: URL?
    @State private var isExporting = false

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
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteRecording(recording)
                            } label: {
                                Label("削除", systemImage: "trash")
                            }
                            .accessibilityIdentifier("detail.deleteButton.\(recording.sequenceNumber)")
                        }
                        .accessibilityIdentifier("detail.recordingRow.\(recording.sequenceNumber)")
                    }
                }
                .accessibilityIdentifier("detail.recordingsList")
            }
        }
        .navigationTitle("詳細")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    exportAndShare()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityIdentifier("detail.shareButton")
            }
        }
        .sheet(item: $shareURL) { url in
            ShareSheet(activityItems: [url])
        }
    }

    @MainActor
    private func exportAndShare() {
        isExporting = true
        Task { @MainActor in
            do {
                let url = try await viewModel.exportForSharing()
                shareURL = url
            } catch {
                // Handle error silently for now
            }
            isExporting = false
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

// Make URL conform to Identifiable for sheet(item:)
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// UIKit ShareSheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context: Context) {}
}
