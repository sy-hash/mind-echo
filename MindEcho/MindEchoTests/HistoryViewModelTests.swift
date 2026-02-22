import Testing
import Foundation
import MindEchoCore
import SwiftData
@testable import MindEcho

@MainActor
struct HistoryViewModelTests {
    private func makeContext() throws -> (ModelContext, ModelContainer) {
        let schema = Schema([JournalEntry.self, Recording.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        return (container.mainContext, container)
    }

    @Test func fetchEntries_emptyInitially() throws {
        let (context, _container) = try makeContext()
        let vm = HistoryViewModel(modelContext: context)
        vm.fetchEntries()
        #expect(vm.entries.isEmpty)
    }

    @Test func fetchEntries_returnsInsertedEntries() throws {
        let (context, _container) = try makeContext()
        let entry = JournalEntry(date: DateHelper.logicalDate())
        context.insert(entry)
        let vm = HistoryViewModel(modelContext: context)
        vm.fetchEntries()
        #expect(vm.entries.count == 1)
    }

    @Test func fetchEntries_sortedByDateDescending() throws {
        let (context, _container) = try makeContext()
        let cal = Calendar.current
        let today = DateHelper.logicalDate()
        let yesterday = DateHelper.logicalDate(for: cal.date(byAdding: .day, value: -1, to: Date())!)
        let entry1 = JournalEntry(date: yesterday)
        let entry2 = JournalEntry(date: today)
        context.insert(entry1)
        context.insert(entry2)
        let vm = HistoryViewModel(modelContext: context)
        vm.fetchEntries()
        #expect(vm.entries.count == 2)
        #expect(vm.entries[0].date >= vm.entries[1].date)
    }

    @Test func deleteEntry_removesFromList() throws {
        let (context, _container) = try makeContext()
        let entry = JournalEntry(date: DateHelper.logicalDate())
        context.insert(entry)
        let vm = HistoryViewModel(modelContext: context)
        vm.fetchEntries()
        #expect(vm.entries.count == 1)
        vm.deleteEntry(entry)
        #expect(vm.entries.isEmpty)
    }
}
