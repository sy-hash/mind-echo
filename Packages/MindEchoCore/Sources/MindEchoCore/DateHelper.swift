import Foundation

public enum DateHelper {
    private static let boundaryHour = 3

    /// Returns the logical date for the given timestamp, normalized to noon (12:00) local time.
    /// Times between 00:00-02:59 are considered part of the previous day.
    public static func logicalDate(for date: Date = Date(), calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.timeZone = TimeZone.current
        let components = cal.dateComponents([.year, .month, .day, .hour], from: date)
        var targetDay = cal.dateComponents([.year, .month, .day], from: date)
        if let hour = components.hour, hour < boundaryHour {
            // Before 3 AM -> belongs to previous day
            guard let previousDay = cal.date(byAdding: .day, value: -1, to: date) else {
                return date
            }
            targetDay = cal.dateComponents([.year, .month, .day], from: previousDay)
        }
        targetDay.hour = 12
        targetDay.minute = 0
        targetDay.second = 0
        return cal.date(from: targetDay) ?? date
    }

    /// Returns a formatted display string for the logical date, e.g. "2025年2月7日（金）"
    public static func displayString(for date: Date, calendar: Calendar = .current) -> String {
        var cal = calendar
        cal.timeZone = TimeZone.current
        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日（E）"
        return formatter.string(from: date)
    }

    /// Returns the logical date for "today" (current moment)
    public static func today(calendar: Calendar = .current) -> Date {
        logicalDate(for: Date(), calendar: calendar)
    }

    /// Returns an array of logical dates from `from` to `to` (inclusive, descending order).
    /// Both `from` and `to` should be logical dates (normalized to noon).
    public static func logicalDateRange(from: Date, to: Date, calendar: Calendar = .current) -> [Date] {
        var cal = calendar
        cal.timeZone = TimeZone.current
        let fromNoon = logicalDate(for: from, calendar: cal)
        let toNoon = logicalDate(for: to, calendar: cal)

        guard fromNoon <= toNoon else { return [] }

        var dates: [Date] = []
        var current = toNoon
        while current >= fromNoon {
            dates.append(current)
            guard let prev = cal.date(byAdding: .day, value: -1, to: current) else { break }
            current = prev
        }
        return dates
    }
}
