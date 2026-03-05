import Foundation
import MindEchoAudio
import MindEchoCore
import Observation
import SwiftData

@Observable
class HomeViewModel {
    enum TranscriptionState: Equatable {
        case idle
        case loading
        case success(String)
        case failure(String)
    }

    typealias SummaryState = TranscriptionViewModel.SummaryState

    /// Represents a single calendar day in the past section, with an optional entry.
    struct DateRow: Identifiable {
        let date: Date
        let entry: JournalEntry?
        var id: Date { date }
    }

    var recordingDuration: TimeInterval = 0
    var playingRecordingId: UUID?
    var isPlaying = false
    var playbackProgress: Double = 0
    var todayEntry: JournalEntry?
    var pastRows: [DateRow] = []
    var errorMessage: String?
    private(set) var transcriptionState: TranscriptionState = .idle
    private(set) var summaryState: SummaryState = .idle
    var recordingTargetDate: Date?
    private(set) var liveTranscriptionText: String = ""
    private(set) var liveTranscriptionError: String?

    @ObservationIgnored
    var transcribe: (URL, Locale) async throws -> String = { url, locale in
        try await TranscriptionService().transcribe(audioFileURL: url, locale: locale)
    }
    @ObservationIgnored
    var summarize: (String) async throws -> String = SummarizationService().summarize
    @ObservationIgnored
    var isSummarizationAvailable: () -> Bool = { SummarizationService.isAvailable }

    private let modelContext: ModelContext
    private var audioRecorder: any AudioRecording
    private var audioPlayer: any AudioPlaying
    private let exportService: any Exporting
    private let liveTranscriber: (any LiveTranscribing)?
    private var durationTimer: Timer?
    private var recordingStartTime: Date?
    private var accumulatedDuration: TimeInterval = 0
    private var currentRecordingFileName: String?
    private var currentRecordingStartedAt: Date?
    private var lastRecordedFileName: String?
    private var lastRecordedRecording: Recording?
    private var liveTranscriptionTask: Task<Void, Never>?

    var hasLiveTranscription: Bool { liveTranscriber != nil }

    init(
        modelContext: ModelContext,
        audioRecorder: any AudioRecording,
        audioPlayer: any AudioPlaying = AudioPlayerService(),
        exportService: any Exporting = ExportServiceImpl(),
        liveTranscriber: (any LiveTranscribing)? = nil
    ) {
        self.modelContext = modelContext
        self.audioRecorder = audioRecorder
        self.audioPlayer = audioPlayer
        self.exportService = exportService
        self.liveTranscriber = liveTranscriber
        self.audioPlayer.onPlaybackFinished = { [weak self] in
            self?.isPlaying = false
            self?.playingRecordingId = nil
            self?.playbackProgress = 0
        }
    }

    // MARK: - Computed (forwarding from recorder)

    var isRecording: Bool { audioRecorder.isRecording }
    var isRecordingPaused: Bool { audioRecorder.isPaused }
    var audioLevels: [Float] { audioRecorder.audioLevels }

    // MARK: - Recording

    func startRecording() {
        transcriptionState = .idle
        lastRecordedFileName = nil
        lastRecordedRecording = nil
        liveTranscriptionText = ""
        liveTranscriptionError = nil
        do {
            try FilePathManager.ensureDirectoryExists(FilePathManager.recordingsDirectory)
            let url = FilePathManager.newRecordingURL()
            currentRecordingFileName = url.lastPathComponent
            currentRecordingStartedAt = Date()
            // Set up live transcription BEFORE starting recorder to avoid
            // missing initial audio buffers.
            startLiveTranscription()
            try audioRecorder.startRecording(to: url)
            recordingDuration = 0
            accumulatedDuration = 0
            recordingStartTime = Date()
            startDurationTimer()
        } catch {
            currentRecordingFileName = nil
            currentRecordingStartedAt = nil
            stopLiveTranscription()
            errorMessage = "録音の開始に失敗しました: \(error.localizedDescription)"
        }
    }

    func pauseRecording() {
        if let start = recordingStartTime {
            accumulatedDuration += Date().timeIntervalSince(start)
        }
        recordingStartTime = nil
        audioRecorder.pauseRecording()
        stopDurationTimer()
    }

    func resumeRecording() {
        audioRecorder.resumeRecording()
        recordingStartTime = Date()
        startDurationTimer()
    }

    func stopRecording() {
        stopLiveTranscription()
        if let start = recordingStartTime {
            accumulatedDuration += Date().timeIntervalSince(start)
        }
        let finalDuration = accumulatedDuration
        stopDurationTimer()
        audioRecorder.stopRecording()

        // Save recording to SwiftData
        guard let fileName = currentRecordingFileName else { return }
        lastRecordedFileName = fileName
        let targetDate = recordingTargetDate ?? DateHelper.logicalDate()
        let entry = getOrCreateEntry(for: targetDate)
        let nextSeq = (entry.recordings.map(\.sequenceNumber).max() ?? 0) + 1

        let recording = Recording(
            sequenceNumber: nextSeq,
            audioFileName: fileName,
            duration: finalDuration,
            recordedAt: currentRecordingStartedAt ?? Date()
        )
        modelContext.insert(recording)
        entry.recordings.append(recording)
        entry.updatedAt = Date()
        if targetDate == DateHelper.logicalDate() {
            todayEntry = entry
        }
        lastRecordedRecording = recording

        currentRecordingFileName = nil
        currentRecordingStartedAt = nil
        recordingDuration = 0
        accumulatedDuration = 0
        recordingStartTime = nil
        recordingTargetDate = nil
    }

    // MARK: - Transcription

