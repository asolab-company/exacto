import CoreMotion
import SwiftUI
import UIKit

final class MotionLeveler: ObservableObject {

    @Published var angleDeg: Double = 0

    @Published var bubble: CGPoint = .zero
    @Published var tiltFromHorizontalDeg: Double = 0

    private let mm = CMMotionManager()

    init() {
        mm.deviceMotionUpdateInterval = 1 / 60
        mm.startDeviceMotionUpdates(
            using: .xArbitraryCorrectedZVertical,
            to: .main
        ) { [weak self] motion, _ in
            guard let self, let m = motion else { return }
            let g = m.gravity

            let (gx, gy) = Self.screenAlignedXY(gx: g.x, gy: g.y)
            let gz = g.z

            let angleDown = atan2(gx, -gy)
            self.angleDeg = Self.normalize(angleDown * 180 / .pi)

            self.bubble = CGPoint(x: -gx, y: -gy)

            let r = sqrt(gx * gx + gy * gy)
            let tilt = atan2(r, abs(gz))
            self.tiltFromHorizontalDeg = tilt * 180 / .pi
        }
    }

    deinit { mm.stopDeviceMotionUpdates() }

    private static func screenAlignedXY(gx: Double, gy: Double) -> (
        Double, Double
    ) {
        let orientation =
            UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.interfaceOrientation ?? .portrait

        switch orientation {
        case .portrait: return (gx, gy)
        case .portraitUpsideDown: return (-gx, -gy)
        case .landscapeLeft: return (-gy, gx)
        case .landscapeRight: return (gy, -gx)
        default: return (gx, gy)
        }
    }

    static func normalize(_ d: Double) -> Double {
        var x = d
        while x <= -180 { x += 360 }
        while x > 180 { x -= 360 }
        return x
    }
}

struct LevelOverlay: View {
    @Binding var mode: LevelMode
    @Binding var isLocked: Bool
    @StateObject private var motion = MotionLeveler()

    private let perfectToleranceDeg = 1.0
    private let toVertical = 65.0
    private let toHorizontal = 20.0
    @State private var didHaptic = false

    @State private var lockAngle: Double = 0
    @State private var lockTilt: Double = 0
    @State private var lockBubble: CGPoint = .zero

    private var angleDisplay: Double { isLocked ? lockAngle : motion.angleDeg }
    private var tiltDisplay: Double {
        isLocked ? lockTilt : motion.tiltFromHorizontalDeg
    }
    private var bubbleDisplay: CGPoint { isLocked ? lockBubble : motion.bubble }

    private func signedNoPlusZero(_ value: Double) -> String {
        let n = Int(round(value))
        if n == 0 { return "0" }
        return n > 0 ? "+\(n)" : "\(n)"
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height) * 0.74
            let ringW: CGFloat = 6

            ZStack {
                switch mode {
                case .vertical:
                    verticalView(size: size)
                case .horizontal:

                    Circle()
                        .stroke(lineWidth: 3)
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: size, height: size)

                    Crosshair()
                        .stroke(style: .init(lineWidth: 4, lineCap: .round))
                        .foregroundStyle(.white)
                        .frame(width: size * 0.98, height: size * 0.98)

                    horizontalBubbleView(size: size, ringW: ringW)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        .onChange(of: motion.tiltFromHorizontalDeg) { tilt in
            guard !isLocked else { return }
            switch mode {
            case .horizontal where tilt > toVertical:
                withAnimation(.easeInOut(duration: 0.15)) { mode = .vertical }
            case .vertical where tilt < toHorizontal:
                withAnimation(.easeInOut(duration: 0.15)) { mode = .horizontal }
            default: break
            }
        }

        .onChange(of: isLocked) { locked in
            guard locked else { return }
            lockAngle = motion.angleDeg
            lockTilt = motion.tiltFromHorizontalDeg
            lockBubble = motion.bubble
        }
    }

    @ViewBuilder
    private func verticalView(size: CGFloat) -> some View {
        let isPerfect = abs(angleDisplay) <= perfectToleranceDeg

        LevelLine()
            .stroke(style: .init(lineWidth: 6, lineCap: .round))
            .foregroundStyle(.white)
            .frame(width: size * 1.15, height: 2)
            .rotationEffect(.degrees(angleDisplay))
            .shadow(radius: 3)

        centerBadge(size: size, text: signedNoPlusZero(angleDisplay))
            .onChange(of: isPerfect) { good in
                guard !isLocked else { return }
                if good && !didHaptic {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    didHaptic = true
                } else if !good {
                    didHaptic = false
                }
            }
    }

    @ViewBuilder
    private func horizontalBubbleView(size: CGFloat, ringW: CGFloat)
        -> some View
    {
        let ringRadius = size * 0.46
        let bubbleRadius = size * 0.46
        let maxTravel = ringRadius * 0.45

        let vx = CGFloat(bubbleDisplay.x)
        let vy = CGFloat(bubbleDisplay.y)
        let dx = vx * maxTravel
        let dy = vy * maxTravel

        let isFlat = tiltDisplay <= perfectToleranceDeg

        Circle()
            .stroke(lineWidth: ringW)
            .foregroundStyle(Color("MainColor", bundle: .main))
            .frame(width: bubbleRadius * 2, height: bubbleRadius * 2)
            .offset(x: dx, y: dy)
            .animation(
                .interpolatingSpring(stiffness: 220, damping: 22),
                value: dx
            )
            .animation(
                .interpolatingSpring(stiffness: 220, damping: 22),
                value: dy
            )
            .onChange(of: isFlat) { good in
                guard !isLocked else { return }
                if good && !didHaptic {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                    didHaptic = true
                } else if !good {
                    didHaptic = false
                }
            }

        centerBadge(size: size, text: "\(Int(round(tiltDisplay)))")
    }

    @ViewBuilder
    private func centerBadge(size: CGFloat, text: String) -> some View {
        ZStack {
            Circle().fill(.black.opacity(0.45))
            Text(text)
                .font(.system(size: size * 0.18, weight: .black))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .allowsTightening(true)
                .monospacedDigit()
        }
        .frame(width: size * 0.46, height: size * 0.46)
    }
}

private struct Crosshair: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = min(r.width, r.height)
        let tick: CGFloat = w * 0.08
        let gap: CGFloat = w * 0.40

        p.move(to: CGPoint(x: r.midX - gap, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX - gap - tick, y: r.midY))
        p.move(to: CGPoint(x: r.midX + gap, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX + gap + tick, y: r.midY))

        p.move(to: CGPoint(x: r.midX, y: r.midY - gap))
        p.addLine(to: CGPoint(x: r.midX, y: r.midY - gap - tick))
        p.move(to: CGPoint(x: r.midX, y: r.midY + gap))
        p.addLine(to: CGPoint(x: r.midX, y: r.midY + gap + tick))
        return p
    }
}

private struct LevelLine: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        return p
    }
}
