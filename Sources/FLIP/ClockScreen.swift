import SwiftUI
import AppKit

struct ClockScreen: View {
    let countdown: CountdownController
    @State private var tapExclusions: [CGRect] = []
    @State private var isEditingTime = false
    @State private var timerMode = false
    @StateObject private var visibility = WindowVisibility()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("style") private var styleName = ClockStyle.minimalBlack.rawValue
    @AppStorage("twelveHour") private var twelveHour = false
    @AppStorage("seconds") private var seconds = true
    @AppStorage("date") private var showDate = true
    @AppStorage("ambient") private var ambient = true
    @AppStorage("size") private var scale = 1.0
    @AppStorage("duration") private var duration = 0.55
    @StateObject private var activity = ControlsActivity()
    @State private var gallery = false
    @State private var settings = false
    private var style: ClockStyle { ClockStyle(rawValue: styleName) ?? .minimalBlack }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ClockBackground(style: style, animated: ambient && visibility.canRender && !reduceMotion)
                    .id(style).transition(.opacity).animation(.easeInOut(duration: 0.6), value: style)
                if timerMode {
                    if countdown.state.phase == .running || countdown.state.phase == .paused {
                        ZStack {
                            MacCountdownView(controller: countdown, scale: scale, duration: duration, controlsVisible: activity.visible, isEditing: $isEditingTime)
                                .padding(.vertical, 88).padding(.horizontal, 24)
                            VStack {
                                header
                                modePicker
                                Spacer()
                                toolbar
                            }.padding(24)
                                .opacity(activity.visible ? 1 : 0).allowsHitTesting(activity.visible).accessibilityHidden(!activity.visible)
                        }
                    } else {
                    VStack(spacing: 14) {
                        header.opacity(activity.visible ? 1 : 0)
                        modePicker.opacity(activity.visible ? 1 : 0).allowsHitTesting(activity.visible).accessibilityHidden(!activity.visible)
                        MacCountdownView(controller: countdown, scale: scale, duration: duration, controlsVisible: activity.visible, isEditing: $isEditingTime)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        toolbar.opacity(activity.visible ? 1 : 0).allowsHitTesting(activity.visible).accessibilityHidden(!activity.visible)
                    }.padding(24)
                    }
                } else {
                    ClockFace(size: geometry.size, twelveHour: twelveHour, seconds: seconds, showDate: showDate, scale: scale, duration: duration, visibility: visibility)
                    VStack {
                        header.padding(30)
                        modePicker
                        Spacer()
                        toolbar.padding(.bottom, 25)
                    }.opacity(activity.visible ? 1 : 0).allowsHitTesting(activity.visible).accessibilityHidden(!activity.visible)
                    VStack { Spacer(); MacCountdownCompletionBanner(controller: countdown).padding(.bottom, 100) }
                }
            }.coordinateSpace(name: "flipScreen")
                .onPreferenceChange(FLIPTapExclusions.self) { tapExclusions = $0 }
                .simultaneousGesture(SpatialTapGesture().onEnded { event in
                    guard !gallery, !settings else { return }
                    if !activity.visible || !tapExclusions.contains(where: { $0.contains(event.location) }) {
                        if activity.visible && isEditingTime { NSApp.keyWindow?.makeFirstResponder(nil) }
                        activity.backgroundTap()
                    }
                })
                .foregroundStyle(.white).preferredColorScheme(.dark)
                .background(ActivityWindowReader(activity: activity).frame(width: 0, height: 0))
                .onChange(of: gallery || settings || isEditingTime) { _, open in activity.setPanelOpen(open, preservingHidden: !activity.visible && !gallery && !settings) }
                .background(VisibilityWindowReader(visibility: visibility).frame(width: 0, height: 0))
                .onChange(of: timerMode) { _, _ in activity.setPanelOpen(gallery || settings || isEditingTime) }
                .onDisappear { activity.stop(); visibility.stop() }
                .onExitCommand { if let window = NSApp.keyWindow, window.styleMask.contains(.fullScreen) { window.toggleFullScreen(nil) } }
                .sheet(isPresented: $gallery) { galleryView }
                .sheet(isPresented: $settings) { preferences }
        }
    }
    private var header: some View {
        HStack {
            Text("FLIP").font(.system(size: 13, weight: .semibold)).tracking(5)
            Spacer()
            Text(style.rawValue).font(.caption).foregroundStyle(.secondary)
        }
    }
    private var modePicker: some View {
        Picker("Modo", selection: $timerMode) {
            Text("Reloj").tag(false)
            Text("Temporizador").tag(true)
        }.excludesFLIPBackgroundTap().pickerStyle(.segmented).frame(width: 260).accessibilityIdentifier("flip.mode")
    }
    private var toolbar: some View {
        HStack(spacing: 24) {
            Button { gallery = true } label: { Label("Fondos", systemImage: "square.grid.2x2") }.keyboardShortcut("b", modifiers: .command)
            Button { settings = true } label: { Label("Personalizar", systemImage: "slider.horizontal.3") }.keyboardShortcut(",", modifiers: .command)
            Button { NSApp.keyWindow?.toggleFullScreen(nil) } label: { Label("Pantalla completa", systemImage: "arrow.up.left.and.arrow.down.right") }.keyboardShortcut("f", modifiers: [.command, .control])
        }.excludesFLIPBackgroundTap().buttonStyle(.plain).font(.system(size: 12)).padding(18).background(.ultraThinMaterial, in: Capsule())
    }
    private var galleryView: some View { BackgroundGallery(styleName: $styleName, isPresented: $gallery) }
    private var preferences: some View {
        ClockPreferences(twelveHour: $twelveHour, seconds: $seconds, showDate: $showDate, ambient: $ambient, scale: $scale, duration: $duration, isPresented: $settings)
    }
}
