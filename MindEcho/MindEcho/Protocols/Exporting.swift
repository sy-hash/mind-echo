import Foundation

protocol Exporting {
    func exportTextJournal(entry: JournalEntry, to directory: URL) async throws -> URL
    func exportMergedAudio(entry: JournalEntry, to directory: URL) async throws -> URL
}
