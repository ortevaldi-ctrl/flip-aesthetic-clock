import SwiftUI

/// Static cards adapted for widget rendering. Reuses FLIP's visual grammar, without FlipCard's tasks.
struct WidgetClockView: View {
    let date: Date
    let medium: Bool
    var body: some View {
        GeometryReader { geometry in
            let gap: CGFloat = medium ? 12 : 8
            let availableWidth = max(60, geometry.size.width - (medium ? 110 : 0))
            let width = min((availableWidth - gap) / 2, max(30, geometry.size.height - 50) / 0.94)
            let values = WidgetClockModel.values(at: date)
            HStack(spacing: medium ? 18 : 0) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("FLIP").font(.system(size: 9, weight: .semibold)).tracking(3).foregroundStyle(.white.opacity(0.60))
                    HStack(spacing: gap) {
                        card(values[0], width: width)
                        card(values[1], width: width)
                    }
                    if !medium {
                        Text(WidgetClockModel.dateLabel(at: date)).font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75)).lineLimit(1).minimumScaleFactor(0.75)
                    }
                }
                if medium {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(date.formatted(.dateTime.day())).font(.system(size: 32, weight: .light, design: .rounded))
                        Text(WidgetClockModel.dateLabel(at: date)).font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75)).fixedSize(horizontal: false, vertical: true)
                        Text("Abrir FLIP").font(.system(size: 9)).foregroundStyle(.white.opacity(0.45))
                    }.frame(width: 90, alignment: .leading)
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }.foregroundStyle(.white)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("FLIP. \(WidgetClockModel.values(at: date).joined(separator: ":")), \(WidgetClockModel.dateLabel(at: date)). Abrir FLIP.")
    }
    private func card(_ value: String, width: CGFloat) -> some View {
        let height = width * 0.94
        return ZStack {
            VStack(spacing: 0) {
                Color(white: 0.13)
                Color(white: 0.17)
            }
            Text(value).font(.system(size: width * 0.65, weight: .semibold, design: .rounded))
                .monospacedDigit().minimumScaleFactor(0.6)
            Rectangle().fill(.black.opacity(0.85)).frame(height: 1)
            HStack { hinge; Spacer(); hinge }.padding(.horizontal, 3)
        }.frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: width * 0.09))
            .overlay(RoundedRectangle(cornerRadius: width * 0.09).stroke(.white.opacity(0.10), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
    }
    private var hinge: some View { RoundedRectangle(cornerRadius: 1).fill(Color(white: 0.36)).frame(width: 2, height: 6) }
}
