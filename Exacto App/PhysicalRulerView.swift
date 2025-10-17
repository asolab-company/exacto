import SwiftUI
import UIKit

struct DualRulerView: View {
    @AppStorage("ruler.calibration") private var calibration: Double = 1.0
    @State private var showCal = false

    @State private var p1: CGFloat = 0
    @State private var p2: CGFloat = 0

    private let accent = Color("MainColor")

    var body: some View {
        GeometryReader { geo in
            let H = geo.size.height
            let W = geo.size.width

            ZStack {
                Color(hex: "#BABABA")
                    .ignoresSafeArea()

                DualScaleCanvas(
                    height: H,
                    width: W,
                    pointsPerMM: pointsPerMM,
                    pointsPerInch: pointsPerInch
                )
                .foregroundStyle(.primary.opacity(0.95))

                Rectangle()
                    .fill(accent.opacity(0.35))
                    .frame(width: W, height: abs(p2 - p1))
                    .position(x: W / 2, y: (p1 + p2) / 2)

                marker(x: W / 2, y: $p1, limit: H)
                marker(x: W / 2, y: $p2, limit: H)

                VStack {
                    Spacer()
                    lengthLabel(abs(p2 - p1))
                        .padding(.bottom)
                }
            }

            .contentShape(Rectangle())
            .gesture(dragNearestHandle(inside: geo))
        }
        .background(.ultraThinMaterial)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Calibrate") { showCal = true }
            }
        }
        .sheet(isPresented: $showCal) {
            RulerCalibrationView(
                calibration: $calibration,
                pointsPerMMNominal: pointsPerMMNominal,
                accent: accent
            )
        }
    }

    private var pointsPerInch: CGFloat {
        defaultPPI() / UIScreen.main.nativeScale
    }
    private var pointsPerMMNominal: CGFloat { pointsPerInch / 25.4 }
    private var pointsPerMM: CGFloat {
        pointsPerMMNominal * CGFloat(calibration)
    }

    private func lengthLabel(_ distancePoints: CGFloat) -> some View {
        let mm = distancePoints / pointsPerMM
        let cm = mm / 10.0
        let inches = distancePoints / pointsPerInch

        let metricText =
            (mm < 100)
            ? String(format: "%.1f mm", mm)
            : String(format: "%.1f cm", cm)
        let inchText = String(format: "%.3f in", inches)

        let fontSize: CGFloat = 16
        let uiFont =
            UIFont(name: "SFProDisplay-Bold", size: fontSize)
            ?? .systemFont(ofSize: fontSize, weight: .bold)
        let separatorHeight = uiFont.lineHeight * 0.9

        return HStack(spacing: 12) {
            Text(metricText)
            Rectangle()
                .fill(Color.white.opacity(0.35))
                .frame(width: 1, height: separatorHeight)
                .cornerRadius(0.5)
            Text(inchText)
        }
        .font(.custom("SFProDisplay-Bold", size: fontSize))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: "#000000").opacity(0.5))
        )
        .shadow(radius: 2, y: 1)
    }

    private func marker(x: CGFloat, y: Binding<CGFloat>, limit: CGFloat)
        -> some View
    {
        let d: CGFloat = 44
        return Circle()
            .fill(accent)
            .frame(width: d, height: d)
            .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
            .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))
            .position(x: x, y: y.wrappedValue)
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        y.wrappedValue = clamp(g.location.y, 0, limit)
                    }
            )
            .accessibilityLabel("Handle")
    }

    private func dragNearestHandle(inside geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { g in
                let y = clamp(g.location.y, 0, geo.size.height)
                if abs(y - p1) <= abs(y - p2) { p1 = y } else { p2 = y }
            }
    }

    private func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        min(hi, max(lo, v))
    }
}

private struct DualScaleCanvas: View {
    let height: CGFloat
    let width: CGFloat
    let pointsPerMM: CGFloat
    let pointsPerInch: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let H = height
            let W = width

            let leftX: CGFloat = 0.5
            let rightX: CGFloat = W - 0.5

            var path = Path()

            func tickLeft(y: CGFloat, len: CGFloat) {
                path.move(to: CGPoint(x: leftX, y: y))
                path.addLine(to: CGPoint(x: leftX + len, y: y))
            }
            func tickRight(y: CGFloat, len: CGFloat) {
                path.move(to: CGPoint(x: rightX, y: y))
                path.addLine(to: CGPoint(x: rightX - len, y: y))
            }

