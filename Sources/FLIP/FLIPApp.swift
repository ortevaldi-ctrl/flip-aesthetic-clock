import SwiftUI
import AppKit

@main
@MainActor
struct FLIPApp: App {
    @StateObject private var countdownSession = MacCountdownSession()
    var body: some Scene {
        WindowGroup("FLIP — Aesthetic Clock") { ClockScreen(countdown: countdownSession.controller).frame(minWidth: 640, minHeight: 440).onAppear { countdownSession.start() }.onOpenURL { url in
            if FLIPWidgetLink.accepts(url) { NSApp.activate(ignoringOtherApps: true) }
        } }
            .defaultSize(width: 1100, height: 720)
            .windowStyle(.hiddenTitleBar)
            .handlesExternalEvents(matching: ["*"])
        Settings { Text("Las opciones están disponibles en la barra del reloj.").padding(30) }
    }
}
