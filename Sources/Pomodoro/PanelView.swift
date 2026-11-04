import SwiftUI

private let orange = Color(nsColor: PillRenderer.orange)
private let darkAmber = Color(nsColor: PillRenderer.darkAmber)
private let tile = Color(white: 0.17)
private let unlit = Color(white: 0.23)

struct PanelView: View {
    @ObservedObject var model: TimerModel
    @State private var openAtLogin = LoginItem.isEnabled

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                TickRing(fraction: model.fractionLeft)
                VStack(spacing: 4) {
                    Text(formatClock(model.remaining))
                        .font(.system(size: 40, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white)
                    Text(statusLine)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 200, height: 200)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(TimerModel.presets, id: \.self) { m in
                    Button { model.select(m) } label: {
                        VStack(spacing: 0) {
                            Text("\(m)").font(.system(size: 16, weight: .semibold))
                            Text("min").font(.system(size: 10))
                                .foregroundStyle(m == model.minutes ? darkAmber.opacity(0.8) : .secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(m == model.minutes ? darkAmber : .white)
                        .background(m == model.minutes ? orange : tile, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(!model.canPickPreset)
                    .opacity(model.canPickPreset || m == model.minutes ? 1 : 0.4)
                }
            }

            HStack(spacing: 8) {
                ActionButton(title: primaryTitle, symbol: primarySymbol, tint: .white) { model.toggle() }
                    .keyboardShortcut(.space, modifiers: [])
                ActionButton(title: "End", symbol: "stop.fill", tint: Color(red: 0.94, green: 0.58, blue: 0.58)) {
                    model.end()
                }
                .disabled(model.state == .idle)
                .opacity(model.state == .idle ? 0.4 : 1)
            }

            HStack {
                Toggle("Open at login", isOn: $openAtLogin)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .onChange(of: openAtLogin) { LoginItem.set($0) }
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 290)
        .background(Color(white: 0.11))
        .onAppear { openAtLogin = LoginItem.isEnabled }
    }

    private var statusLine: String {
        switch model.state {
        case .idle: return "\(model.minutes) min session"
        case .running: return "Focusing"
        case .paused: return "Paused"
        case .done: return "Done, take a break"
        }
    }

    private var primaryTitle: String {
        switch model.state {
        case .running: return "Pause"
        case .paused: return "Resume"
        case .done: return "Restart"
        case .idle: return "Start"
        }
    }

    private var primarySymbol: String {
        model.state == .running ? "pause.fill" : "play.fill"
    }
}

/// 60 ticks around a circle, lit clockwise from 12 o'clock for the time left.
struct TickRing: View {
    var fraction: Double

    var body: some View {
        Canvas { ctx, size in draw(in: &ctx, size: size) }
    }

    private func draw(in ctx: inout GraphicsContext, size: CGSize) {
        let cx: CGFloat = size.width / 2
        let cy: CGFloat = size.height / 2
        let outer: CGFloat = min(size.width, size.height) / 2 - 3
        let inner: CGFloat = outer - 16
        let lit = Int((fraction * 60).rounded(.up))
        let style = StrokeStyle(lineWidth: 4, lineCap: .round)
        for i in 0..<60 {
            let a: CGFloat = (CGFloat(i) * 6 - 90) * .pi / 180
            let dx: CGFloat = cos(a)
            let dy: CGFloat = sin(a)
            var p = Path()
            p.move(to: CGPoint(x: cx + inner * dx, y: cy + inner * dy))
            p.addLine(to: CGPoint(x: cx + outer * dx, y: cy + outer * dy))
            ctx.stroke(p, with: .color(i < lit ? orange : unlit), style: style)
        }
    }
}

private struct ActionButton: View {
    let title: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 34)
                .foregroundStyle(tint)
                .background(tile, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
