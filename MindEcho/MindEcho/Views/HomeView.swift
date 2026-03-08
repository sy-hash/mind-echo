import MindEchoAudio
import MindEchoCore
import SwiftData
import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var transcriptionTargetRecording: Recording?
    @State private var isRecordingModalPresented = false
    @State private var shareItems: [Any]?
    @State private var vocabularyStore = VocabularyStore()
    @State private var transcriberPreference = TranscriberPreference()
    @State private var openAIAPIKeyStore = OpenAIAPIKeyStore()
    @State private var showVocabulary = false
    @State private var showSettings = false

    init(
        modelContext: ModelContext,
        audioRecorder: any AudioRecording,
        audioPlayer: any AudioPlaying = AudioPlayerService(),
        liveTranscriber: (any LiveTranscribing)? = nil
    ) {
        _viewModel = State(initialValue: HomeViewModel(
            modelContext: modelContext,
            audioRecorder: audioRecorder,
            audioPlayer: audioPlayer,
            liveTranscriber: liveTranscriber
        ))
    }

    var body: some View {
        NavigationStack {
            List {
                // Today's section
                todaySection

                // Past entries sections
                ForEach(viewModel.pastRows) { row in
                    pastSection(row)
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
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityIdentifier("home.settingsButton")
                        .accessibilityLabel("設定")

                        Button {
                            showVocabulary = true
                        } label: {
                            Image(systemName: "character.book.closed")
                        }
                        .accessibilityIdentifier("home.vocabularyButton")
                        .accessibilityLabel("語彙")
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
                viewModel.vocabularyWords = vocabularyStore.words
                viewModel.liveTranscriberType = transcriberPreference.liveType
                viewModel.postRecordingTranscriberType = transcriberPreference.postRecordingType
                viewModel.openAIAPIKey = openAIAPIKeyStore.apiKey
                viewModel.fetchAllEntries()
            }
            .onChange(of: vocabularyStore.words) { _, newWords in
                viewModel.vocabularyWords = newWords
            }
            .onChange(of: transcriberPreference.liveType) { _, newType in
                viewModel.liveTranscriberType = newType
            }
            .onChange(of: transcriberPreference.postRecordingType) { _, newType in
                viewModel.postRecordingTranscriberType = newType
            }
            .onChange(of: openAIAPIKeyStore.apiKey) { _, newKey in
                viewModel.openAIAPIKey = newKey
            }
            .sheet(isPresented: $showVocabulary) {
                VocabularyView(store: vocabularyStore)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(transcriberPreference: transcriberPreference, openAIAPIKeyStore: openAIAPIKeyStore)
            }
            .sheet(isPresented: $isRecordingModalPresented, onDismiss: {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                }
                viewModel.recordingTargetDate = nil
                viewModel.resetTranscriptionState()
                viewModel.fetchAllEntries()
            }) {
                RecordingModalView(viewModel: viewModel)
            }
            .sheet(item: $transcriptionTargetRecording) { recording in
                TranscriptionView(recording: recording, vocabularyWords: vocabularyStore.words, transcriberType: transcriberPreference.postRecordingType, openAIAPIKey: openAIAPIKeyStore.apiKey)
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
            HStack {
                Text(DateHelper.displayString(for: DateHelper.today()))
                    .accessibilityIdentifier("home.dateLabel")
                Spacer()
                addMenu(for: DateHelper.today(), prefix: "home")
                if let entry = viewModel.todayEntry, !entry.recordings.isEmpty {
                    shareMenu(for: entry, prefix: "home")
                }
            }
        }
    }

    // MARK: - Past Section

    @ViewBuilder
    private func pastSection(_ row: HomeViewModel.DateRow) -> some View {
        Section {
            if let entry = row.entry, !entry.recordings.isEmpty {
                ForEach(entry.sortedRecordings) { recording in
                    recordingRow(recording, isToday: false, entry: entry)
                }
            } else {
                Text("録音がありません")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("past.emptyState.\(dateTag(row.date))")
            }
        } header: {
            HStack {
                Text(DateHelper.displayString(for: row.date))
                    .accessibilityIdentifier("home.sectionHeader.\(dateTag(row.date))")
                Spacer()
                addMenu(for: row.date, prefix: "past", dateTag: dateTag(row.date))
                if let entry = row.entry, !entry.recordings.isEmpty {
                    shareMenu(for: entry, prefix: "past", dateTag: dateTag(row.date))
                }
            }
        }
    }

    // MARK: - Recording Row

    @ViewBuilder
    private func recordingRow(_ recording: Recording, isToday: Bool, entry: JournalEntry? = nil) -> some View {
        let prefix = isToday ? "home" : "past"
        let suffix = isToday
            ? "\(recording.sequenceNumber)"
            : "\(dateTag(entry!.date)).\(recording.sequenceNumber)"
        let isCurrentlyPlaying = viewModel.playingRecordingId == recording.id && viewModel.isPlaying

        HStack(alignment: .center, spacing: 4) {
            // Main content area — tap navigates to TranscriptionView
            Button {
                transcriptionTargetRecording = recording
            } label: {
                recordingRowContent(
                    recording: recording, isToday: isToday, entry: entry)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("\(prefix).recordingRow.\(suffix)")

            // Play / Pause button (distinct id for reliable XCTest detection)
            if isCurrentlyPlaying {
                Button {
                    viewModel.pausePlayback()
                } label: {
                    Image(systemName: "pause.fill")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(prefix).pauseButton.\(suffix)")
                .id("\(prefix).pauseButton.\(suffix)")
            } else {
                Button {
                    viewModel.playRecording(recording)
                } label: {
                    Image(systemName: "play.fill")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("\(prefix).playButton.\(suffix)")
                .id("\(prefix).playButton.\(suffix)")
            }

            // Menu button with delete option
            Menu {
                if let targetEntry = isToday ? viewModel.todayEntry : entry {
                    Button(role: .destructive) {
                        viewModel.deleteRecording(recording, from: targetEntry)
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                    .accessibilityIdentifier("\(prefix).deleteMenuItem.\(suffix)")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier("\(prefix).moreButton.\(suffix)")
        }
    }

    @ViewBuilder
    private func recordingRowContent(
        recording: Recording, isToday: Bool, entry: JournalEntry?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(formatTime(recording.recordedAt))
                    .font(.headline)
                Text(formatDuration(recording.duration))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            if let summary = recording.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier(
                        isToday
                            ? "home.summary.\(recording.sequenceNumber)"
                            : "past.summary.\(dateTag(entry!.date)).\(recording.sequenceNumber)"
                    )
            } else if let transcription = recording.transcription {
                Text(transcription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier(
                        isToday
                            ? "home.transcription.\(recording.sequenceNumber)"
                            : "past.transcription.\(dateTag(entry!.date)).\(recording.sequenceNumber)"
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Add Menu

    private func addMenu(for date: Date, prefix: String, dateTag: String? = nil) -> some View {
        let suffix = dateTag.map { ".\($0)" } ?? ""
        return Menu {
            Button {
                viewModel.recordingTargetDate = date
                isRecordingModalPresented = true
            } label: {
                Label("音声を録音", systemImage: "mic")
            }
            .accessibilityIdentifier("\(prefix).recordMenuItem\(suffix)")
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityIdentifier("\(prefix).addButton\(suffix)")
    }

    // MARK: - Share Menu

    private func shareMenu(for entry: JournalEntry, prefix: String, dateTag: String? = nil) -> some View {
        let suffix = dateTag.map { ".\($0)" } ?? ""
        return Menu {
            Button {
                exportAndShareAudio(entry: entry)
            } label: {
                Label("音声を共有", systemImage: "waveform")
            }
            .accessibilityIdentifier("\(prefix).shareAudioButton\(suffix)")

            Button {
                exportAndShareTranscript(entry: entry)
            } label: {
                Label("テキストを共有", systemImage: "doc.text")
            }
            .accessibilityIdentifier("\(prefix).shareTranscriptButton\(suffix)")

            Button {
                exportAndSharePDF(entry: entry)
            } label: {
                Label("PDFで共有", systemImage: "doc.richtext")
            }
            .accessibilityIdentifier("\(prefix).sharePDFButton\(suffix)")
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityIdentifier("\(prefix).shareButton\(suffix)")
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

    private func exportAndSharePDF(entry: JournalEntry) {
        Task { @MainActor in
            do {
                let url = try viewModel.exportTranscriptPDFForSharing(entry: entry)
                shareItems = [url]
            } catch {
                // Handle error silently for now
            }
        }
    }

    private func exportAndShareTranscript(entry: JournalEntry) {
        Task { @MainActor in
            do {
                let text = try viewModel.exportTranscriptForSharing(entry: entry)
                shareItems = [text]
            } catch {
                // Handle error silently for now
            }
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
