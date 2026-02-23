import Foundation
import MindEchoAudio
import MindEchoCore
import Observation
import SwiftData

@Observable
class EntryDetailViewModel {
    var entry: JournalEntry
    var isEditing = false
    var playingRecordingId: UUID?
    var isPlaying = false
    var playbackProgress: Double = 0

    private let modelContext: ModelContext
    private var audioPlayer: any AudioPlaying
    private let exportService: any Exporting

    init(
        entry: JournalEntry,
        modelContext: ModelContext,
        audioPlayer: any AudioPlaying = AudioPlayerService(),
        exportService: any Exporting = ExportServiceImpl()
    ) {
        self.entry = entry
        self.modelContext = modelContext
        self.audioPlayer = audioPlayer
        self.exportService = exportService
        self.audioPlayer.onPlaybackFinished = { [weak self] in
            self?.isPlaying = false
            self?.playingRecordingId = nil
            self?.playbackProgress = 0
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
            // Handle error silently for now
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

    // MARK: - Recording management

    func deleteRecording(_ recording: Recording) {
        let url = FilePathManager.recordingsDirectory
            .appendingPathComponent(recording.audioFileName)
        try? FileManager.default.removeItem(at: url)
        entry.recordings.removeAll { $0.id == recording.id }
        entry.updatedAt = Date()
    }

    // MARK: - Export

    func exportForSharing() async throws -> URL {
        let exportDir = FilePathManager.exportsDirectory
        return try await exportService.exportMergedAudio(entry: entry, to: exportDir)
    }
}
