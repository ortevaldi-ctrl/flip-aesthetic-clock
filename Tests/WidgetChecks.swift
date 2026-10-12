import Foundation
import SwiftUI
import AppKit

@main struct WidgetChecks {
    @MainActor static func main() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let formatter = ISO8601DateFormatter()
        let now = formatter.date(from: "2026-10-10T23:59:47Z")!
        let dates = WidgetClockModel.dates(startingAt: now, calendar: calendar)
        precondition(dates.count == 121 && dates.first == now)
        precondition(WidgetClockModel.values(at: dates[0], calendar: calendar) == ["23", "59"])
        precondition(WidgetClockModel.values(at: dates[1], calendar: calendar) == ["00", "00"])
        precondition(calendar.component(.day, from: dates[1]) == 11)
        for (earlier, later) in zip(dates, dates.dropFirst()) { precondition(later > earlier) }
        for date in dates.dropFirst() { precondition(calendar.component(.second, from: date) == 0) }
        precondition(dates.last!.timeIntervalSince(dates[1]) == 119 * 60)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        let spring = formatter.date(from: "2026-03-29T00:59:00Z")!
        precondition(WidgetClockModel.values(at: spring, calendar: calendar) == ["01", "59"])
        precondition(WidgetClockModel.values(at: spring.addingTimeInterval(60), calendar: calendar) == ["03", "00"])
        let autumn = formatter.date(from: "2026-10-25T00:59:00Z")!
        precondition(WidgetClockModel.values(at: autumn, calendar: calendar) == ["02", "59"])
        precondition(WidgetClockModel.values(at: autumn.addingTimeInterval(60), calendar: calendar) == ["02", "00"])
        precondition(FLIPWidgetLink.accepts(FLIPWidgetLink.url))
        precondition(!FLIPWidgetLink.accepts(URL(string: "https://open/clock")!))
        precondition(!FLIPWidgetLink.accepts(URL(string: "flip-clock://unknown/clock")!))
        precondition(!FLIPWidgetLink.accepts(URL(string: "flip-clock://open/timer")!))
        print("PASS: minute timeline, midnight/date rollover, both DST transitions and validated app URL")
        let directory = URL(fileURLWithPath: "build/WidgetVerification")
        let samples: [(String, CGFloat, CGFloat, Bool)] = [
            ("small", 170, 170, false), ("medium", 360, 170, true),
            ("small-compact", 158, 158, false), ("medium-compact", 338, 158, true)
        ]
        for (name, width, height, medium) in samples {
            let artwork = WidgetClockView(date: now, medium: medium).padding(16)
                .frame(width: width, height: height)
                .background(LinearGradient(colors: [Color(white: 0.09), .black, Color(white: 0.035)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .environment(\.colorScheme, .dark)
            let renderer = ImageRenderer(content: artwork); renderer.scale = 2
            guard let image = renderer.cgImage else { fatalError("Render failed: \(name)") }
            let bitmap = NSBitmapImageRep(cgImage: image)
            guard let data = bitmap.representation(using: .png, properties: [:]) else { fatalError("PNG failed") }
            try data.write(to: directory.appendingPathComponent("widget-\(name).png"))
            print("Rendered offscreen: \(name), \(Int(width))×\(Int(height)) points")
        }
    }
}
