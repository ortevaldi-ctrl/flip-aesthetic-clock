import SwiftUI

enum ClockStyle: String, CaseIterable, Identifiable {
    case minimalBlack = "Minimal Black", darkGradient = "Dark Gradient", frostedGlass = "Frosted Glass", monochromeAurora = "Monochrome Aurora", liquidChrome = "Liquid Chrome"
    case topographic = "Topographic", mountain = "Mountain", darkOcean = "Dark Ocean", space = "Space", moon = "Moon"
    case nightCity = "Night City", whiteNeon = "White Neon", technicalGrid = "Technical Grid", abstractMetal = "Abstract Metal", particles = "Particles"
    case waves = "Waves", brushedTitanium = "Brushed Titanium", carbonFiber = "Carbon Fiber", verticalSplit = "Vertical Split", outline = "Outline"
    case dotMatrix = "Dot Matrix", retroFilm = "Retro Film", earth = "Earth", minimalLines = "Minimal Lines", blackSilk = "Black Silk"
    var hasAmbientMotion: Bool { [.monochromeAurora, .liquidChrome, .darkOcean, .particles, .waves].contains(self) }
    var id: String { rawValue }
}
struct ClockBackground: View {
    let style: ClockStyle
    var animated = true
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: !animated || !style.hasAmbientMotion)) { context in
            let t = animated ? context.date.timeIntervalSinceReferenceDate * 0.06 : 0
            GeometryReader { geo in
                ZStack {
                    Color.black
                    switch style {
                    case .waves, .brushedTitanium, .carbonFiber, .verticalSplit, .outline, .dotMatrix, .retroFilm, .earth, .minimalLines, .blackSilk:
                        PremiumBackground(style: style, time: t)
                    case .minimalBlack: Color.black
                    case .darkGradient:
                        LinearGradient(colors: [.black, Color(white: 0.25), Color(white: 0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    case .frostedGlass:
                        LinearGradient(colors: [Color(white: 0.36), Color(white: 0.10)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        Circle().fill(.white.opacity(0.12)).frame(width: geo.size.width * 0.7).blur(radius: 70).offset(x: -geo.size.width * 0.3, y: -100)
                        RoundedRectangle(cornerRadius: 50).fill(.ultraThinMaterial).padding(45).opacity(0.35)
                    case .monochromeAurora:
                        ForEach(0..<4) { i in
                            Ellipse().fill(LinearGradient(colors: [.white.opacity(0.16), .clear], startPoint: .top, endPoint: .bottom))
                                .frame(width: geo.size.width * 0.4, height: geo.size.height * 1.5)
                                .rotationEffect(.degrees(25 + sin(t + Double(i)) * 15))
                                .offset(x: CGFloat(i - 2) * geo.size.width * 0.24, y: CGFloat(sin(t + Double(i))) * 60).blur(radius: 45)
                        }
                    case .topographic, .mountain, .darkOcean, .space, .moon, .nightCity, .whiteNeon, .technicalGrid, .abstractMetal, .particles:
                        CollectionBackground(style: style, time: t)
                    case .liquidChrome:
                        Canvas { context, size in
                            for i in 0..<32 {
                                var path = Path()
                                let y = CGFloat(i) / 31 * size.height
                                path.move(to: CGPoint(x: -20, y: y))
                                path.addCurve(to: CGPoint(x: size.width + 20, y: y + 80 * sin(t)), control1: CGPoint(x: size.width * 0.3, y: y + 180 * sin(t + Double(i) * 0.16)), control2: CGPoint(x: size.width * 0.65, y: y - 150 * cos(t + Double(i) * 0.13)))
                                context.stroke(path, with: .linearGradient(Gradient(colors: [.black, .white.opacity(0.36), Color(white: 0.08), .white.opacity(0.22), .black]), startPoint: .zero, endPoint: CGPoint(x: size.width, y: size.height)), lineWidth: 14)
                            }
                        }.blur(radius: 9)
                    }
                }
            }
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}
