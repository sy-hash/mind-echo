import Foundation
import SwiftData

@Model
class JournalEntry {
    var id: UUID
    var date: Date  // Logical date normalized to noon (12:00) local time
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade)
    var recordings: [Recording]
    @Relationship(deleteRule: .cascade)
    var textEntries: [TextEntry]

    var sortedRecordings: [Recording] {
        recordings.sorted { $0.sequenceNumber < $1.sequenceNumber }
    }

    var sortedTextEntries: [TextEntry] {
        textEntries.sorted { $0.sequenceNumber < $1.sequenceNumber }
    }

    var totalDuration: TimeInterval {
        recordings.reduce(0) { $0 + $1.duration }
    }

    init(id: UUID = UUID(), date: Date, createdAt: Date = Date(), updatedAt: Date = Date(),
         recordings: [Recording] = [], textEntries: [TextEntry] = []) {
        self.id = id
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.recordings = recordings
        self.textEntries = textEntries
    }
}
