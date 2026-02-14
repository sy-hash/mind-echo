import Foundation
import MindEchoCore
import Observation
import SwiftData

@Observable
class HistoryViewModel {
    var entries: [JournalEntry] = []

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchEntries() {
        let descriptor = FetchDescriptor<JournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        entries = (try? modelContext.fetch(descriptor)) ?? []
    }

    func deleteEntry(_ entry: JournalEntry) {
        // Delete associated audio files from disk
        for recording in entry.recordings {
            let url = FilePathManager.recordingsDirectory
                .appendingPathComponent(recording.audioFileName)
            try? FileManager.default.removeItem(at: url)
        }
        modelContext.delete(entry)
        fetchEntries()
    }
}
