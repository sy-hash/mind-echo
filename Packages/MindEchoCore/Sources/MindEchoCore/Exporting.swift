import Foundation

public protocol Exporting {
    func exportMergedAudio(entry: JournalEntry, to directory: URL) async throws -> URL
}
