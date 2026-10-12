import SwiftUI
import WidgetKit

struct ClockWidgetEntry: TimelineEntry { let date: Date }
struct ClockWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClockWidgetEntry { ClockWidgetEntry(date: Date()) }
    func getSnapshot(in context: Context, completion: @escaping (ClockWidgetEntry) -> Void) {
        completion(ClockWidgetEntry(date: Date()))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockWidgetEntry>) -> Void) {
        let dates = WidgetClockModel.dates(startingAt: Date())
        completion(Timeline(entries: dates.map { ClockWidgetEntry(date: $0) }, policy: .atEnd))
    }
}
struct ClockWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ClockWidgetEntry
    var body: some View {
        WidgetClockView(date: entry.date, medium: family == .systemMedium)
            .containerBackground(for: .widget) {
                LinearGradient(colors: [Color(white: 0.09), .black, Color(white: 0.035)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            .widgetURL(FLIPWidgetLink.url)
    }
}

@main struct FLIPClockWidget: Widget {
    let kind = "FLIPClockWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClockWidgetProvider()) { entry in ClockWidgetEntryView(entry: entry) }
            .configurationDisplayName("FLIP")
            .description("Hora y fecha con tarjetas monocromáticas. Las actualizaciones dependen de macOS; no muestra segundos.")
            .supportedFamilies([.systemSmall, .systemMedium])
            .containerBackgroundRemovable(false)
    }
}

#if DEBUG
struct FLIPClockWidgetPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            ClockWidgetEntryView(entry: ClockWidgetEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            ClockWidgetEntryView(entry: ClockWidgetEntry(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
#endif
