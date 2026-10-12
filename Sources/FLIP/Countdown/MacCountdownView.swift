import SwiftUI

struct MacCountdownView: View {
    @ObservedObject var controller: CountdownController
    let controlsVisible: Bool
    @Binding var isEditing: Bool
    let scale: Double
    let duration: Double
    @State private var editingFields: Set<String> = []
    @State private var hours: Int
    @State private var minutes: Int
    @State private var seconds: Int
    init(controller: CountdownController, scale: Double, duration: Double, controlsVisible: Bool, isEditing: Binding<Bool>) {
        self.controlsVisible = controlsVisible; self._isEditing = isEditing
        self.controller = controller; self.scale = scale; self.duration = duration
        let selected = Int(controller.state.duration)
        _hours = State(initialValue: selected / 3600)
        _minutes = State(initialValue: selected / 60 % 60)
        _seconds = State(initialValue: selected % 60)
    }
    var body: some View {
        GeometryReader { geometry in
            let width = max(50, min(230, (geometry.size.width - 36) / 3,
                                    max(50, geometry.size.height - 175) / 0.94)) * min(1, max(0.55, scale))
            if controller.state.phase == .running || controller.state.phase == .paused {
                VStack(spacing: 14) {
                    Text(status).font(.headline).accessibilityIdentifier("countdown.status")
                    cards(width: width)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 12) {
                            actions
                            MacCountdownNotificationOption(notifications: controller.notifications).excludesFLIPBackgroundTap()
                                .opacity(controlsVisible ? 1 : 0).allowsHitTesting(controlsVisible).accessibilityHidden(!controlsVisible)
                        }.padding(.bottom, 8)
                    }
            } else {
            ScrollView {
                VStack(spacing: 14) {
                    Text(status).font(controller.state.phase == .finished ? .title2.bold() : .headline)
                        .accessibilityIdentifier("countdown.status")
                    cards(width: width)
                    if controller.state.phase == .idle || controller.state.phase == .finished {
                        HStack(spacing: 20) {
                            durationPicker("Horas", selection: $hours, range: 0..<100)
                            durationPicker("Minutos", selection: $minutes, range: 0..<60)
                            durationPicker("Segundos", selection: $seconds, range: 0..<60)
                        }
                    }
                    actions
                    MacCountdownNotificationOption(notifications: controller.notifications).excludesFLIPBackgroundTap()
                        .opacity(controlsVisible ? 1 : 0).allowsHitTesting(controlsVisible).accessibilityHidden(!controlsVisible)
                }.frame(maxWidth: .infinity).padding(.vertical, 8)
            }.scrollIndicators(.hidden)
            }
        }
        .onChange(of: hours) { _, _ in configure() }
        .onChange(of: minutes) { _, _ in configure() }
        .onChange(of: seconds) { _, _ in configure() }
    }
    private func cards(width: CGFloat) -> some View {
                    HStack(spacing: 18) {
                        ForEach(0..<3, id: \.self) { index in
                            VStack(spacing: 10) {
                                FlipCard(value: controller.values[index], width: width, duration: duration)
                                Text(["HORAS", "MINUTOS", "SEGUNDOS"][index]).font(.system(size: 10, weight: .medium)).tracking(3)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }.accessibilityElement(children: .ignore)
                        .excludesFLIPBackgroundTap()
                        .accessibilityLabel("Tiempo restante: \(controller.values[0]) horas, \(controller.values[1]) minutos, \(controller.values[2]) segundos")
    }
    private var actions: some View {
                    HStack(spacing: 14) {
                        switch controller.state.phase {
                        case .idle, .finished:
                            action("Iniciar", symbol: "play.fill") { configure(); controller.start() }
                                .disabled(hours * 3600 + minutes * 60 + seconds == 0)
                        case .running: action("Pausar", symbol: "pause.fill") { controller.pause() }
                        case .paused: action("Reanudar", symbol: "play.fill") { controller.resume() }
                        }
                        action("Reiniciar", symbol: "arrow.counterclockwise") { controller.reset() }
                    }.opacity(controlsVisible ? 1 : 0).allowsHitTesting(controlsVisible).accessibilityHidden(!controlsVisible)
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
            .excludesFLIPBackgroundTap()
            .opacity(controlsVisible ? 1 : 0).allowsHitTesting(controlsVisible)
            .accessibilityHidden(!controlsVisible)
    }
    private func action(_ title: String, symbol: String, perform: @escaping () -> Void) -> some View {
        Button(action: perform) { Label(title, systemImage: symbol).frame(minWidth: 100, minHeight: 30) }
            .excludesFLIPBackgroundTap().buttonStyle(.bordered).tint(.white).accessibilityIdentifier("countdown.\(title)")
    }
    private func configure() { controller.configure(hours: hours, minutes: minutes, seconds: seconds) }
}
private struct MacCountdownNotificationOption: View {
    @ObservedObject var notifications: CountdownNotifications
    var body: some View {
        VStack(spacing: 7) {
            Toggle("Aviso del sistema cuando FLIP esté oculta", isOn: Binding(get: { notifications.enabled }, set: { notifications.setEnabled($0) }))
                .toggleStyle(.checkbox).accessibilityIdentifier("countdown.backgroundNotice")
            if notifications.requestingPermission { Text("Esperando permiso de notificaciones…").font(.caption).foregroundStyle(.secondary) }
            if let message = notifications.message {
                Text(message).font(.caption).multilineTextAlignment(.center).foregroundStyle(.white.opacity(0.7))
            }
        }.frame(maxWidth: 500)
    }
}
struct MacCountdownCompletionBanner: View {
    @ObservedObject var controller: CountdownController
    var body: some View {
        if controller.state.phase == .finished {
            Text("Tiempo terminado").font(.headline).padding(16)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityIdentifier("countdown.clockCompletion")
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
            TextField(title, text: $text)
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
                if !new { text = String(value) }
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
