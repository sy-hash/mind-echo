import AVFoundation
import Foundation
import MindEchoAudio
import MindEchoCore

struct ExportServiceImpl: Exporting {
    func exportMergedAudio(entry: JournalEntry, to directory: URL) async throws -> URL {
        try FilePathManager.ensureDirectoryExists(directory)

        // Generate TTS announcement
        let ttsBuffer = try await TTSGenerator.generateDateAnnouncement(for: entry.date)

        // Get recording file URLs in sequence order
        let recordingURLs = entry.sortedRecordings.map { recording in
            FilePathManager.recordingsDirectory.appendingPathComponent(recording.audioFileName)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: entry.date)

        // First merge to Merged directory
        let mergedURL = FilePathManager.mergedDirectory.appendingPathComponent("\(dateStr)_merged.m4a")
        _ = try await AudioMerger.merge(
            ttsBuffer: ttsBuffer,
            recordingURLs: recordingURLs,
            outputURL: mergedURL
        )

        // Copy to export directory
        let exportURL = directory.appendingPathComponent("\(dateStr)_merged.m4a")
        try? FileManager.default.removeItem(at: exportURL)
        try FileManager.default.copyItem(at: mergedURL, to: exportURL)

        return exportURL
    }

    func exportTranscription(entry: JournalEntry, to directory: URL) throws -> URL {
        try FilePathManager.ensureDirectoryExists(directory)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: entry.date)

        // Build header: "2025-02-07 Fri"
        let headerFormatter = DateFormatter()
        headerFormatter.locale = Locale(identifier: "en_US_POSIX")
        headerFormatter.dateFormat = "yyyy-MM-dd E"
        let header = headerFormatter.string(from: entry.date)

        // Combine transcriptions in sequence order
        var lines = [header, ""]
        for recording in entry.sortedRecordings {
            guard let transcription = recording.transcription else { continue }
            lines.append("#\(recording.sequenceNumber)")
            lines.append(transcription)
            lines.append("")
        }

        let content = lines.joined(separator: "\n")
        let exportURL = directory.appendingPathComponent("\(dateStr)_transcription.txt")
        try content.write(to: exportURL, atomically: true, encoding: .utf8)

        return exportURL
    }
}
