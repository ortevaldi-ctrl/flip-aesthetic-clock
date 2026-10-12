import SwiftUI
import AppKit

@main struct Phase4AChecks {
    @MainActor static func main() throws {
        var deadline = ControlsDeadline(now: 100)
        precondition(!deadline.shouldHide(now: 102.999))
        precondition(deadline.shouldHide(now: 103))
        precondition(deadline.movement(to: CGPoint(x: 5, y: 5), now: 101))
        precondition(!deadline.movement(to: CGPoint(x: 5, y: 5), now: 102))
        precondition(deadline.shouldHide(now: 118))
        precondition(deadline.movement(to: CGPoint(x: 6, y: 5), now: 118))
        precondition(!deadline.shouldHide(now: 120.999))
        deadline.panelOpen = true
        precondition(!deadline.shouldHide(now: 1000))
        deadline.panelOpen = false; deadline.restart(now: 1000)
        precondition(!deadline.shouldHide(now: 1002.999))
        precondition(deadline.shouldHide(now: 1003))
        precondition(ClockStyle.allCases.count == 25)
        precondition(Set(ClockStyle.allCases.map(\.rawValue)).count == 25)
        let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("build/QA")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for (index, style) in ClockStyle.allCases.enumerated() {
            precondition(ClockStyle(rawValue: style.rawValue) == style)
            let artwork = ClockBackground(style: style, animated: false)
                .overlay(alignment: .bottomLeading) { Text(style.rawValue).font(.system(size: 18)).foregroundStyle(.white).padding(20) }
                .frame(width: 800, height: 500).environment(\.colorScheme, .dark)
            let renderer = ImageRenderer(content: artwork)
            guard let image = renderer.cgImage else { fatalError("Could not render \(style)") }
            let bitmap = NSBitmapImageRep(cgImage: image)
            guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("PNG encoding failed") }
            try png.write(to: directory.appendingPathComponent(String(format: "%02d", index + 1) + "-" + style.rawValue.replacingOccurrences(of: " ", with: "-") + ".png"))
            print("Rendered and round-tripped selection: \(style.rawValue)")
        }
        print("PASS: exact 3s deadline, stationary-event rejection, real movement reset, panel pause/resume, 25 unique styles and local renders")
    }
}
