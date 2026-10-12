import Foundation

/// A finite batch of minute entries: no resident timer, second ticks or animation loop.
enum WidgetClockModel {
    static let minuteCount = 120
    static func dates(startingAt now: Date, calendar: Calendar = .autoupdatingCurrent) -> [Date] {
        guard let minute = calendar.dateInterval(of: .minute, for: now)?.start else { return [now] }
        // The first entry is current; future entries land at minute boundaries, including DST changes.
        return [now] + (1...minuteCount).map { minute.addingTimeInterval(Double($0) * 60) }
    }
    static func values(at date: Date, calendar: Calendar = .autoupdatingCurrent) -> [String] {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return [parts.hour ?? 0, parts.minute ?? 0].map { String(format: "%02d", $0) }
    }
    static func dateLabel(at date: Date, locale: Locale = .autoupdatingCurrent, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale; formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM")
        return formatter.string(from: date)
    }
}
