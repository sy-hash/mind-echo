import Foundation
import SwiftData

@Model
public class TextEntry {
    public var id: UUID
    public var sequenceNumber: Int
    public var content: String
    public var createdAt: Date
    public var updatedAt: Date

    @Relationship(inverse: \JournalEntry.textEntries)
    public var entry: JournalEntry?

    public init(id: UUID = UUID(), sequenceNumber: Int = 1, content: String,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
