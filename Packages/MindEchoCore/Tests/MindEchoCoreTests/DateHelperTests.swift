import Testing
import Foundation
@testable import MindEchoCore

@MainActor
struct DateHelperTests {
    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone.current
        return Calendar.current.date(from: components)!
    }

    @Test func afternoonTime_returnsCurrentDay() {
        let date = makeDate(year: 2025, month: 2, day: 7, hour: 15)
        let logical = DateHelper.logicalDate(for: date)
        let cal = Calendar.current
        #expect(cal.component(.day, from: logical) == 7)
        #expect(cal.component(.month, from: logical) == 2)
        #expect(cal.component(.hour, from: logical) == 12) // normalized to noon
    }

    @Test func lateNightBeforeBoundary_returnsPreviousDay() {
        let date = makeDate(year: 2025, month: 2, day: 8, hour: 2, minute: 30)
        let logical = DateHelper.logicalDate(for: date)
        let cal = Calendar.current
        #expect(cal.component(.day, from: logical) == 7) // Previous day
        #expect(cal.component(.month, from: logical) == 2)
    }

    @Test func exactlyAtBoundary_returnsCurrentDay() {
        let date = makeDate(year: 2025, month: 2, day: 8, hour: 3, minute: 0)
        let logical = DateHelper.logicalDate(for: date)
        let cal = Calendar.current
        #expect(cal.component(.day, from: logical) == 8) // Current day (3AM is boundary)
    }

    @Test func justBeforeBoundary_returnsPreviousDay() {
        let date = makeDate(year: 2025, month: 2, day: 8, hour: 2, minute: 59)
        let logical = DateHelper.logicalDate(for: date)
        let cal = Calendar.current
        #expect(cal.component(.day, from: logical) == 7) // Previous day
    }

    @Test func midnight_returnsPreviousDay() {
        let date = makeDate(year: 2025, month: 2, day: 8, hour: 0, minute: 0)
        let logical = DateHelper.logicalDate(for: date)
        let cal = Calendar.current
        #expect(cal.component(.day, from: logical) == 7)
    }

    @Test func displayString_containsJapaneseFormat() {
        let date = makeDate(year: 2025, month: 2, day: 7, hour: 12)
        let logical = DateHelper.logicalDate(for: date)
        let display = DateHelper.displayString(for: logical)
        #expect(display.contains("2025"))
        #expect(display.contains("2"))
        #expect(display.contains("7"))
    }
}
