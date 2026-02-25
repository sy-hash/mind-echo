import Foundation
import SwiftData

@Model
public class Recording {
    public var id: UUID
    public var sequenceNumber: Int
    public var audioFileName: String
    public var duration: TimeInterval
    public var recordedAt: Date
    public var transcription: String?
    public var summary: String?

    @Relationship(inverse: \JournalEntry.recordings)
    public var entry: JournalEntry?

    public var hasTranscription: Bool {
        transcription != nil
    }

    public var hasSummary: Bool {
        summary != nil
    }

    public init(id: UUID = UUID(), sequenceNumber: Int, audioFileName: String,
         duration: TimeInterval, recordedAt: Date = Date(), transcription: String? = nil,
         summary: String? = nil) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.audioFileName = audioFileName
        self.duration = duration
        self.recordedAt = recordedAt
        self.transcription = transcription
        self.summary = summary
    }
}
