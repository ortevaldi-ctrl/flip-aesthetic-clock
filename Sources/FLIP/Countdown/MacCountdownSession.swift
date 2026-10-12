import AppKit
import Combine

/// One countdown per app, shared by all clock windows. Hidden windows pause UI work, not wall time.
@MainActor final class MacCountdownSession: ObservableObject {
    let controller: CountdownController
    private var observers: [NSObjectProtocol] = []
    private var workspaceObservers: [NSObjectProtocol] = []
    private let notifications: NotificationCenter
    private let workspace: NotificationCenter
    private let isVisible: () -> Bool
    private var started = false
    private var sleeping = false
    init(controller: CountdownController? = nil, notifications: NotificationCenter = .default,
         workspace: NotificationCenter? = nil, isVisible: (() -> Bool)? = nil) {
        self.controller = controller ?? .macLive()
        self.notifications = notifications
        self.workspace = workspace ?? NSWorkspace.shared.notificationCenter
        self.isVisible = isVisible ?? {
            !NSApp.isHidden && NSApp.windows.contains { $0.isVisible && !$0.isMiniaturized && $0.occlusionState.contains(.visible) }
        }
    }
    func start() {
        guard !started else { return }
        started = true
        for name in [NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification,
                     NSWindow.didDeminiaturizeNotification, NSWindow.willCloseNotification,
                     NSApplication.didHideNotification, NSApplication.didUnhideNotification,
                     NSApplication.didBecomeActiveNotification] {
            observers.append(notifications.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.updateVisibility() }
            })
        }
        observers.append(notifications.addObserver(forName: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.updateVisibility() }
        })
        workspaceObservers.append(workspace.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.sleeping = true; self?.controller.setActive(false) }
        })
        workspaceObservers.append(workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.sleeping = false; self?.updateVisibility() }
        })
        updateVisibility()
    }
    private func updateVisibility() {
        let visible = !sleeping && isVisible()
        controller.setActive(visible)
    }
    func stop() {
        controller.setActive(false)
        observers.forEach { notifications.removeObserver($0) }
        workspaceObservers.forEach { workspace.removeObserver($0) }
        observers = []; workspaceObservers = []; started = false
    }
}
