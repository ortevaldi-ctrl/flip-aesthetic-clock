import SwiftUI
import AppKit

/// Monotonic inactivity deadline: repeated events at the same cursor position do not reset it.
struct ControlsDeadline {
    static let interval: TimeInterval = 3
    private(set) var lastMovement: TimeInterval
    private(set) var position: CGPoint?
    var panelOpen = false
    init(now: TimeInterval) { lastMovement = now }
    mutating func movement(to point: CGPoint, now: TimeInterval) -> Bool {
        guard point != position else { return false }
        position = point
        lastMovement = now
        return true
    }
    mutating func resetPosition() { position = nil }
    mutating func restart(now: TimeInterval) { lastMovement = now }
    func shouldHide(now: TimeInterval) -> Bool { !panelOpen && now - lastMovement >= Self.interval }
}

@MainActor final class ControlsActivity: ObservableObject {
    @Published private(set) var visible = true
    private var deadline = ControlsDeadline(now: ProcessInfo.processInfo.systemUptime)
    private var timer: Timer?
    private var monitor: Any?
    private var notifications: [NSObjectProtocol] = []
    private weak var window: NSWindow?
    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    func attach(to newWindow: NSWindow) {
        guard window !== newWindow else { return }
        stop()
        window = newWindow
        newWindow.acceptsMouseMovedEvents = true
        deadline.resetPosition()
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged, .otherMouseDragged]) { [weak self] event in
            MainActor.assumeIsolated {
                guard let self, let window = self.window,
                      event.window === window || event.window?.sheetParent === window else { return }
                let point = NSEvent.mouseLocation
                if self.deadline.movement(to: point, now: self.now), self.visible { self.reveal() }
            }
            return event
        }
        for name in [NSWindow.didEnterFullScreenNotification, NSWindow.didExitFullScreenNotification, NSWindow.didResignKeyNotification, NSWindow.didBecomeKeyNotification] {
            notifications.append(NotificationCenter.default.addObserver(forName: name, object: newWindow, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.restart() }
            })
        }
        restart()
    }
    func setPanelOpen(_ open: Bool, preservingHidden: Bool = false) {
        deadline.panelOpen = open
        if preservingHidden { timer?.invalidate(); timer = nil; return }
        restart()
    }
    func backgroundTap() {
        if !visible { restart(); return }
        timer?.invalidate(); timer = nil
        withAnimation(.easeOut(duration: 0.2)) { visible = false }
    }
    private func reveal() {
        NSCursor.setHiddenUntilMouseMoves(false)
        if !visible { withAnimation(.easeOut(duration: 0.2)) { visible = true } }
        schedule()
    }
    private func restart() {
        deadline.restart(now: now)
        reveal()
    }
    private func schedule() {
        timer?.invalidate()
        guard !deadline.panelOpen else { return }
        let remaining = max(0, ControlsDeadline.interval - (now - deadline.lastMovement))
        let timer = Timer(timeInterval: remaining, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.expire() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
    private func expire() {
        guard deadline.shouldHide(now: now) else { schedule(); return }
        withAnimation(.easeOut(duration: 0.4)) { visible = false }
        if let window, window.isKeyWindow, window.styleMask.contains(.fullScreen), window.attachedSheet == nil {
            NSCursor.setHiddenUntilMouseMoves(true)
        }
    }
    func stop() {
        timer?.invalidate(); timer = nil
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        notifications.forEach { NotificationCenter.default.removeObserver($0) }
        notifications = []
        NSCursor.setHiddenUntilMouseMoves(false)
        window = nil
    }
}

/// Connects to the actual owning window; never relies on NSApp.keyWindow to track another project.
struct ActivityWindowReader: NSViewRepresentable {
    let activity: ControlsActivity
    func makeNSView(context: Context) -> WindowProbe { WindowProbe(activity: activity) }
    func updateNSView(_ nsView: WindowProbe, context: Context) {}
    final class WindowProbe: NSView {
        let activity: ControlsActivity
        init(activity: ControlsActivity) { self.activity = activity; super.init(frame: .zero) }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            // Defer observable changes until SwiftUI finishes attaching the view.
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.window else { return }
                self.activity.attach(to: window)
            }
        }
    }
}
