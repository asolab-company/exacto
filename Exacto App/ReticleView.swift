import SwiftUI
import UIKit

final class ReticleView: UIView {
    enum Quality { case none, weak, strong }

    private let ring = CAShapeLayer()
    private let cross = CAShapeLayer()
    private let ticks = CAShapeLayer()
    private let dot = CAShapeLayer()

    private var mainColor: UIColor { UIColor(Color("MainColor")) }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false

        [ring, cross, ticks, dot].forEach { layer.addSublayer($0) }

        ring.fillColor = UIColor.clear.cgColor
        ring.lineWidth = 2

        cross.fillColor = UIColor.clear.cgColor
        cross.lineWidth = 1.5

        ticks.fillColor = UIColor.clear.cgColor
        ticks.lineWidth = 1

        dot.fillColor = mainColor.cgColor

        updatePaths()
        applyHalo()
        setQuality(.none, animated: false)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePaths()
    }

    private func updatePaths() {
        let s: CGFloat = 44
        let r: CGFloat = 18
        let c = CGPoint(x: bounds.midX, y: bounds.midY)

        let rp = UIBezierPath(
            ovalIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)
        )
        ring.path = rp.cgPath

        let crossLen: CGFloat = 6
        let cp = UIBezierPath()
        cp.move(to: CGPoint(x: c.x - crossLen, y: c.y))
        cp.addLine(to: CGPoint(x: c.x + crossLen, y: c.y))
        cp.move(to: CGPoint(x: c.x, y: c.y - crossLen))
        cp.addLine(to: CGPoint(x: c.x, y: c.y + crossLen))
        cross.path = cp.cgPath

        let tp = UIBezierPath()
        let tickCount = 12
        let tickLen: CGFloat = 4
        for i in 0..<tickCount {
            let a = CGFloat(i) * (2 * CGFloat.pi / CGFloat(tickCount))
            let p0 = CGPoint(
                x: c.x + cos(a) * (r - tickLen),
                y: c.y + sin(a) * (r - tickLen)
            )
            let p1 = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            tp.move(to: p0)
            tp.addLine(to: p1)
        }
        ticks.path = tp.cgPath

        let d: CGFloat = 4
        let dp = UIBezierPath(
            ovalIn: CGRect(x: c.x - d / 2, y: c.y - d / 2, width: d, height: d)
        )
        dot.path = dp.cgPath
    }

    func setQuality(_ q: Quality, animated: Bool = true) {
        let base: UIColor
        let alphaRing: CGFloat
        let alphaCross: CGFloat
        let alphaTicks: CGFloat
        let alphaDot: CGFloat

        switch q {
        case .none:
            base = .white
            alphaRing = 0.90
            alphaCross = 0.70
            alphaTicks = 0.80
            alphaDot = 0.95
            stopBreathing()
        case .weak:
            base = mainColor
            alphaRing = 0.6
            alphaCross = 0.4
            alphaTicks = 0.5
            alphaDot = 0.8
            stopBreathing()
        case .strong:
            base = mainColor
            alphaRing = 1.0
            alphaCross = 0.8
            alphaTicks = 0.9
            alphaDot = 1.0
            startBreathing()
        }

        let ringColor = base.withAlphaComponent(alphaRing).cgColor
        let crossColor = base.withAlphaComponent(alphaCross).cgColor
        let tickColor = base.withAlphaComponent(alphaTicks).cgColor
        let dotColor = base.withAlphaComponent(alphaDot).cgColor

        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        ring.strokeColor = ringColor
        cross.strokeColor = crossColor
        ticks.strokeColor = tickColor
        dot.fillColor = dotColor
        CATransaction.commit()
    }
    private func applyHalo() {
        [ring, cross, ticks, dot].forEach {
            $0.shadowColor = UIColor.black.withAlphaComponent(0.55).cgColor
            $0.shadowOpacity = 1
            $0.shadowRadius = 2.2
            $0.shadowOffset = .zero
        }
    }
    private func startBreathing() {
        if layer.animation(forKey: "breath") != nil { return }
        let a = CABasicAnimation(keyPath: "transform.scale")
        a.fromValue = 1.0
        a.toValue = 1.06
        a.duration = 0.8
        a.autoreverses = true
        a.repeatCount = .infinity
        a.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(a, forKey: "breath")
    }
    private func stopBreathing() {
        layer.removeAnimation(forKey: "breath")
        layer.transform = CATransform3DIdentity
    }
}
