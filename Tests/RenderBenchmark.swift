import SwiftUI
import AppKit

@main struct RenderBenchmark {
    @MainActor static func main() {
        let started = ProcessInfo.processInfo.systemUptime
        var slowest = (name: "", seconds: 0.0)
        for style in ClockStyle.allCases {
            let start = ProcessInfo.processInfo.systemUptime
            let image = ImageRenderer(content: ClockBackground(style: style, animated: false).frame(width: 1100, height: 720)).cgImage
            precondition(image != nil)
            let elapsed = ProcessInfo.processInfo.systemUptime - start
            if elapsed > slowest.seconds { slowest = (style.rawValue, elapsed) }
            print(String(format: "%-22@ %.3f s", style.rawValue as NSString, elapsed))
        }
        print(String(format: "25 static renders at 1100×720: %.3f s; slowest %@ %.3f s", ProcessInfo.processInfo.systemUptime - started, slowest.name, slowest.seconds))
        print("This is an offscreen rendering check, not a live CPU/GPU or energy measurement.")
    }
}
