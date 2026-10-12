import SwiftUI

struct PremiumBackground: View {
    let style: ClockStyle
    let time: Double
    var body: some View {
        Canvas(opaque: true, rendersAsynchronously: true) { c, s in
            let bounds = Path(CGRect(origin: .zero, size: s))
            c.fill(bounds, with: .color(.black))
            switch style {
            case .waves:
                for row in 0..<44 {
                    var p = Path()
                    for step in 0...110 {
                        let x = Double(step) / 110, base = Double(row) / 43
                        let y = base * 0.85 + 0.08 + sin(x * 8 + base * 5 + time * 0.45) * 0.05 + cos(x * 4 - base * 3) * 0.045
                        let point = CGPoint(x: x * s.width, y: y * s.height)
                        if step == 0 { p.move(to: point) } else { p.addLine(to: point) }
                    }
                    c.stroke(p, with: .color(.white.opacity(row % 6 == 0 ? 0.26 : 0.10)), lineWidth: row % 6 == 0 ? 0.85 : 0.45)
                }
            case .brushedTitanium:
                c.fill(bounds, with: .linearGradient(Gradient(colors: [Color(white: 0.10), Color(white: 0.27), Color(white: 0.14), Color(white: 0.08)]), startPoint: .zero, endPoint: CGPoint(x: s.width, y: s.height * 0.7)))
                for i in 0..<850 {
                    let y = Double(i) / 850 * s.height
                    let start = noise(i) * s.width * 0.2
                    let p = line(CGPoint(x: start, y: y), CGPoint(x: s.width - noise(i + 1000) * s.width * 0.2, y: y - s.height * 0.04))
                    c.stroke(p, with: .color((i % 2 == 0 ? Color.white : Color.black).opacity(0.018 + noise(i + 19) * 0.045)), lineWidth: 0.45)
                }
            case .carbonFiber:
                let tile = max(8, s.width / 110)
                for row in 0...Int(s.height / tile) {
                    for col in 0...Int(s.width / tile) {
                        let horizontal = (row + col) % 4 < 2
                        let r = CGRect(x: Double(col) * tile, y: Double(row) * tile, width: tile - 0.5, height: tile - 0.5)
                        c.fill(Path(r), with: .linearGradient(Gradient(colors: [Color(white: 0.035), Color(white: 0.13), Color(white: 0.045)]), startPoint: r.origin, endPoint: CGPoint(x: horizontal ? r.minX : r.maxX, y: horizontal ? r.maxY : r.minY)))
                        for fiber in 1..<4 {
                            let offset = Double(fiber) * tile / 4
                            let a = CGPoint(x: horizontal ? r.minX : r.minX + offset, y: horizontal ? r.minY + offset : r.minY)
                            let b = CGPoint(x: horizontal ? r.maxX : a.x, y: horizontal ? a.y : r.maxY)
                            c.stroke(line(a, b), with: .color(.white.opacity(0.025)), lineWidth: 0.4)
                        }
                    }
                }
            case .verticalSplit:
                let r = CGRect(x: s.width * 0.5, y: 0, width: s.width * 0.5, height: s.height)
                c.fill(Path(r), with: .linearGradient(Gradient(colors: [Color(white: 0.26), Color(white: 0.12)]), startPoint: r.origin, endPoint: CGPoint(x: s.width, y: s.height)))
                c.stroke(line(CGPoint(x: r.minX, y: 0), CGPoint(x: r.minX, y: s.height)), with: .color(.white.opacity(0.14)), lineWidth: 0.8)
            case .outline:
                for i in 0..<7 {
                    let inset = Double(i) * min(s.width, s.height) * 0.045
                    let r = CGRect(x: s.width * 0.08 + inset, y: s.height * 0.07 + inset, width: s.width * 0.84 - inset * 2, height: s.height * 0.86 - inset * 2)
                    var geometry = Path(roundedRect: r, cornerRadius: min(r.width, r.height) * 0.08)
                    geometry = geometry.applying(CGAffineTransform(translationX: -s.width / 2, y: -s.height / 2).rotated(by: -0.09).translatedBy(x: s.width / 2, y: s.height / 2))
                    c.stroke(geometry, with: .color(.white.opacity(0.24 - Double(i) * 0.025)), lineWidth: 0.65)
                }
            case .dotMatrix:
                let spacing = max(16, s.width / 60)
                for row in 0...Int(s.height / spacing) {
                    for col in 0...Int(s.width / spacing) {
                        let x = Double(col) * spacing, y = Double(row) * spacing
                        let wave = (sin(Double(col) * 0.13) * cos(Double(row) * 0.18) + 1) / 2
                        let radius = 0.55 + wave * 1.1
                        c.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.06 + wave * 0.2)))
                    }
                }
            case .retroFilm:
                c.fill(bounds, with: .radialGradient(Gradient(colors: [Color(white: 0.18), Color(white: 0.075), .black]), center: CGPoint(x: s.width * 0.5, y: s.height * 0.4), startRadius: 0, endRadius: max(s.width, s.height) * 0.65))
                for i in 0..<9000 {
                    let x = noise(i * 2) * s.width, y = noise(i * 2 + 1) * s.height
                    c.fill(Path(CGRect(x: x, y: y, width: 0.5 + noise(i + 930) * 1.1, height: 0.8)), with: .color((i % 2 == 0 ? Color.white : Color.black).opacity(0.035 + noise(i + 50) * 0.10)))
                }
                for i in 0..<8 {
                    let x = noise(i + 125) * s.width
                    c.stroke(line(CGPoint(x: x, y: 0), CGPoint(x: x + 1, y: s.height)), with: .color(.white.opacity(0.025)), lineWidth: 0.4)
                }
            case .earth: earth(&c, s)
            case .minimalLines:
                for i in 0..<18 {
                    let offset = Double(i) * 0.021
                    var p = Path()
                    p.move(to: CGPoint(x: -20, y: s.height * (0.13 + offset)))
                    p.addCurve(to: CGPoint(x: s.width + 20, y: s.height * (0.72 + offset)), control1: CGPoint(x: s.width * 0.3, y: s.height * (-0.08 + offset)), control2: CGPoint(x: s.width * 0.58, y: s.height * (1.1 + offset)))
                    c.stroke(p, with: .color(.white.opacity(i % 4 == 0 ? 0.3 : 0.09)), lineWidth: i % 4 == 0 ? 0.75 : 0.4)
                }
            case .blackSilk:
                // Smooth folds: a variable centerline and asymmetric specular band for each ribbon.
                for i in 0..<15 {
                    var p = Path()
                    var q = Path()
                    for step in 0...90 {
                        let y = Double(step) / 90
                        let x = Double(i) / 14 + sin(y * 5.5 + Double(i) * 0.38) * 0.08 + sin(y * 11 + Double(i) * 0.22) * 0.02
                        let point = CGPoint(x: x * s.width, y: y * s.height)
                        if step == 0 { p.move(to: point); q.move(to: CGPoint(x: point.x + 6, y: point.y)) }
                        else { p.addLine(to: point); q.addLine(to: CGPoint(x: point.x + 6, y: point.y)) }
                    }
                    var glow = c; glow.addFilter(.blur(radius: s.width * 0.016))
                    glow.stroke(p, with: .color(Color(white: 0.16)), lineWidth: s.width * 0.043)
                    var shine = c; shine.addFilter(.blur(radius: s.width * 0.003))
                    shine.stroke(q, with: .linearGradient(Gradient(colors: [.white.opacity(0.03), .white.opacity(0.20), .white.opacity(0.04), .white.opacity(0.10)]), startPoint: .zero, endPoint: CGPoint(x: 0, y: s.height)), lineWidth: s.width * 0.006)
                }
            default: break
            }
            c.fill(bounds, with: .radialGradient(Gradient(colors: [.black.opacity(0.30), .clear, .black.opacity(0.28)]), center: CGPoint(x: s.width * 0.5, y: s.height * 0.5), startRadius: 0, endRadius: max(s.width, s.height) * 0.7))
        }
    }
    private func noise(_ i: Int) -> Double { let n = sin(Double(i) * 127.1 + 311.7) * 43758.5453; return n - floor(n) }
    private func line(_ a: CGPoint, _ b: CGPoint) -> Path { Path { $0.move(to: a); $0.addLine(to: b) } }
    private func earth(_ c: inout GraphicsContext, _ s: CGSize) {
        let d = min(s.width * 0.62, s.height * 0.90)
        let r = CGRect(x: s.width * 0.62 - d / 2, y: s.height * 0.53 - d / 2, width: d, height: d)
        let disk = Path(ellipseIn: r)
        var glow = c; glow.addFilter(.shadow(color: .white.opacity(0.18), radius: 10))
        glow.fill(disk, with: .color(Color(white: 0.10)))
        var globe = c; globe.clip(to: disk)
        // Original stylized continental outlines in normalized map coordinates, projected onto a sphere.
        let continents: [[CGPoint]] = [
            [CGPoint(x:0.10,y:0.19),CGPoint(x:0.24,y:0.10),CGPoint(x:0.38,y:0.20),CGPoint(x:0.35,y:0.33),CGPoint(x:0.27,y:0.41),CGPoint(x:0.30,y:0.50),CGPoint(x:0.21,y:0.42),CGPoint(x:0.12,y:0.31)],
            [CGPoint(x:0.31,y:0.49),CGPoint(x:0.42,y:0.54),CGPoint(x:0.44,y:0.64),CGPoint(x:0.35,y:0.83),CGPoint(x:0.30,y:0.74),CGPoint(x:0.28,y:0.58)],
            [CGPoint(x:0.55,y:0.24),CGPoint(x:0.65,y:0.16),CGPoint(x:0.85,y:0.17),CGPoint(x:0.97,y:0.31),CGPoint(x:0.90,y:0.45),CGPoint(x:0.78,y:0.47),CGPoint(x:0.71,y:0.38),CGPoint(x:0.65,y:0.35),CGPoint(x:0.62,y:0.44),CGPoint(x:0.52,y:0.33)],
            [CGPoint(x:0.54,y:0.39),CGPoint(x:0.68,y:0.40),CGPoint(x:0.72,y:0.54),CGPoint(x:0.62,y:0.73),CGPoint(x:0.53,y:0.63),CGPoint(x:0.48,y:0.49)],
            [CGPoint(x:0.82,y:0.67),CGPoint(x:0.95,y:0.65),CGPoint(x:0.98,y:0.78),CGPoint(x:0.85,y:0.81)]
        ]
        for points in continents {
            var p = Path()
            for (i, v) in points.enumerated() {
                let longitude = (v.x - 0.5) * .pi * 0.95, latitude = (v.y - 0.5) * .pi * 0.92
                let projected = CGPoint(x: r.midX + sin(longitude) * cos(latitude) * d / 2, y: r.midY + sin(latitude) * d / 2)
                if i == 0 { p.move(to: projected) } else { p.addLine(to: projected) }
            }
            p.closeSubpath()
            globe.fill(p, with: .color(Color(white: 0.29)))
            globe.stroke(p, with: .color(.white.opacity(0.07)), lineWidth: 0.8)
        }
        for i in 0..<44 {
            let y = r.minY + noise(i) * d
            var cloud = Path(); cloud.move(to: CGPoint(x: r.minX + noise(i + 88) * d * 0.6, y: y))
            cloud.addQuadCurve(to: CGPoint(x: r.maxX - noise(i + 89) * d * 0.3, y: y + d * 0.035), control: CGPoint(x: r.midX, y: y - d * 0.05))
            globe.stroke(cloud, with: .color(.white.opacity(0.055)), lineWidth: d * 0.012)
        }
        globe.fill(disk, with: .linearGradient(Gradient(colors: [.white.opacity(0.14), .clear, .black.opacity(0.98)]), startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.maxX * 0.97, y: r.midY)))
        c.stroke(disk, with: .color(.white.opacity(0.17)), lineWidth: 0.7)
    }
}
