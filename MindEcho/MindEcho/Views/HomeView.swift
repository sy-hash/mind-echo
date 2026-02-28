import MindEchoAudio
import MindEchoCore
import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var transcriptionTargetRecording: Recording?
    @State private var isRecordingModalPresented = false
    @State private var shareItems: [Any]?

    init(modelContext: ModelContext, audioRecorder: any AudioRecording, audioPlayer: any AudioPlaying = AudioPlayerService()) {
        _viewModel = State(initialValue: HomeViewModel(
            modelContext: modelContext,
            audioRecorder: audioRecorder,
            audioPlayer: audioPlayer
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                // Today's section
                todaySection

                // Past entries sections
                ForEach(viewModel.pastEntries) { entry in
                    pastEntrySection(entry)
                }
            }
            .listStyle(.grouped)
            .accessibilityIdentifier("home.entryList")
            .safeAreaInset(edge: .bottom) {
                Button {
                    isRecordingModalPresented = true
                } label: {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.red)
                }
                .accessibilityIdentifier("home.recordButton")
                .padding(.vertical)
            }
            .navigationTitle("MindEcho")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.todayEntry != nil && !(viewModel.todayEntry?.recordings.isEmpty ?? true) {
                        shareMenu(for: viewModel.todayEntry!)
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { shareItems != nil },
                set: { if !$0 { shareItems = nil } }
            )) {
                if let items = shareItems {
                    ShareSheet(activityItems: items)
                }
            }
            .onAppear {
                viewModel.fetchAllEntries()
            }
            .sheet(isPresented: $isRecordingModalPresented, onDismiss: {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                }
                viewModel.resetTranscriptionState()
                viewModel.fetchAllEntries()
            }) {
                RecordingModalView(viewModel: viewModel)
            }
            .sheet(item: $transcriptionTargetRecording) { recording in
                TranscriptionView(recording: recording)
                    .accessibilityIdentifier("home.transcriptionSheet")
            }
        }
    }

    // MARK: - Today Section

    @ViewBuilder
    private var todaySection: some View {
        Section {
            if let entry = viewModel.todayEntry, !entry.recordings.isEmpty {
                ForEach(entry.sortedRecordings) { recording in
                    recordingRow(recording, isToday: true)
                }
            } else {
                Text("録音がありません")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("home.emptyState")
            }
        } header: {
            Text(DateHelper.displayString(for: DateHelper.today()))
                .accessibilityIdentifier("home.dateLabel")
        }
    }

    // MARK: - Past Entry Section

    @ViewBuilder
    private func pastEntrySection(_ entry: JournalEntry) -> some View {
        Section {
            ForEach(entry.sortedRecordings) { recording in
                recordingRow(recording, isToday: false, entry: entry)
            }
        } header: {
            Text(DateHelper.displayString(for: entry.date))
                .accessibilityIdentifier("home.sectionHeader.\(dateTag(entry.date))")
        }
    }

    // MARK: - Recording Row

    @ViewBuilder
    private func recordingRow(_ recording: Recording, isToday: Bool, entry: JournalEntry? = nil) -> some View {
        let identifier = isToday
            ? "home.recordingRow.\(recording.sequenceNumber)"
            : "past.recordingRow.\(dateTag(entry!.date)).\(recording.sequenceNumber)"

        HStack(alignment: .top, spacing: 8) {
            // Info area: tapping anywhere here toggles playback.
            // Kept as a separate inner view so the transcribe button below
            // is NOT inside this gesture area and remains individually accessible.
            VStack(alignment: .leading, spacing: 6) {
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
                if let summary = recording.summary {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .accessibilityIdentifier(
                            isToday
                                ? "home.summary.\(recording.sequenceNumber)"
                                : "past.summary.\(dateTag(entry!.date)).\(recording.sequenceNumber)"
                        )
                } else if let transcription = recording.transcription {
                    Text(transcription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .accessibilityIdentifier(
                            isToday
                                ? "home.transcription.\(recording.sequenceNumber)"
                                : "past.transcription.\(dateTag(entry!.date)).\(recording.sequenceNumber)"
                        )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if viewModel.playingRecordingId == recording.id && viewModel.isPlaying {
                    viewModel.pausePlayback()
                } else {
                    viewModel.playRecording(recording)
                }
            }

            // Transcribe button is placed outside the tap-gesture VStack so that
            // XCTest can locate and interact with it as an independent button element.
            Button {
                transcriptionTargetRecording = recording
            } label: {
                Image(systemName: recording.hasTranscription ? "doc.text.fill" : "doc.text")
            }
            .accessibilityIdentifier(
                isToday
                    ? "home.transcribeButton.\(recording.sequenceNumber)"
                    : "past.transcribeButton.\(dateTag(entry!.date)).\(recording.sequenceNumber)"
            )
        }
        .swipeActions(edge: .trailing) {
            if let targetEntry = isToday ? viewModel.todayEntry : entry {
                Button(role: .destructive) {
                    viewModel.deleteRecording(recording, from: targetEntry)
                } label: {
                    Label("削除", systemImage: "trash")
                }
                .accessibilityIdentifier(
                    isToday
                        ? "home.deleteButton.\(recording.sequenceNumber)"
                        : "past.deleteButton.\(dateTag(entry!.date)).\(recording.sequenceNumber)"
                )
            }
        }
        .accessibilityIdentifier(identifier)
    }

    // MARK: - Share Menu

    private func shareMenu(for entry: JournalEntry) -> some View {
        Menu {
            Button {
                exportAndShareAudio(entry: entry)
            } label: {
                Label("音声を共有", systemImage: "waveform")
            }
            .accessibilityIdentifier("home.shareAudioButton")

            Button {
                exportAndShareTranscript(entry: entry)
            } label: {
                Label("テキストを共有", systemImage: "doc.text")
            }
            .accessibilityIdentifier("home.shareTranscriptButton")
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityIdentifier("home.shareButton")
    }

    // MARK: - Export

    private func exportAndShareAudio(entry: JournalEntry) {
        Task {
            do {
                let url = try await viewModel.exportForSharing(entry: entry)
                shareItems = [url]
            } catch {
                // Handle error silently for now
            }
        }
    }

    private func exportAndShareTranscript(entry: JournalEntry) {
        do {
            let text = try viewModel.exportTranscriptForSharing(entry: entry)
            shareItems = [text]
        } catch {
            // Handle error silently for now
        }
    }

    // MARK: - Formatting

    private func dateTag(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
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
