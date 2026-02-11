import AVFoundation
import Foundation

struct ExportServiceImpl: Exporting {
    func exportTextJournal(entry: JournalEntry, to directory: URL) async throws -> URL {
        try FilePathManager.ensureDirectoryExists(directory)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: entry.date)

        // Weekday for header
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale(identifier: "en_US_POSIX")
        weekdayFormatter.dateFormat = "yyyy-MM-dd (EEE)"
        let headerDate = weekdayFormatter.string(from: entry.date)

        var content = "# Journal: \(headerDate)\n\n"
        for textEntry in entry.sortedTextEntries {
            content += textEntry.content + "\n"
        }

        let outputURL = directory.appendingPathComponent("\(dateStr)_journal.txt")
        try content.write(to: outputURL, atomically: true, encoding: .utf8)
        return outputURL
    }

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
}
