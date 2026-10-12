import SwiftUI
import AppKit

@MainActor final class WindowVisibility: ObservableObject {
    @Published private(set) var canRender = true
    private weak var window: NSWindow?
    private var observers: [NSObjectProtocol] = []
    func attach(_ window: NSWindow) {
        guard self.window !== window else { return }
        stop()
        self.window = window
        for name in [NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification, NSWindow.didDeminiaturizeNotification, NSWindow.willCloseNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            })
        }
        for name in [NSApplication.didHideNotification, NSApplication.didUnhideNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            })
        }
        refresh()
    }
    private func refresh() {
        guard let window else { return }
        let visible = window.isVisible && !window.isMiniaturized && window.occlusionState.contains(.visible) && !NSApp.isHidden
        if canRender != visible { canRender = visible }
    }
    func stop() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers = []; window = nil
    }
}
struct VisibilityWindowReader: NSViewRepresentable {
    let visibility: WindowVisibility
    func makeNSView(context: Context) -> Probe { Probe(visibility) }
    func updateNSView(_ view: Probe, context: Context) {}
    final class Probe: NSView {
        let visibility: WindowVisibility
        init(_ visibility: WindowVisibility) { self.visibility = visibility; super.init(frame: .zero) }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            // Window attachment can occur inside a SwiftUI update transaction.
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.window else { return }
                self.visibility.attach(window)
            }
        }
    }
}
