import Foundation
import MindEchoCore
import SwiftData
import Testing

@testable import MindEcho

@MainActor
struct MonthlyShareViewModelTests {
    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([JournalEntry.self, Recording.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func makeViewModel(container: ModelContainer) -> MonthlyShareViewModel {
        MonthlyShareViewModel(modelContext: container.mainContext)
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.timeZone = TimeZone.current
        return Calendar.current.date(from: components)!
    }

    private func insertEntry(
        context: ModelContext,
        date: Date,
        transcriptions: [String] = []
    ) -> JournalEntry {
        let entry = JournalEntry(date: date)
        for (i, text) in transcriptions.enumerated() {
            let recording = Recording(
                sequenceNumber: i + 1,
                audioFileName: "test_\(i).m4a",
                duration: 30
            )
            recording.transcription = text
            entry.recordings.append(recording)
        }
        context.insert(entry)
        return entry
    }

    // MARK: - fetchAvailableMonths

    @Test func fetchAvailableMonths_groupsByMonth() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = makeViewModel(container: container)

        let mar1 = makeDate(year: 2026, month: 3, day: 10)
        let mar2 = makeDate(year: 2026, month: 3, day: 20)
        let feb = makeDate(year: 2026, month: 2, day: 15)

        insertEntry(context: context, date: mar1, transcriptions: ["テスト1"])
        insertEntry(context: context, date: mar2, transcriptions: ["テスト2"])
        insertEntry(context: context, date: feb, transcriptions: ["テスト3"])

        vm.fetchAvailableMonths()

        #expect(vm.availableMonths.count == 2)
    }

    @Test func fetchAvailableMonths_sortedDescending() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = makeViewModel(container: container)

        insertEntry(context: context, date: makeDate(year: 2026, month: 1, day: 5))
        insertEntry(context: context, date: makeDate(year: 2026, month: 3, day: 5))
        insertEntry(context: context, date: makeDate(year: 2026, month: 2, day: 5))

        vm.fetchAvailableMonths()

        #expect(vm.availableMonths.count == 3)
        #expect(vm.availableMonths[0].month == 3)
        #expect(vm.availableMonths[1].month == 2)
        #expect(vm.availableMonths[2].month == 1)
    }

    @Test func fetchAvailableMonths_emptyData() throws {
        let container = try makeContainer()
        let vm = makeViewModel(container: container)

        vm.fetchAvailableMonths()

        #expect(vm.availableMonths.isEmpty)
    }

    @Test func fetchAvailableMonths_countsEntries() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = makeViewModel(container: container)

        insertEntry(context: context, date: makeDate(year: 2026, month: 3, day: 1))
        insertEntry(context: context, date: makeDate(year: 2026, month: 3, day: 5))
        insertEntry(context: context, date: makeDate(year: 2026, month: 3, day: 10))

        vm.fetchAvailableMonths()

        #expect(vm.availableMonths.count == 1)
        #expect(vm.availableMonths[0].entryCount == 3)
    }

    // MARK: - exportMonth initial states

    @Test func exportMonth_noSelectionDoesNothing() async throws {
        let container = try makeContainer()
        let vm = makeViewModel(container: container)
        vm.selectedMonth = nil

        await vm.exportMonth()

        #expect(vm.exportState == .idle)
    }

    @Test func exportMonth_noMatchingEntriesFailure() async throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = makeViewModel(container: container)

        // 2026年2月にエントリを作成
        let feb = makeDate(year: 2026, month: 2, day: 15)
        insertEntry(context: context, date: feb, transcriptions: ["テスト"])

        vm.fetchAvailableMonths()
        // 3月を選択（エントリなし）
        vm.selectedMonth = MonthlyShareViewModel.AvailableMonth(
            year: 2026, month: 3, entryCount: 0, recordingCount: 0)
        vm.selectedFormat = .text

        await vm.exportMonth()

        if case .failure = vm.exportState {
            // 期待通りの失敗
        } else {
            Issue.record("Expected failure state, got \(vm.exportState)")
        }
    }

    // MARK: - AvailableMonth.displayString

    @Test func availableMonth_displayStringFormat() {
        let month = MonthlyShareViewModel.AvailableMonth(
            year: 2026, month: 3, entryCount: 5, recordingCount: 10
        )
        // "2026年3月（5件）" の形式であること
        #expect(month.displayString.contains("2026"))
        #expect(month.displayString.contains("3月"))
        #expect(month.displayString.contains("5件"))
    }

    // MARK: - MonthlyShareFormat

    @Test func monthlyShareFormat_allCasesPresent() {
        let cases = MonthlyShareFormat.allCases
        #expect(cases.contains(.pdf))
        #expect(cases.contains(.audio))
        #expect(cases.contains(.text))
    }

    @Test func monthlyShareFormat_displayNames() {
        #expect(MonthlyShareFormat.pdf.displayName == "PDF")
        #expect(MonthlyShareFormat.audio.displayName == "音声")
        #expect(MonthlyShareFormat.text.displayName == "テキスト")
    }
}