    func startTranscription() async {
        guard let fileName = lastRecordedFileName,
              let recording = lastRecordedRecording else { return }
        let url = FilePathManager.recordingsDirectory.appendingPathComponent(fileName)
        transcriptionState = .loading
        do {
            let text = try await transcribe(url, Locale(identifier: "ja-JP"))
            if text.isEmpty {
                transcriptionState = .failure("書き起こし結果が空でした。")
            } else {
                recording.transcription = text
                transcriptionState = .success(text)
                await startSummarization(recording: recording, text: text)
            }
        } catch {
            transcriptionState = .failure("書き起こしに失敗しました: \(error.localizedDescription)")
        }
    }

    func resetTranscriptionState() {
        transcriptionState = .idle
        summaryState = .idle
        lastRecordedFileName = nil
        lastRecordedRecording = nil
    }

    // MARK: - Summarization

    private func startSummarization(recording: Recording, text: String) async {
        if let existing = recording.summary {
            summaryState = .success(existing)
            return
        }
        guard isSummarizationAvailable() else {
            summaryState = .unavailable
            return
        }
        summaryState = .loading
        do {
            let summary = try await summarize(text)
            if summary.isEmpty {
                summaryState = .failure("要約結果が空でした。")
            } else {
                recording.summary = summary
                summaryState = .success(summary)
            }
        } catch {
            summaryState = .failure("要約に失敗しました: \(error.localizedDescription)")
        }
    }

    // MARK: - Playback

    func playRecording(_ recording: Recording) {
        do {
            let url = FilePathManager.recordingsDirectory
                .appendingPathComponent(recording.audioFileName)
            try audioPlayer.play(url: url)
            playingRecordingId = recording.id
            isPlaying = true
        } catch {
            errorMessage = "再生に失敗しました: \(error.localizedDescription)"
        }
    }

    func pausePlayback() {
        audioPlayer.pause()
        isPlaying = false
    }

    func stopPlayback() {
        audioPlayer.stop()
        isPlaying = false
        playingRecordingId = nil
        playbackProgress = 0
    }

    // MARK: - Data

    func fetchTodayEntry() {
        let today = DateHelper.logicalDate()
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.date == today }
        )
        todayEntry = try? modelContext.fetch(descriptor).first
    }

    func fetchAllEntries() {
        let today = DateHelper.logicalDate()
        fetchTodayEntry()
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        let past = all.filter { $0.date != today }

        guard let oldestDate = past.last?.date else {
            pastRows = []
            return
        }

        let cal = Calendar.current
        let yesterday = cal.date(byAdding: .day, value: -1, to: today) ?? today
        let allDates = DateHelper.logicalDateRange(from: oldestDate, to: yesterday)
        let entryByDate = Dictionary(past.map { ($0.date, $0) }, uniquingKeysWith: { first, _ in first })
        pastRows = allDates.map { DateRow(date: $0, entry: entryByDate[$0]) }
    }

    // MARK: - Recording management

    func deleteRecording(_ recording: Recording, from entry: JournalEntry) {
        let url = FilePathManager.recordingsDirectory
            .appendingPathComponent(recording.audioFileName)
        try? FileManager.default.removeItem(at: url)
        entry.recordings.removeAll { $0.id == recording.id }
        entry.updatedAt = Date()

        if entry.recordings.isEmpty {
            // Delete associated audio files and the entry itself
            modelContext.delete(entry)
            fetchAllEntries()
        }
    }

    func exportForSharing(entry: JournalEntry) async throws -> URL {
        let exportDir = FilePathManager.exportsDirectory
        return try await exportService.exportMergedAudio(entry: entry, to: exportDir)
    }

    func exportTranscriptForSharing(entry: JournalEntry) throws -> String {
        let exportDir = FilePathManager.exportsDirectory
        let url = try exportService.exportCombinedTranscript(entry: entry, to: exportDir)
        return try String(contentsOf: url, encoding: .utf8)
    }

    // MARK: - Private

    private func getOrCreateEntry(for logicalDate: Date) -> JournalEntry {
        if let existing = todayEntry, existing.date == logicalDate {
            return existing
        }
        if let existing = pastRows.first(where: { $0.date == logicalDate })?.entry {
            return existing
        }
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.date == logicalDate }
        )
        if let found = try? modelContext.fetch(descriptor).first {
            return found
        }
        let newEntry = JournalEntry(date: logicalDate)
        modelContext.insert(newEntry)
        return newEntry
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self, let start = self.recordingStartTime else { return }
            self.recordingDuration = self.accumulatedDuration + Date().timeIntervalSince(start)
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }

    // MARK: - Live Transcription

    private func startLiveTranscription() {
        guard let liveTranscriber else { return }

        // Bridge audio buffers from recorder to live transcription service
        audioRecorder.onAudioBuffer = { buffer, format in
            liveTranscriber.feedAudioBuffer(buffer, format: format)
        }

        let stream = liveTranscriber.start(locale: Locale(identifier: "ja-JP"))
        liveTranscriptionTask = Task { @MainActor [weak self] in
            do {
                for try await text in stream {
                    self?.liveTranscriptionText = text
                }
            } catch is CancellationError {
                // ユーザーによる停止操作に伴うキャンセルはエラーとして扱わない
            } catch {
                self?.liveTranscriptionError = "書き起こしに失敗しました: \(error.localizedDescription)"
            }
        }
    }

    private func stopLiveTranscription() {
        liveTranscriptionTask?.cancel()
        liveTranscriptionTask = nil
        audioRecorder.onAudioBuffer = nil
        liveTranscriber?.stop()
    }
}
