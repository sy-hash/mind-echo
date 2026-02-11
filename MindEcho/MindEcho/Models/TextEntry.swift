import Foundation
import SwiftData

@Model
class TextEntry {
    var id: UUID
    var sequenceNumber: Int
    var content: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \JournalEntry.textEntries)
    var entry: JournalEntry?

    init(id: UUID = UUID(), sequenceNumber: Int = 1, content: String,
         createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.sequenceNumber = sequenceNumber
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
