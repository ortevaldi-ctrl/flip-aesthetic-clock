import SwiftUI

struct IOSClockScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("style") private var styleName = ClockStyle.minimalBlack.rawValue
    @AppStorage("twelveHour") private var twelveHour = false
    @AppStorage("seconds") private var seconds = true
    @AppStorage("date") private var showDate = true
    @AppStorage("ambient") private var ambient = true
    @AppStorage("size") private var scale = 1.0
    @AppStorage("duration") private var duration = 0.55
    @StateObject private var countdown = CountdownController.live()
    @State private var tapExclusions: [CGRect] = []
    @State private var isEditingTime = false
    @State private var timerMode = false
    @State private var gallery = false
    @State private var settings = false
    @State private var controlsVisible = true
    @State private var interaction = 0
    private var style: ClockStyle { ClockStyle(rawValue: styleName) ?? .minimalBlack }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ClockBackground(style: style, animated: ambient && scenePhase == .active && !reduceMotion)
                    .ignoresSafeArea()
                if timerMode {
                    ZStack {
                        IOSCountdownView(controller: countdown, duration: duration, scale: scale, controlsVisible: controlsVisible, isEditing: $isEditingTime)
                            .padding(.horizontal, 20)
                        VStack {
                            header
                            modePicker
                            Spacer()
                            toolbar
                        }.padding(20)
                            .opacity(controlsVisible && !isEditingTime ? 1 : 0)
                            .allowsHitTesting(controlsVisible && !isEditingTime)
                            .accessibilityHidden(!controlsVisible || isEditingTime)
                    }
                } else {
                    IOSClockFace(size: geometry.size, twelveHour: twelveHour, seconds: seconds,
                                 showDate: showDate, scale: scale, duration: duration,
                                 running: scenePhase == .active)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack {
                        header.opacity(controlsVisible ? 1 : 0)
                        modePicker.opacity(controlsVisible ? 1 : 0).allowsHitTesting(controlsVisible).accessibilityHidden(!controlsVisible)
                        Spacer()
                        toolbar
                    }.padding(20)
                        .opacity(controlsVisible ? 1 : 0)
                        .allowsHitTesting(controlsVisible)
                        .accessibilityHidden(!controlsVisible)
                }
            }.overlay(alignment: .bottom) {
                if !timerMode && countdown.state.phase == .finished {
                    Text("Tiempo terminado").font(.headline).padding(16)
                        .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
                        .padding(.bottom, 105).accessibilityIdentifier("countdown.clockCompletion")
                }
            }.coordinateSpace(name: "flipScreen")
                .onPreferenceChange(FLIPTapExclusions.self) { tapExclusions = $0 }
                .simultaneousGesture(SpatialTapGesture().onEnded { event in
                    guard !gallery, !settings else { return }
                    if countdown.state.phase == .finished {
                        countdown.reset()
                        revealControls()
                        return
                    }
                    if !controlsVisible { revealControls(); return }
                    guard !tapExclusions.contains(where: { $0.contains(event.location) }) else {
                        interaction += 1
                        return
                    }
                    withAnimation(.easeOut(duration: 0.2)) { controlsVisible = false }
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                })
        }.foregroundStyle(.white).preferredColorScheme(.dark)
            .task(id: interaction) {
                guard scenePhase == .active, !gallery, !settings, !isEditingTime else { return }
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                withAnimation(.easeOut(duration: 0.4)) { controlsVisible = false }
            }
            .onChange(of: gallery || settings) { _, _ in revealControls() }
            .onChange(of: isEditingTime) { _, _ in if controlsVisible { revealControls() } }
            .onAppear { countdown.setActive(scenePhase == .active) }
            .onChange(of: timerMode) { _, _ in revealControls() }
            .onChange(of: scenePhase) { _, phase in
                countdown.setActive(phase == .active)
                revealControls()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                countdown.setActive(scenePhase == .active)
            }
            .sheet(isPresented: $gallery) {
                BackgroundGallery(styleName: $styleName, isPresented: $gallery)
            }
            .sheet(isPresented: $settings) {
                ClockPreferences(twelveHour: $twelveHour, seconds: $seconds, showDate: $showDate,
                                 ambient: $ambient, scale: $scale, duration: $duration, isPresented: $settings)
            }
    }
    private var header: some View {
        HStack {
            Text("FLIP").font(.caption.weight(.semibold)).tracking(5)
            Spacer()
            Text(style.rawValue).font(.caption).foregroundStyle(.secondary)
        }
    }
    private var modePicker: some View {
        Picker("Modo", selection: $timerMode) {
            Text("Reloj").tag(false)
            Text("Temporizador").tag(true)
        }.excludesFLIPBackgroundTap().pickerStyle(.segmented).accessibilityIdentifier("flip.mode")
    }
    private var toolbar: some View {
        HStack(spacing: 24) {
            Button { gallery = true } label: { Label("Fondos", systemImage: "square.grid.2x2") }
            Button { settings = true } label: { Label("Ajustes", systemImage: "slider.horizontal.3") }
        }.excludesFLIPBackgroundTap().font(.subheadline).buttonStyle(.plain).padding(18)
            .background(.ultraThinMaterial, in: Capsule())
    }
    private func revealControls() {
        withAnimation(.easeOut(duration: 0.2)) { controlsVisible = true }
        interaction += 1
    }
}

/// In portrait, hours/minutes share a row and seconds sit below; landscape uses one row.
private struct IOSClockFace: View {
    let size: CGSize
    let twelveHour: Bool
    let seconds: Bool
    let showDate: Bool
    let scale: Double
    let duration: Double
    let running: Bool
    @StateObject private var time = TimeEngine()

    var body: some View {
        let landscape = size.width > size.height
        let columns = landscape && seconds ? 3 : 2
        let rows = !landscape && seconds ? 2 : 1
        let spacing: CGFloat = landscape ? 14 : 16
        let widthLimit = (size.width - 40 - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        let reservedHeight: CGFloat = 140 + (showDate ? 44 : 0) + (twelveHour ? 24 : 0)
        let heightLimit = ((size.height - reservedHeight) / CGFloat(rows) - 28) / 0.94
        let width = max(24, min(260, widthLimit, heightLimit)) * min(1, max(0.55, scale))
        let values = ClockValues.values(at: time.date, twelveHour: twelveHour)
        VStack(spacing: landscape ? 12 : 24) {
            HStack(spacing: spacing) {
                unit(values[0], label: "HORAS", width: width)
                unit(values[1], label: "MINUTOS", width: width)
                if landscape && seconds { unit(values[2], label: "SEGUNDOS", width: width) }
            }
            if !landscape && seconds { unit(values[2], label: "SEGUNDOS", width: width) }
            if showDate {
                Text(time.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                    .font(.system(size: 13, weight: .light)).foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }
            if twelveHour {
                Text(Calendar.autoupdatingCurrent.component(.hour, from: time.date) < 12 ? "AM" : "PM")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .excludesFLIPBackgroundTap()
        .onAppear { time.setShowsSeconds(seconds); time.setRunning(running) }
        .onChange(of: seconds) { _, value in time.setShowsSeconds(value) }
        .onChange(of: running) { _, value in time.setRunning(value) }
        .onDisappear { time.setRunning(false) }
    }
    private func unit(_ value: String, label: String, width: CGFloat) -> some View {
        VStack(spacing: 10) {
            FlipCard(value: value, width: width, duration: duration)
            Text(label).font(.system(size: 9, weight: .medium)).tracking(2)
                .foregroundStyle(.white.opacity(0.45))
        }.accessibilityElement(children: .ignore).accessibilityLabel("\(label): \(value)")
    }
}
