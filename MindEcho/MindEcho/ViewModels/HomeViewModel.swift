import Foundation
import MindEchoAudio
import MindEchoCore
import Observation
import SwiftData

@Observable
class HomeViewModel {
    var recordingDuration: TimeInterval = 0
    var playingRecordingId: UUID?
    var isPlaying = false
    var playbackProgress: Double = 0
    var todayEntry: JournalEntry?
    var errorMessage: String?

    // MARK: - Transcription

    var transcriptionTargetRecording: Recording?
    var transcriptionState: TranscriptionState = .idle
    var showTranscriptionSheet = false

    private let modelContext: ModelContext
    private var audioRecorder: any AudioRecording
    private var audioPlayer: any AudioPlaying
    private var durationTimer: Timer?
    private var recordingStartTime: Date?
    private var accumulatedDuration: TimeInterval = 0
    private var currentRecordingFileName: String?
    private var currentRecordingStartedAt: Date?

    init(
        modelContext: ModelContext,
        audioRecorder: any AudioRecording,
        audioPlayer: any AudioPlaying = AudioPlayerService()
    ) {
        self.modelContext = modelContext
        self.audioRecorder = audioRecorder
        self.audioPlayer = audioPlayer
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
        todayEntry = entry

        currentRecordingFileName = nil
        currentRecordingStartedAt = nil
        recordingDuration = 0
        accumulatedDuration = 0
        recordingStartTime = nil
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

    // MARK: - Text

    func saveText(_ text: String) {
        let today = DateHelper.logicalDate()
        let entry = getOrCreateTodayEntry(for: today)

        if let existing = entry.sortedTextEntries.first {
            existing.content = text
            existing.updatedAt = Date()
        } else {
            let textEntry = TextEntry(sequenceNumber: 1, content: text)
            entry.textEntries.append(textEntry)
        }
        entry.updatedAt = Date()
        todayEntry = entry
    }

    // MARK: - Data

    func fetchTodayEntry() {
        let today = DateHelper.logicalDate()
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.date == today }
        )
        todayEntry = try? modelContext.fetch(descriptor).first
    }

    // MARK: - Transcription

    func startTranscription(for recording: Recording) {
        transcriptionTargetRecording = recording
        transcriptionState = .loading
        showTranscriptionSheet = true

        let audioURL = FilePathManager.recordingsDirectory
            .appendingPathComponent(recording.audioFileName)
        let service = TranscriptionService()

        Task { @MainActor in
            do {
                let text = try await service.transcribe(audioURL: audioURL)
                transcriptionState = .success(text.isEmpty ? "(書き起こし結果がありませんでした)" : text)
            } catch {
                transcriptionState = .failure(error.localizedDescription)
            }
        }
    }

    func dismissTranscription() {
        showTranscriptionSheet = false
        transcriptionTargetRecording = nil
        transcriptionState = .idle
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
