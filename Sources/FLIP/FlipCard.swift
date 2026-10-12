import SwiftUI
#if os(macOS)
import AppKit
#endif

struct FlipCard: View {
    let value: String
    let width: CGFloat
    let duration: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var previous: String = ""
    @State private var displayed: String = ""
    @State private var angle = 0.0
    @State private var animating = false
    @State private var generation = UUID()
    private var height: CGFloat { width * 0.94 }

    private func half(_ text: String, top: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.065).fill(Color(white: top ? 0.095 : 0.12))
            Text(text).font(.system(size: width * 0.70, weight: .semibold, design: .rounded)).monospacedDigit()
                .foregroundStyle(.white).minimumScaleFactor(0.5)
        }
        .frame(width: width, height: height)
        .offset(y: top ? height / 4 : -height / 4)
        .frame(width: width, height: height / 2).clipped()
    }
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                half(animating ? value : displayed, top: true)
                half(animating ? previous : displayed, top: false)
            }
            if animating {
                TurningLeaf(previous: previous, next: value, width: width, angle: angle)
            }
            Rectangle().fill(.black.opacity(0.8)).frame(height: 2)
            HStack { hinge; Spacer(); hinge }.padding(.horizontal, 5)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: width * 0.065))
        .overlay(RoundedRectangle(cornerRadius: width * 0.065).stroke(.white.opacity(0.09), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 18, y: 12)
        .onAppear { displayed = value; previous = value }
        .onChange(of: value) { old, new in
            let token = UUID(); generation = token
            previous = old; displayed = new; angle = 0
            #if os(macOS)
            let shouldReduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
            #else
            let shouldReduceMotion = reduceMotion
            #endif
            guard !shouldReduceMotion else { animating = false; return }
            animating = true
            withAnimation(.linear(duration: duration)) { angle = 180 }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration))
                if generation == token { animating = false }
            }
        }
        .accessibilityLabel(value)
    }
    private var hinge: some View { RoundedRectangle(cornerRadius: 2).fill(Color(white: 0.3)).frame(width: 4, height: 13) }
}

private struct TurningLeaf: View, Animatable {
    let previous: String
    let next: String
    let width: CGFloat
    var angle: Double
    var animatableData: Double { get { angle } set { angle = newValue } }
    private var height: CGFloat { width * 0.94 }
    var body: some View {
        let top = angle < 90
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.065).fill(Color(white: top ? 0.095 : 0.12))
            Text(top ? previous : next).font(.system(size: width * 0.70, weight: .semibold, design: .rounded)).monospacedDigit().foregroundStyle(.white)
        }
        .frame(width: width, height: height)
        .offset(y: top ? height / 4 : -height / 4)
        .frame(width: width, height: height / 2).clipped()
        .overlay(Color.black.opacity(top ? 0.5 * angle / 90 : 0.45 * (180 - angle) / 90))
        .rotation3DEffect(.degrees(top ? -angle : 180 - angle), axis: (x: 1, y: 0, z: 0), anchor: top ? .bottom : .top, perspective: 0.45)
        .offset(y: top ? -height / 4 : height / 4)
    }
}

/// Only actual clock/control content excludes background taps; surrounding layout space does not.
struct FLIPTapExclusions: PreferenceKey {
    static var defaultValue: [CGRect] { [] }
    static func reduce(value: inout [CGRect], nextValue: () -> [CGRect]) { value += nextValue() }
}
extension View {
    func excludesFLIPBackgroundTap() -> some View {
        background(GeometryReader { geometry in
            Color.clear.preference(key: FLIPTapExclusions.self,
                value: [geometry.frame(in: .named("flipScreen"))])
        })
    }
}
