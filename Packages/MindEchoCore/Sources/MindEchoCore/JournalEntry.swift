import Foundation
import SwiftData

@Model
public class JournalEntry {
    public var id: UUID
    public var date: Date  // Logical date normalized to noon (12:00) local time
    public var createdAt: Date
    public var updatedAt: Date
    @Relationship(deleteRule: .cascade)
    public var recordings: [Recording]

    public var sortedRecordings: [Recording] {
        recordings.sorted { $0.sequenceNumber < $1.sequenceNumber }
    }

    public var totalDuration: TimeInterval {
        recordings.reduce(0) { $0 + $1.duration }
    }

    public init(id: UUID = UUID(), date: Date, createdAt: Date = Date(), updatedAt: Date = Date(),
         recordings: [Recording] = []) {
        self.id = id
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.recordings = recordings
    }
}
