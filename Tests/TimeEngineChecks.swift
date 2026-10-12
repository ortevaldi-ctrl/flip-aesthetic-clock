import Foundation

@main struct TimeEngineChecks {
    static func main() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        func date(_ hour: Int, _ minute: Int, _ second: Int) -> Date {
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 9, hour: hour, minute: minute, second: second))!
        }
        precondition(ClockValues.values(at: date(0, 0, 0), twelveHour: false, calendar: calendar) == ["00", "00", "00"])
        precondition(ClockValues.values(at: date(0, 0, 0), twelveHour: true, calendar: calendar) == ["12", "00", "00"])
        precondition(ClockValues.values(at: date(12, 0, 0), twelveHour: true, calendar: calendar) == ["12", "00", "00"])
        precondition(ClockValues.values(at: date(23, 59, 59).addingTimeInterval(1), twelveHour: false, calendar: calendar) == ["00", "00", "00"])
        precondition(ClockValues.values(at: date(13, 5, 7), twelveHour: true, calendar: calendar) == ["01", "05", "07"])
        let instant = date(8, 0, 0)
        calendar.timeZone = TimeZone(secondsFromGMT: 7200)!
        precondition(ClockValues.values(at: instant, twelveHour: false, calendar: calendar) == ["10", "00", "00"])
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        precondition(ClockValues.values(at: instant.addingTimeInterval(3600 * 8), twelveHour: false, calendar: calendar) == ["16", "00", "00"])
        print("PASS: midnight, noon, rollover, 12h padding, time zone and eight-hour wall-time jump")
    }
}
