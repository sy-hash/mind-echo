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

    var recordingDuration: TimeInterval = 0
    var playingRecordingId: UUID?
    var isPlaying = false
    var playbackProgress: Double = 0
    var allEntries: [JournalEntry] = []
    var errorMessage: String?
    private(set) var transcriptionState: TranscriptionState = .idle

    @ObservationIgnored
    var transcribe: (URL, Locale) async throws -> String = { url, locale in
        try await TranscriptionService().transcribe(audioFileURL: url, locale: locale)
    }

    private let modelContext: ModelContext
    private var audioRecorder: any AudioRecording
    private var audioPlayer: any AudioPlaying
    private let exportService: any Exporting
    private var durationTimer: Timer?
    private var recordingStartTime: Date?
    private var accumulatedDuration: TimeInterval = 0
    private var currentRecordingFileName: String?
    private var currentRecordingStartedAt: Date?
    private var lastRecordedFileName: String?
    private var lastRecordedRecording: Recording?

    init(
        modelContext: ModelContext,
        audioRecorder: any AudioRecording,
        audioPlayer: any AudioPlaying = AudioPlayerService(),
        exportService: any Exporting = ExportServiceImpl()
    ) {
        self.modelContext = modelContext
        self.audioRecorder = audioRecorder
        self.audioPlayer = audioPlayer
        self.exportService = exportService
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

    var todayEntry: JournalEntry? {
        let today = DateHelper.today()
        return allEntries.first { $0.date == today }
    }

    // MARK: - Section helpers

    func sectionTitle(for entry: JournalEntry) -> String {
        let today = DateHelper.today()
        let cal = Calendar.current
        if entry.date == today {
            return "今日"
        }
        if let yesterdayRef = cal.date(byAdding: .day, value: -1, to: Date()) {
            let yesterday = DateHelper.logicalDate(for: yesterdayRef)
            if entry.date == yesterday {
                return "昨日"
            }
        }
        return DateHelper.displayString(for: entry.date)
    }

    // MARK: - Recording

    func startRecording() {
        transcriptionState = .idle
        lastRecordedFileName = nil
        lastRecordedRecording = nil
        do {
            try FilePathManager.ensureDirectoryExists(FilePathManager.recordingsDirectory)
            let url = FilePathManager.newRecordingURL()
            currentRecordingFileName = url.lastPathComponent
            currentRecordingStartedAt = Date()
            try audioRecorder.startRecording(to: url)
            recordingDuration = 0
            accumulatedDuration = 0
            recordingStartTime = Date()
            startDurationTimer()
        } catch {
            currentRecordingFileName = nil
            currentRecordingStartedAt = nil
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
        if let start = recordingStartTime {
            accumulatedDuration += Date().timeIntervalSince(start)
        }
        let finalDuration = accumulatedDuration
        stopDurationTimer()
        audioRecorder.stopRecording()

        // Save recording to SwiftData
        guard let fileName = currentRecordingFileName else { return }
        lastRecordedFileName = fileName
        let today = DateHelper.logicalDate()
        let entry = getOrCreateTodayEntry(for: today)
        let nextSeq = (entry.recordings.map(\.sequenceNumber).max() ?? 0) + 1

        let recording = Recording(
            sequenceNumber: nextSeq,
            audioFileName: fileName,
            duration: finalDuration,
            recordedAt: currentRecordingStartedAt ?? Date()
        )
        entry.recordings.append(recording)
        entry.updatedAt = Date()
        lastRecordedRecording = recording

        currentRecordingFileName = nil
        currentRecordingStartedAt = nil
        recordingDuration = 0
        accumulatedDuration = 0
        recordingStartTime = nil

        fetchAllEntries()
    }

    // MARK: - Transcription

    func startTranscription() async {
        guard let fileName = lastRecordedFileName else { return }
        let url = FilePathManager.recordingsDirectory.appendingPathComponent(fileName)
        transcriptionState = .loading
        do {
            let text = try await transcribe(url, Locale(identifier: "ja-JP"))
            if text.isEmpty {
                transcriptionState = .failure("書き起こし結果が空でした。")
            } else {
                lastRecordedRecording?.transcription = text
                transcriptionState = .success(text)
            }
        } catch {
            transcriptionState = .failure("書き起こしに失敗しました: \(error.localizedDescription)")
        }
    }

    func resetTranscriptionState() {
        transcriptionState = .idle
        lastRecordedFileName = nil
        lastRecordedRecording = nil
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

    // MARK: - Delete

    func deleteEntry(_ entry: JournalEntry) {
        for recording in entry.recordings {
            let url = FilePathManager.recordingsDirectory
                .appendingPathComponent(recording.audioFileName)
            try? FileManager.default.removeItem(at: url)
        }
        modelContext.delete(entry)
        fetchAllEntries()
    }

    func deleteRecording(_ recording: Recording, from entry: JournalEntry) {
        let url = FilePathManager.recordingsDirectory
            .appendingPathComponent(recording.audioFileName)
        try? FileManager.default.removeItem(at: url)
        entry.recordings.removeAll { $0.id == recording.id }
        entry.updatedAt = Date()
        if entry.recordings.isEmpty {
            modelContext.delete(entry)
        }
        fetchAllEntries()
    }

    // MARK: - Export

    func exportForSharing(entry: JournalEntry) async throws -> URL {
        let exportDir = FilePathManager.exportsDirectory
        return try await exportService.exportMergedAudio(entry: entry, to: exportDir)
    }

    func exportTranscriptForSharing(entry: JournalEntry) throws -> String {
        let exportDir = FilePathManager.exportsDirectory
        let url = try exportService.exportCombinedTranscript(entry: entry, to: exportDir)
        return try String(contentsOf: url, encoding: .utf8)
    }

    enum ExportError: Error {
        case noEntry
    }

    // MARK: - Data

    func fetchAllEntries() {
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        allEntries = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Private

    private func getOrCreateTodayEntry(for logicalDate: Date) -> JournalEntry {
        if let existing = todayEntry, existing.date == logicalDate {
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
}
