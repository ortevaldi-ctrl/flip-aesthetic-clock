import SwiftUI

/// Deterministic procedural artwork. No network, random changes between frames, or external assets.
struct CollectionBackground: View {
    let style: ClockStyle
    let time: Double
    var body: some View {
        Canvas(opaque: true, rendersAsynchronously: true) { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))
            switch style {
            case .topographic: topographic(&context, size)
            case .mountain: mountain(&context, size)
            case .darkOcean: ocean(&context, size)
            case .space: space(&context, size)
            case .moon: moon(&context, size)
            case .nightCity: city(&context, size)
            case .whiteNeon: neon(&context, size)
            case .technicalGrid: grid(&context, size)
            case .abstractMetal: metal(&context, size)
            case .particles: particles(&context, size)
            default: break
            }
            // Preserve the clock as the foreground on every piece of artwork.
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(Gradient(colors: [.black.opacity(0.35), .clear, .black.opacity(0.32)]), center: CGPoint(x: size.width * 0.5, y: size.height * 0.49), startRadius: 0, endRadius: max(size.width, size.height) * 0.7))
        }
    }
    private func noise(_ seed: Int) -> Double {
        let value = sin(Double(seed) * 127.1 + 311.7) * 43758.5453
        return value - floor(value)
    }
    private func rectangle(_ size: CGSize) -> Path { Path(CGRect(origin: .zero, size: size)) }
    private func backdrop(_ context: inout GraphicsContext, _ size: CGSize, _ shades: [Double]) {
        context.fill(rectangle(size), with: .linearGradient(Gradient(colors: shades.map { Color(white: $0) }), startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
    }
    private func line(_ points: [CGPoint]) -> Path {
        Path { path in guard let first = points.first else { return }; path.move(to: first); for p in points.dropFirst() { path.addLine(to: p) } }
    }
    private func topographic(_ c: inout GraphicsContext, _ s: CGSize) {
        backdrop(&c, s, [0.065, 0.035])
        for contour in 0..<37 {
            let radius = Double(contour + 1) * 0.029
            var points: [CGPoint] = []
            for step in 0...180 {
                let a = Double(step) / 180 * .pi * 2
                let relief = 1 + 0.15 * sin(a * 3 + radius * 5) + 0.08 * cos(a * 7 - radius * 2)
                points.append(CGPoint(x: s.width * (0.23 + cos(a) * radius * relief * 0.8), y: s.height * (0.3 + sin(a) * radius * relief)))
            }
            c.stroke(line(points), with: .color(.white.opacity(contour % 5 == 0 ? 0.22 : 0.11)), lineWidth: contour % 5 == 0 ? 0.9 : 0.5)
        }
    }
    private func mountain(_ c: inout GraphicsContext, _ s: CGSize) {
        backdrop(&c, s, [0.21, 0.32, 0.075])
        // Irregular ridgelines and progressively darker layers establish aerial perspective.
        for layer in 0..<6 {
            var points = [CGPoint(x: -10, y: s.height)]
            for step in 0...100 {
                let x = Double(step) / 100
                let ridge = 0.48 + Double(layer) * 0.076 - abs(sin(x * 8 + Double(layer) * 1.9)) * (0.22 - Double(layer) * 0.022) + (noise(step * 5 + layer * 137) - 0.5) * 0.055
                points.append(CGPoint(x: x * s.width, y: ridge * s.height))
            }
            points.append(CGPoint(x: s.width + 10, y: s.height))
            var path = line(points); path.closeSubpath()
            let shade = 0.26 - Double(layer) * 0.043
            c.fill(path, with: .linearGradient(Gradient(colors: [Color(white: shade), Color(white: max(0.025, shade - 0.06))]), startPoint: .zero, endPoint: CGPoint(x: s.width * 0.7, y: s.height)))
            c.stroke(line(Array(points.dropFirst().dropLast())), with: .color(.white.opacity(0.04)), lineWidth: 0.6)
        }
        var mist = c
        mist.addFilter(.blur(radius: s.height * 0.035))
        for band in 0..<3 {
            mist.fill(Path(ellipseIn: CGRect(x: -s.width * 0.15, y: s.height * (0.5 + Double(band) * 0.1), width: s.width * 1.3, height: s.height * 0.045)), with: .color(.white.opacity(0.075)))
        }
    }
    private func ocean(_ c: inout GraphicsContext, _ s: CGSize) {
        backdrop(&c, s, [0.075, 0.16, 0.025])
        let horizon = s.height * 0.39
        c.stroke(line([CGPoint(x: 0, y: horizon), CGPoint(x: s.width, y: horizon)]), with: .color(.white.opacity(0.16)), lineWidth: 0.6)
        for row in 0..<75 {
            let depth = Double(row) / 74
            let y = horizon + depth * depth * (s.height - horizon)
            var points: [CGPoint] = []
            for step in 0...100 {
                let x = Double(step) / 100
                let wave = sin(x * 35 + Double(row) * 1.7 + time * 2) + 0.45 * cos(x * 73 - time + Double(row))
                points.append(CGPoint(x: x * s.width, y: y + wave * (1 + depth * 7)))
            }
            c.stroke(line(points), with: .linearGradient(Gradient(colors: [.white.opacity(0.02), .white.opacity(0.07 + noise(row) * 0.13), .white.opacity(0.015)]), startPoint: CGPoint(x: 0, y: y), endPoint: CGPoint(x: s.width, y: y)), lineWidth: 0.5 + depth)
        }
    }
    private func stars(_ c: inout GraphicsContext, _ s: CGSize) {
        for i in 0..<160 {
            let radius = 0.35 + noise(i + 900) * 1.15
            c.fill(Path(ellipseIn: CGRect(x: noise(i * 3) * s.width, y: noise(i * 3 + 1) * s.height, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.15 + noise(i + 500) * 0.6)))
        }
    }
    private func space(_ c: inout GraphicsContext, _ s: CGSize) {
        stars(&c, s)
        let d = min(s.width * 0.35, s.height * 0.52)
        let r = CGRect(x: s.width * 0.74 - d / 2, y: s.height * 0.15 - d * 0.25, width: d, height: d)
        let disk = Path(ellipseIn: r)
        var planet = c
        planet.addFilter(.shadow(color: .white.opacity(0.08), radius: 12))
        planet.fill(disk, with: .radialGradient(Gradient(colors: [Color(white: 0.55), Color(white: 0.16), .black]), center: CGPoint(x: r.minX + d * 0.12, y: r.minY + d * 0.12), startRadius: 0, endRadius: d * 0.9))
        c.stroke(disk, with: .color(.white.opacity(0.12)), lineWidth: 0.6)
        var surface = c; surface.clip(to: disk)
        for i in 0..<250 {
            let diameter = 1 + noise(i + 601) * 5
            surface.fill(Path(ellipseIn: CGRect(x: r.minX + noise(i * 3) * d, y: r.minY + noise(i * 3 + 2) * d, width: diameter, height: diameter)), with: .color(.black.opacity(0.08)))
        }
    }
    private func moon(_ c: inout GraphicsContext, _ s: CGSize) {
        backdrop(&c, s, [0.005, 0.02])
        let d = max(s.width, s.height) * 1.08
        let bounds = CGRect(x: s.width * 0.18, y: s.height * 0.28, width: d, height: d)
        let disk = Path(ellipseIn: bounds)
        c.fill(disk, with: .radialGradient(Gradient(colors: [Color(white: 0.50), Color(white: 0.24), Color(white: 0.035)]), center: CGPoint(x: bounds.minX, y: bounds.minY + d * 0.15), startRadius: 0, endRadius: d))
        var surface = c; surface.clip(to: disk)
        for i in 0..<440 {
            let x = bounds.minX + noise(i * 4) * d
            let y = bounds.minY + noise(i * 4 + 1) * d
            let radius = (0.003 + pow(noise(i * 4 + 2), 5) * 0.046) * d
            let crater = CGRect(x: x, y: y, width: radius * 2, height: radius * 1.55)
            surface.fill(Path(ellipseIn: crater), with: .linearGradient(Gradient(colors: [.black.opacity(0.48), .white.opacity(0.025)]), startPoint: CGPoint(x: x, y: y), endPoint: CGPoint(x: x + radius * 2, y: y + radius)))
            surface.stroke(Path(ellipseIn: crater.insetBy(dx: -0.8, dy: -0.8)), with: .linearGradient(Gradient(colors: [.white.opacity(0.23), .clear, .black.opacity(0.25)]), startPoint: CGPoint(x: x, y: y), endPoint: CGPoint(x: x + radius * 2, y: y + radius * 2)), lineWidth: max(0.5, radius * 0.09))
        }
        for i in 0..<1600 {
            let x = bounds.minX + noise(i * 2 + 9000) * d, y = bounds.minY + noise(i * 2 + 9001) * d
            surface.fill(Path(CGRect(x: x, y: y, width: 1, height: 1)), with: .color(.white.opacity(0.045)))
        }
    }
    private func city(_ c: inout GraphicsContext, _ s: CGSize) {
        backdrop(&c, s, [0.025, 0.14, 0.025])
        let horizon = s.height * 0.76
        for layer in 0..<2 {
            for i in 0..<34 {
                let width = s.width / 31
                let x = Double(i) * width - width + Double(layer) * width * 0.4
                let height = s.height * (0.08 + noise(i + layer * 88) * (layer == 0 ? 0.26 : 0.42))
                let rect = CGRect(x: x, y: horizon - height, width: width * 0.86, height: height)
                c.fill(Path(rect), with: .color(Color(white: layer == 0 ? 0.095 : 0.025)))
                if i % 7 == 0 { c.stroke(line([CGPoint(x: rect.midX, y: rect.minY), CGPoint(x: rect.midX, y: rect.minY - s.height * 0.035)]), with: .color(Color(white: 0.25)), lineWidth: 1) }
                for row in 0..<Int(height / 10) {
                    for col in 0..<3 where noise(i * 307 + row * 13 + col + layer * 19) > 0.54 {
                        let wx = x + width * (0.18 + Double(col) * 0.23), wy = rect.minY + Double(row) * 10 + 5
                        c.fill(Path(CGRect(x: wx, y: wy, width: max(1, width * 0.07), height: 2)), with: .color(.white.opacity(0.13 + noise(i + row) * 0.32)))
                        let reflection = CGRect(x: wx, y: horizon + (horizon - wy) * 0.45, width: max(1, width * 0.08), height: 3 + noise(row) * 8)
                        c.fill(Path(reflection), with: .color(.white.opacity(0.035)))
                    }
                }
            }
        }
        c.stroke(line([CGPoint(x: 0, y: horizon), CGPoint(x: s.width, y: horizon)]), with: .color(.white.opacity(0.08)), lineWidth: 1)
    }
    private func neon(_ c: inout GraphicsContext, _ s: CGSize) {
        let paths = [line([CGPoint(x: s.width * 0.07, y: s.height * 0.18), CGPoint(x: s.width * 0.07, y: s.height * 0.83), CGPoint(x: s.width * 0.27, y: s.height * 0.83)]), line([CGPoint(x: s.width * 0.72, y: s.height * 0.17), CGPoint(x: s.width * 0.93, y: s.height * 0.17), CGPoint(x: s.width * 0.93, y: s.height * 0.82)])]
        var glow = c; glow.addFilter(.blur(radius: 18))
        for p in paths { glow.stroke(p, with: .color(.white.opacity(0.25)), lineWidth: 9); c.stroke(p, with: .color(.white.opacity(0.65)), lineWidth: 1.5) }
    }
    private func grid(_ c: inout GraphicsContext, _ s: CGSize) {
        let vanishing = CGPoint(x: s.width * 0.5, y: s.height * 0.36)
        for i in -14...14 {
            c.stroke(line([vanishing, CGPoint(x: s.width * 0.5 + Double(i) * s.width * 0.13, y: s.height)]), with: .color(.white.opacity(i % 5 == 0 ? 0.16 : 0.07)), lineWidth: 0.6)
        }
        for i in 0..<20 {
            let y = vanishing.y + pow(Double(i) / 19, 2.5) * (s.height - vanishing.y)
            c.stroke(line([CGPoint(x: 0, y: y), CGPoint(x: s.width, y: y)]), with: .color(.white.opacity(0.10)), lineWidth: 0.5)
        }
        for i in 1..<12 {
            let y = Double(i) * s.height / 24
            c.stroke(line([CGPoint(x: 0, y: y), CGPoint(x: s.width, y: y)]), with: .color(.white.opacity(0.025)), lineWidth: 0.5)
        }
    }
    private func metal(_ c: inout GraphicsContext, _ s: CGSize) {
        backdrop(&c, s, [0.07, 0.015])
        for i in 0..<4 {
            let offset = Double(i) * s.width * 0.22
            let path = Path { p in
                p.move(to: CGPoint(x: offset - s.width * 0.3, y: -20))
                p.addCurve(to: CGPoint(x: offset + s.width * 0.38, y: s.height + 20), control1: CGPoint(x: offset + s.width * 0.65, y: s.height * 0.2), control2: CGPoint(x: offset - s.width * 0.2, y: s.height * 0.8))
                p.addLine(to: CGPoint(x: offset + s.width * 0.6, y: s.height + 20))
                p.addCurve(to: CGPoint(x: offset - s.width * 0.12, y: -20), control1: CGPoint(x: offset + s.width * 0.04, y: s.height * 0.75), control2: CGPoint(x: offset + s.width * 0.8, y: s.height * 0.15))
                p.closeSubpath()
            }
            c.fill(path, with: .linearGradient(Gradient(colors: [Color(white: 0.04), Color(white: 0.36), Color(white: 0.11), Color(white: 0.52), Color(white: 0.06)]), startPoint: CGPoint(x: offset, y: 0), endPoint: CGPoint(x: offset + s.width * 0.35, y: s.height)))
            c.stroke(path, with: .color(.white.opacity(0.13)), lineWidth: 0.7)
            var brushed = c; brushed.clip(to: path)
            for j in 0..<150 {
                let y = Double(j) / 150 * s.height
                brushed.stroke(line([CGPoint(x: 0, y: y), CGPoint(x: s.width, y: y + 10)]), with: .color(.white.opacity(0.018)), lineWidth: 0.5)
            }
        }
    }
    private func particles(_ c: inout GraphicsContext, _ s: CGSize) {
        for i in 0..<95 {
            let depth = noise(i + 345)
            let x = (noise(i * 3) + sin(time * 0.3 + Double(i)) * 0.018) * s.width
            let drift = noise(i * 3 + 1) - time * (0.004 + depth * 0.004)
            let y = (drift - floor(drift)) * s.height
            let radius = 0.5 + depth * 2
            let dot = Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2))
            if depth > 0.8 {
                var glow = c; glow.addFilter(.blur(radius: 3)); glow.fill(dot, with: .color(.white.opacity(0.15)))
            }
            c.fill(dot, with: .color(.white.opacity(0.12 + depth * 0.40)))
        }
    }
}
