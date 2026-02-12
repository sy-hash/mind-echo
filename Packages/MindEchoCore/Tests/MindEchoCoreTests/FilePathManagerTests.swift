import Testing
import Foundation
@testable import MindEchoCore

@MainActor
struct FilePathManagerTests {
    @Test func recordingsDirectory_containsRecordingsPath() {
        let url = FilePathManager.recordingsDirectory
        #expect(url.lastPathComponent == "Recordings")
    }

    @Test func mergedDirectory_containsMergedPath() {
        let url = FilePathManager.mergedDirectory
        #expect(url.lastPathComponent == "Merged")
    }

    @Test func exportsDirectory_containsExportsPath() {
        let url = FilePathManager.exportsDirectory
        #expect(url.lastPathComponent == "Exports")
    }

    @Test func newRecordingURL_hasCorrectFormat() {
        let date: Date = {
            var components = DateComponents()
            components.year = 2025
            components.month = 2
            components.day = 7
            components.hour = 14
            components.minute = 30
            components.second = 0
            components.timeZone = TimeZone.current
            return Calendar.current.date(from: components)!
        }()
        let url = FilePathManager.newRecordingURL(for: date)
        #expect(url.lastPathComponent == "20250207_143000.m4a")
        #expect(url.pathExtension == "m4a")
    }

    @Test func exportTextURL_hasCorrectFormat() {
        let date: Date = {
            var components = DateComponents()
            components.year = 2025
            components.month = 2
            components.day = 7
            components.hour = 12
            components.timeZone = TimeZone.current
            return Calendar.current.date(from: components)!
        }()
        let url = FilePathManager.exportTextURL(for: date)
        #expect(url.lastPathComponent == "20250207_journal.txt")
    }

    @Test func exportAudioURL_hasCorrectFormat() {
        let date: Date = {
            var components = DateComponents()
            components.year = 2025
            components.month = 2
            components.day = 7
            components.hour = 12
            components.timeZone = TimeZone.current
            return Calendar.current.date(from: components)!
        }()
        let url = FilePathManager.exportAudioURL(for: date)
        #expect(url.lastPathComponent == "20250207_merged.m4a")
    }
}
