import Testing
import Foundation
import MindEchoCore

@MainActor
struct DateHelperTests {
    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }

    @Test func logicalDateRange_sameDate_returnsSingleElement() {
        let date = makeDate(year: 2026, month: 3, day: 1)
        let range = DateHelper.logicalDateRange(from: date, to: date)
        #expect(range.count == 1)
        #expect(Calendar.current.isDate(range[0], inSameDayAs: date))
    }

    @Test func logicalDateRange_multipleDays_returnsDescending() {
        let from = makeDate(year: 2026, month: 2, day: 26)
        let to = makeDate(year: 2026, month: 3, day: 1)
        let range = DateHelper.logicalDateRange(from: from, to: to)
        // Feb 26, 27, 28, Mar 1 = 4 days
        #expect(range.count == 4)
        // Descending: Mar 1, Feb 28, Feb 27, Feb 26
        #expect(Calendar.current.component(.day, from: range[0]) == 1)
        #expect(Calendar.current.component(.day, from: range[3]) == 26)
    }

    @Test func logicalDateRange_fromAfterTo_returnsEmpty() {
        let from = makeDate(year: 2026, month: 3, day: 5)
        let to = makeDate(year: 2026, month: 3, day: 1)
        let range = DateHelper.logicalDateRange(from: from, to: to)
        #expect(range.isEmpty)
    }

    @Test func logicalDateRange_allDatesNormalizedToNoon() {
        let from = makeDate(year: 2026, month: 3, day: 1)
        let to = makeDate(year: 2026, month: 3, day: 3)
        let range = DateHelper.logicalDateRange(from: from, to: to)
        for date in range {
            let hour = Calendar.current.component(.hour, from: date)
            #expect(hour == 12)
        }
    }

    @Test func logicalDateRange_crossMonthBoundary() {
        let from = makeDate(year: 2026, month: 1, day: 30)
        let to = makeDate(year: 2026, month: 2, day: 2)
        let range = DateHelper.logicalDateRange(from: from, to: to)
        // Jan 30, 31, Feb 1, 2 = 4 days
        #expect(range.count == 4)
    }
}
