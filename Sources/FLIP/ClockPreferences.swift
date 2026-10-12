import SwiftUI

struct ClockPreferences: View {
    @Binding var twelveHour: Bool
    @Binding var seconds: Bool
    @Binding var showDate: Bool
    @Binding var ambient: Bool
    @Binding var scale: Double
    @Binding var duration: Double
    @Binding var isPresented: Bool
    var body: some View {
        VStack {
            HStack { Text("Personalización").font(.title2); Spacer(); Button("Cerrar") { isPresented = false } }
            Form {
                Toggle("Formato de 12 horas", isOn: $twelveHour)
                Toggle("Mostrar segundos", isOn: $seconds)
                Toggle("Mostrar fecha", isOn: $showDate)
                Toggle("Animaciones ambientales", isOn: $ambient)
                LabeledContent("Tamaño") { Slider(value: $scale, in: 0.55...1) }
                LabeledContent("Duración del giro") { Slider(value: $duration, in: 0.25...0.85) }
            }.formStyle(.grouped)
        }.padding(25)
        #if os(macOS)
        .frame(width: 460, height: 380)
        #endif
        .preferredColorScheme(.dark)
    }
}
