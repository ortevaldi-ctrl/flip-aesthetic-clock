import SwiftUI

struct IOSCountdownView: View {
    @ObservedObject var controller: CountdownController
    let duration: Double
    let controlsVisible: Bool
    @Binding var isEditing: Bool
    let scale: Double
    @State private var editingFields: Set<String> = []
    @State private var hours = 0
    @State private var minutes = 5
    @State private var seconds = 0

    init(controller: CountdownController, duration: Double, scale: Double, controlsVisible: Bool, isEditing: Binding<Bool>) {
        self.controlsVisible = controlsVisible; self._isEditing = isEditing
        self.controller = controller; self.duration = duration; self.scale = scale
        let selected = Int(controller.state.duration)
        _hours = State(initialValue: selected / 3600)
        _minutes = State(initialValue: selected / 60 % 60)
        _seconds = State(initialValue: selected % 60)
    }
    var body: some View {
        GeometryReader { geometry in
            // Use the same full-screen space and scale as the clock, without
            // subtracting outer padding and then reserving that space again.
            let widthLimit = (geometry.size.width - 28) / 3
            let heightLimit = (geometry.size.height - 168) / 0.94
            let width = max(24, min(260, widthLimit, heightLimit)) * min(1, max(0.55, scale))
            let active = controller.state.phase == .running || controller.state.phase == .paused
            ZStack {
                if active {
                    VStack(spacing: 12) {
                        statusLabel
                        cards(width: width)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(alignment: .bottom) {
                            VStack(spacing: 8) {
                                actions
                                CountdownNotificationOption(notifications: controller.notifications)
                                    .excludesFLIPBackgroundTap()
                            }.padding(.bottom, 66)
                                .opacity(controlsVisible ? 1 : 0)
                                .allowsHitTesting(controlsVisible)
                                .accessibilityHidden(!controlsVisible)
                        }
                } else {
                    HStack(spacing: isEditing ? 0 : 20) {
                        let previewWidth = max(24, min(width, (geometry.size.width - 320) / 3))
                        VStack(spacing: 12) {
                            statusLabel
                            cards(width: controlsVisible ? previewWidth : width)
                        }.frame(maxWidth: isEditing ? 0 : .infinity)
                            .opacity(isEditing ? 0 : 1)
                            .accessibilityHidden(isEditing)
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(spacing: 8) {
                                    selection(landscape: true)
                                    actions
                                    CountdownNotificationOption(notifications: controller.notifications)
                                        .excludesFLIPBackgroundTap()
                                }.frame(maxWidth: .infinity)
                            }.scrollIndicators(.hidden)
                                .onChange(of: editingFields) { _, fields in
                                    if let field = fields.first {
                                        DispatchQueue.main.async { proxy.scrollTo(field, anchor: .top) }
                                    }
                                }
                        }.frame(width: isEditing ? nil : (controlsVisible ? 300 : 0))
                            .frame(maxWidth: isEditing ? .infinity : nil)
                            .opacity(controlsVisible ? 1 : 0)
                            .allowsHitTesting(controlsVisible)
                            .accessibilityHidden(!controlsVisible)
                    }.padding(.top, isEditing ? 0 : 80)
                        .padding(.bottom, isEditing ? 8 : 66)
                }
            }
        }
        .onChange(of: hours) { _, _ in configure() }
        .onChange(of: minutes) { _, _ in configure() }
        .onChange(of: seconds) { _, _ in configure() }
    }
    private var statusLabel: some View {
        Text(status).font(controller.state.phase == .finished ? .title2.bold() : .headline)
            .multilineTextAlignment(.center).accessibilityIdentifier("countdown.status")
    }
    private func cards(width: CGFloat) -> some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                VStack(spacing: 8) {
                    FlipCard(value: controller.values[index], width: width, duration: duration)
                    Text(["HORAS", "MINUTOS", "SEGUNDOS"][index]).font(.system(size: 9)).tracking(2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }.accessibilityElement(children: .ignore)
            .excludesFLIPBackgroundTap()
                        .accessibilityLabel("Tiempo restante: \(controller.values[0]) horas, \(controller.values[1]) minutos, \(controller.values[2]) segundos")
    }
    @ViewBuilder private func selection(landscape: Bool) -> some View {
        if controller.state.phase == .idle || controller.state.phase == .finished {
            HStack(spacing: 4) {
                durationPicker("Horas", selection: $hours, range: 0..<100)
                durationPicker("Minutos", selection: $minutes, range: 0..<60)
                durationPicker("Segundos", selection: $seconds, range: 0..<60)
            }.frame(height: landscape ? 88 : 115)
        }
    }
    private var status: String {
        switch controller.state.phase {
        case .idle: return "Temporizador"
        case .running: return "Cuenta atrás"
        case .paused: return "En pausa"
        case .finished: return "Tiempo terminado"
        }
    }
    private func durationPicker(_ title: String, selection: Binding<Int>, range: Range<Int>) -> some View {
        CountdownNumberInput(title: title, value: selection, maximum: range.upperBound - 1, isEditing: Binding(
            get: { editingFields.contains(title) },
            set: { focused in
                if focused { editingFields.insert(title) } else { editingFields.remove(title) }
                isEditing = !editingFields.isEmpty
            }))
            .id(title)
            .excludesFLIPBackgroundTap()
            .opacity(controlsVisible ? 1 : 0).allowsHitTesting(controlsVisible)
            .accessibilityHidden(!controlsVisible)
    }
    private var actions: some View {
        HStack(spacing: 12) {
            switch controller.state.phase {
            case .idle:
                action("Iniciar", icon: "play.fill") { configure(); controller.start() }
                    .disabled(hours * 3600 + minutes * 60 + seconds == 0)
            case .running: action("Pausar", icon: "pause.fill") { controller.pause() }
            case .paused: action("Reanudar", icon: "play.fill") { controller.resume() }
            case .finished: action("Iniciar", icon: "play.fill") { configure(); controller.start() }
                    .disabled(hours * 3600 + minutes * 60 + seconds == 0)
            }
            action("Reiniciar", icon: "arrow.counterclockwise") { controller.reset() }
        }
    }
    private func action(_ title: String, icon: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) { Label(title, systemImage: icon).frame(minWidth: 90, minHeight: 44) }
            .excludesFLIPBackgroundTap().buttonStyle(.bordered).tint(.white).accessibilityIdentifier("countdown.\(title)")
    }
    private func configure() { controller.configure(hours: hours, minutes: minutes, seconds: seconds) }
}

