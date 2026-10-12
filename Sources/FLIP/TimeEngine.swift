import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import Combine

@MainActor final class TimeEngine: ObservableObject {
    @Published var date = Date()
    private var running = true
    private var showsSeconds = true
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    init() {
        scheduleTick()
        #if os(macOS)
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.timer?.invalidate(); self?.refresh(); self?.scheduleTick() }
        })
        #else
        observers.append(NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.timer?.invalidate(); self?.refresh(); self?.scheduleTick() }
        })
        #endif
        observers.append(NotificationCenter.default.addObserver(forName: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.date = Date() }
        })
    }
    #if os(iOS)
    deinit {
        timer?.invalidate()
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
    #endif
    func setRunning(_ value: Bool) {
        guard running != value else { return }
        running = value
        timer?.invalidate()
        if value { date = Date(); scheduleTick() }
    }
    func setShowsSeconds(_ value: Bool) {
        guard showsSeconds != value else { return }
        showsSeconds = value; timer?.invalidate(); date = Date(); scheduleTick()
    }
    private func scheduleTick() {
        guard running else { return }
        let now = Date()
        let interval: TimeInterval = showsSeconds ? 1 : 60
        let delay = interval - now.timeIntervalSince1970.truncatingRemainder(dividingBy: interval) + 0.002
        let next = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
                self?.scheduleTick()
            }
        }
        RunLoop.main.add(next, forMode: .common)
        timer = next
    }
    private func refresh() {
        let now = Date()
        if Int(now.timeIntervalSince1970) != Int(date.timeIntervalSince1970) { date = now }
    }
}

enum ClockValues {
    static func values(at date: Date, twelveHour: Bool, calendar: Calendar = .autoupdatingCurrent) -> [String] {
        let parts = calendar.dateComponents([.hour, .minute, .second], from: date)
        let hour = parts.hour ?? 0
        return [twelveHour ? (hour % 12 == 0 ? 12 : hour % 12) : hour, parts.minute ?? 0, parts.second ?? 0].map { String(format: "%02d", $0) }
    }
}
