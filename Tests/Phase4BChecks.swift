import SwiftUI
import AppKit
import Combine

final class MemoryDefaults: UserDefaults, @unchecked Sendable {
    var values: [String: Any] = [:]
    override func array(forKey key: String) -> [Any]? { values[key] as? [Any] }
    override func string(forKey key: String) -> String? { values[key] as? String }
    override func set(_ value: Any?, forKey key: String) { values[key] = value }
}
@main struct Phase4BChecks {
    @MainActor static func main() throws {
        let defaults = MemoryDefaults()
        defaults.values = ["favorites": ["Minimal Black", "Unreleased Style"], "style": "Frosted Glass", "twelveHour": true]
        let store = FavoritesStore(defaults: defaults)
        store.toggle(.earth)
        precondition(store.contains(.earth))
        let reload = FavoritesStore(defaults: defaults)
        precondition(reload.contains(.earth) && reload.contains(.minimalBlack))
        precondition(reload.names.contains("Unreleased Style"))
        reload.toggle(.earth)
        precondition(!FavoritesStore(defaults: defaults).contains(.earth))
        precondition(defaults.values["style"] as? String == "Frosted Glass")
        precondition(defaults.values["twelveHour"] as? Bool == true)
        let legacy = MemoryDefaults(); legacy.values["favorites"] = "[\"Moon\"]"
        precondition(FavoritesStore(defaults: legacy).contains(.moon))

        let engine = TimeEngine()
        engine.setRunning(false)
        let paused = engine.date
        RunLoop.main.run(until: Date().addingTimeInterval(1.2))
        precondition(engine.date == paused, "Hidden clock should not publish time updates")
        engine.setRunning(true)
        precondition(abs(engine.date.timeIntervalSinceNow) < 0.1, "Resume should immediately resync wall time")
        engine.setRunning(false)
        print("PASS: favorites add/remove/reload, legacy data, unknown favorites preservation, unrelated preferences, hidden-clock pause and wall-time resync")

        let icon = NSImage(contentsOfFile: "Resources/FLIP.icns")
        precondition(icon != nil && icon!.isValid, "Native ImageIO/AppKit must decode the ICNS")
        let master = NSBitmapImageRep(data: try Data(contentsOf: URL(fileURLWithPath: "Resources/FLIP-master-1024.png")))!
        precondition(master.pixelsWide == 1024 && master.pixelsHigh == 1024)
        print("PASS: valid native ICNS and 1024 × 1024 master")
    }
}