private struct CountdownNotificationOption: View {
    @ObservedObject var notifications: CountdownNotifications
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Avisar con el iPhone bloqueado", isOn: Binding(get: { notifications.enabled }, set: { notifications.setEnabled($0) }))
                .tint(Color(white: 0.45)).font(.subheadline)
                .accessibilityIdentifier("countdown.backgroundNotice")
            if notifications.requestingPermission { Text("Esperando permiso de notificaciones…").font(.caption).foregroundStyle(.secondary) }
            if let message = notifications.message {
                Text(message).font(.caption).foregroundStyle(.white.opacity(0.7)).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct CountdownNumberInput: View {
    let title: String
    @Binding var value: Int
    let maximum: Int
    @Binding var isEditing: Bool
    @State private var text = ""
    @FocusState private var focused: Bool
    var body: some View {
        VStack(spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            arrow("chevron.up", delta: 1)
            TextField(title, text: $text, prompt: Text("0"))
                .textFieldStyle(.plain).multilineTextAlignment(.center)
                .font(.system(size: 20, design: .rounded).monospacedDigit())
                .frame(width: 62).focused($focused)
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                .accessibilityLabel(title)
                .onChange(of: text) { _, new in
                    let digits = String(new.filter { $0.isASCII && $0.isNumber }.prefix(2))
                    let limited = digits.isEmpty ? "" : String(min(maximum, Int(digits) ?? 0))
                    if new != limited { text = limited }
                    value = Int(limited) ?? 0
                }
                .onSubmit { focused = false }
            arrow("chevron.down", delta: -1)
        }.onAppear { text = String(value) }
            .onChange(of: value) { _, new in if !focused { text = String(new) } }
            .onChange(of: focused) { _, new in
                isEditing = new
                if new {
                    value = 0
                    text = ""
                } else { text = String(value) }
            }
            .onDisappear { if focused { isEditing = false } }
            #if os(iOS)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if focused {
                        Spacer()
                        Button("Listo") { focused = false }
                    }
                }
            }
            #endif
    }
    private func arrow(_ symbol: String, delta: Int) -> some View {
        Button {
            value = min(maximum, max(0, value + delta))
            text = String(value)
        } label: {
            Image(systemName: symbol).font(.system(size: 10, weight: .semibold))
                .frame(width: 44, height: 24).contentShape(Rectangle())
        }.buttonStyle(.plain)
            .accessibilityLabel((delta > 0 ? "Sumar 1: " : "Restar 1: ") + title)
            .disabled(delta > 0 ? value >= maximum : value == 0)
    }
}
