import Foundation
import SwiftData

@Model
public class Recording {
    public var id: UUID
    public var sequenceNumber: Int
    public var audioFileName: String
    public var duration: TimeInterval
    public var recordedAt: Date

    @Relationship(inverse: \JournalEntry.recordings)
    public var entry: JournalEntry?

    public init(id: UUID = UUID(), sequenceNumber: Int, audioFileName: String,
         duration: TimeInterval, recordedAt: Date = Date()) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.audioFileName = audioFileName
        self.duration = duration
        self.recordedAt = recordedAt
    }
}