            if pointsPerMM > 0 {
                let step = pointsPerMM
                let count = Int(floor(H / step))
                for i in 0...count {
                    let y = CGFloat(i) * step
                    if i % 10 == 0 {
                        let long: CGFloat = 40
                        tickLeft(y: y, len: long)

                        drawLabel(
                            "\(i/10)",
                            at: CGPoint(x: leftX + long + 4, y: y),
                            anchor: .leading,
                            ctx: ctx,
                            canvasHeight: H
                        )
                    } else if i % 5 == 0 {
                        tickLeft(y: y, len: 26)
                    } else {
                        tickLeft(y: y, len: 16)
                    }
                }
            }

            if pointsPerInch > 0 {
                let inch = pointsPerInch
                let inches = Int(ceil(H / inch))
                for i in 0...inches {
                    let y0 = CGFloat(i) * inch
                    let long: CGFloat = 40
                    tickRight(y: y0, len: long)

                    drawLabel(
                        "\(i)",
                        at: CGPoint(x: rightX - long - 4, y: y0),
                        anchor: .trailing,
                        ctx: ctx,
                        canvasHeight: H
                    )

                    tickRight(y: y0 + inch / 2, len: 28)
                    tickRight(y: y0 + inch / 4, len: 22)
                    tickRight(y: y0 + 3 * inch / 4, len: 22)
                    for k in [1, 3, 5, 7] {
                        tickRight(y: y0 + CGFloat(k) * inch / 8, len: 16)
                    }
                    for k in stride(from: 1, through: 15, by: 2) {
                        tickRight(y: y0 + CGFloat(k) * inch / 16, len: 10)
                    }
                }
            }
            ctx.stroke(path, with: .color(.black), lineWidth: 1.2)
        }
    }

    private func drawLabel(
        _ s: String,
        at p: CGPoint,
        anchor: UnitPoint,
        ctx: GraphicsContext,
        canvasHeight H: CGFloat
    ) {
        let text = Text(s)
            .font(.system(size: 12, weight: .semibold, design: .rounded))

        var resolved = ctx.resolve(text)
        resolved.shading = .color(.black)

        let tSize = resolved.measure(
            in: CGSize(
                width: CGFloat.greatestFiniteMagnitude,
                height: CGFloat.greatestFiniteMagnitude
            )
        )
        let half = tSize.height / 2
        var y = p.y
        y = max(half + 2, min(H - half - 2, y))

        ctx.draw(resolved, at: CGPoint(x: p.x, y: y), anchor: anchor)
    }
}

private struct RulerCalibrationView: View {
    @Binding var calibration: Double
    let pointsPerMMNominal: CGFloat
    let accent: Color

    private let referenceMM: CGFloat = 85.60

    var body: some View {
        VStack(spacing: 18) {
            Text("Calibrate ruler")
                .font(.system(.title2, design: .rounded).weight(.bold))

            Text(
                "Приложи банковскую карту к экрану и подгони ширину синего прямоугольника."
            )
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            GeometryReader { geo in
                let target =
                    referenceMM * pointsPerMMNominal * CGFloat(calibration)
                Rectangle()
                    .fill(accent.opacity(0.35))
                    .frame(
                        width: target,
                        height: min(140, geo.size.height * 0.5)
                    )
                    .overlay(
                        Text("85.60 mm")
                            .font(
                                .system(.headline, design: .rounded).weight(
                                    .semibold
                                )
                            )
                            .padding(8)
                            .background(.thinMaterial, in: Capsule())
                            .padding(.top, 8),
                        alignment: .top
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 220)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 16)
            )
            .padding(.horizontal)

            HStack {
                Text("−")
                Slider(value: $calibration, in: 0.85...1.15, step: 0.0005)
                Text("+")
            }
            .padding(.horizontal)

            Text(String(format: "Scale: %.3f×", calibration))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}

private func defaultPPI() -> CGFloat {
    let idiom = UIDevice.current.userInterfaceIdiom
    if idiom == .pad { return 264 }
    let h = max(
        UIScreen.main.nativeBounds.width,
        UIScreen.main.nativeBounds.height
    )
    if [2796, 2556, 2532, 2460, 2436, 2778, 2688].contains(Int(h)) {
        return 458
    }
    if [2208, 1920].contains(Int(h)) { return 401 }
    return 326
}

#Preview {
    DualRulerView()
}
