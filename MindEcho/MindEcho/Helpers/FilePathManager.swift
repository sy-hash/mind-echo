import Foundation

enum FilePathManager {
    static var recordingsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Recordings", isDirectory: true)
    }

    static var mergedDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Merged", isDirectory: true)
    }

    static var exportsDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("Exports", isDirectory: true)
    }

    /// Generates a recording file URL with timestamp-based name: YYYYMMDD_HHmmss.m4a
    static func newRecordingURL(for date: Date = Date()) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileName = formatter.string(from: date) + ".m4a"
        return recordingsDirectory.appendingPathComponent(fileName)
    }

    /// Returns the merged audio file URL for a given logical date
    static func mergedAudioURL(for logicalDate: Date) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let fileName = formatter.string(from: logicalDate) + "_merged.m4a"
        return mergedDirectory.appendingPathComponent(fileName)
    }

    /// Returns the export text journal URL for a given logical date
    static func exportTextURL(for logicalDate: Date) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let fileName = formatter.string(from: logicalDate) + "_journal.txt"
        return exportsDirectory.appendingPathComponent(fileName)
    }

    /// Returns the export merged audio URL for a given logical date
    static func exportAudioURL(for logicalDate: Date) -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        let fileName = formatter.string(from: logicalDate) + "_merged.m4a"
        return exportsDirectory.appendingPathComponent(fileName)
    }

    /// Ensures a directory exists, creating it if necessary
    static func ensureDirectoryExists(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }
}
