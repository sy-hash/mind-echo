import Foundation
import SwiftData

@Model
class Recording {
    var id: UUID
    var sequenceNumber: Int
    var audioFileName: String
    var duration: TimeInterval
    var recordedAt: Date

    @Relationship(inverse: \JournalEntry.recordings)
    var entry: JournalEntry?

    init(id: UUID = UUID(), sequenceNumber: Int, audioFileName: String,
         duration: TimeInterval, recordedAt: Date = Date()) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.audioFileName = audioFileName
        self.duration = duration
        self.recordedAt = recordedAt
    }
}
