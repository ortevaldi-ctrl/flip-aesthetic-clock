import SwiftUI

/// Isolates time updates from the gallery and background scene.
struct ClockFace: View {
    let size: CGSize
    let twelveHour: Bool
    let seconds: Bool
    let showDate: Bool
    let scale: Double
    let duration: Double
    @ObservedObject var visibility: WindowVisibility
    @StateObject private var time = TimeEngine()
    var body: some View {
        VStack(spacing: 25) {
                    let values = ClockValues.values(at: time.date, twelveHour: twelveHour)
                    let count = seconds ? 3 : 2
                    let width = min(260, (size.width - 90) / CGFloat(count) - 18) * scale
                    HStack(spacing: 18) {
                        ForEach(0..<count, id: \.self) { index in
                            VStack(spacing: 15) {
                                FlipCard(value: values[index], width: width, duration: duration)
                                Text(["HORAS", "MINUTOS", "SEGUNDOS"][index]).font(.system(size: 10, weight: .medium)).tracking(4).foregroundStyle(.white.opacity(0.45))
                            }
                        }
                    }
                    if showDate { Text(time.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year())).font(.system(size: 14, weight: .light)).tracking(2).foregroundStyle(.white.opacity(0.65)) }
                    if twelveHour { Text(Calendar.autoupdatingCurrent.component(.hour, from: time.date) < 12 ? "AM" : "PM").font(.caption).foregroundStyle(.white.opacity(0.5)) }
                }
        .excludesFLIPBackgroundTap()
        .onAppear { time.setShowsSeconds(seconds); time.setRunning(visibility.canRender) }
        .onChange(of: seconds) { _, value in time.setShowsSeconds(value) }
        .onChange(of: visibility.canRender) { _, value in time.setRunning(value) }
        .onDisappear { time.setRunning(false) }
    }
}
