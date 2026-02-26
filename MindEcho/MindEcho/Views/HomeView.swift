import MindEchoAudio
import MindEchoCore
import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var transcriptionTargetRecording: Recording?
    @State private var isRecordingModalPresented = false
    @State private var shareItems: [Any]?

    init(modelContext: ModelContext, audioRecorder: any AudioRecording) {
        _viewModel = State(initialValue: HomeViewModel(
            modelContext: modelContext,
            audioRecorder: audioRecorder
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                // Today section (always shown)
                Section {
                    if let entry = viewModel.todayEntry {
                        ForEach(entry.sortedRecordings) { recording in
                            recordingRow(recording, entry: entry)
                        }
                    }
                } header: {
                    sectionHeader(
                        title: "今日",
                        subtitle: DateHelper.displayString(for: DateHelper.today()),
                        entry: viewModel.todayEntry
                    )
                }
                .accessibilityIdentifier("home.todaySection")

                // Past entries sections
                let pastEntries = viewModel.allEntries.filter { $0.date != DateHelper.today() }
                ForEach(pastEntries) { entry in
                    Section {
                        ForEach(entry.sortedRecordings) { recording in
                            recordingRow(recording, entry: entry)
                        }
                    } header: {
                        sectionHeader(
                            title: viewModel.sectionTitle(for: entry),
                            subtitle: nil,
                            entry: entry
                        )
                    }
                }
            }
            .listStyle(.grouped)
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

    // MARK: - Section Header

    @ViewBuilder
    private func sectionHeader(title: String, subtitle: String?, entry: JournalEntry?) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let entry, !entry.recordings.isEmpty {
                shareMenu(for: entry)
            }
        }
        .accessibilityIdentifier("home.dateLabel")
    }

    // MARK: - Share Menu

    @ViewBuilder
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
                .font(.subheadline)
        }
        .accessibilityIdentifier("home.shareButton")
    }

    // MARK: - Recording Row

    @ViewBuilder
    private func recordingRow(_ recording: Recording, entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("#\(recording.sequenceNumber)")
                    .font(.headline)
                Text(formatTime(recording.recordedAt))
                    .foregroundStyle(.secondary)
                Text(formatDuration(recording.duration))
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    transcriptionTargetRecording = recording
                } label: {
                    Image(systemName: recording.hasTranscription ? "doc.text.fill" : "doc.text")
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("home.transcribeButton.\(recording.sequenceNumber)")
                Image(systemName: viewModel.playingRecordingId == recording.id && viewModel.isPlaying ? "pause.fill" : "play.fill")
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if viewModel.playingRecordingId == recording.id && viewModel.isPlaying {
                    viewModel.pausePlayback()
                } else {
                    viewModel.playRecording(recording)
                }
            }

            if let transcription = recording.transcription {
                Text(transcription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .accessibilityIdentifier("home.transcription.\(recording.sequenceNumber)")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                viewModel.deleteRecording(recording, from: entry)
            } label: {
                Label("削除", systemImage: "trash")
            }
            .accessibilityIdentifier("home.deleteButton.\(recording.sequenceNumber)")
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("home.recordingRow.\(recording.sequenceNumber)")
    }

    // MARK: - Export helpers

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

    // MARK: - Formatters

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

// MARK: - UIKit ShareSheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context: Context) {}
}
