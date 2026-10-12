import SwiftUI
import WidgetKit
import AppIntents

struct IOSClockWidgetEntry: TimelineEntry {
    let date: Date
    let background: WidgetBackgroundChoice
}
struct IOSClockWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> IOSClockWidgetEntry {
        IOSClockWidgetEntry(date: Date(), background: .minimalBlack)
    }
    func snapshot(for configuration: WidgetBackgroundIntent, in context: Context) async -> IOSClockWidgetEntry {
        IOSClockWidgetEntry(date: Date(), background: configuration.background)
    }
    func timeline(for configuration: WidgetBackgroundIntent, in context: Context) async -> Timeline<IOSClockWidgetEntry> {
        let entries = WidgetClockModel.dates(startingAt: Date()).map {
            IOSClockWidgetEntry(date: $0, background: configuration.background)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}
struct IOSClockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: IOSClockWidgetEntry
    var body: some View {
        WidgetClockView(date: entry.date, medium: family == .systemMedium)
            .containerBackground(for: .widget) {
                ClockBackground(style: entry.background.clockStyle, animated: false)
                    .environment(\.colorScheme, .dark)
                    .overlay(Color.black.opacity(0.12))
            }
    }
}
@main
struct FLIPIOSWidget: Widget {
    let kind = "FLIPIOSClockWidget"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WidgetBackgroundIntent.self, provider: IOSClockWidgetProvider()) {
            IOSClockWidgetView(entry: $0)
        }
        .configurationDisplayName("FLIP")
        .description("Hora y fecha. Mantén pulsado el widget y elige Editar widget para cambiar el fondo.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .containerBackgroundRemovable(false)
    }
}
#if DEBUG
struct FLIPIOSWidgetPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            IOSClockWidgetView(entry: IOSClockWidgetEntry(date: Date(), background: .mountain))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            IOSClockWidgetView(entry: IOSClockWidgetEntry(date: Date(), background: .waves))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
#endif
