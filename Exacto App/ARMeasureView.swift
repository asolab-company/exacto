import ARKit
import Photos
import SceneKit
import SwiftUI
import simd

struct ARMeasureView: UIViewRepresentable {
    @Binding var unitSystem: UnitSystem
    @Binding var points: [SCNVector3]
    @Binding var totalLength: Float
    @Binding var placePointTrigger: Int
    @Binding var captureTrigger: Int
    @Binding var mode: MeasureMode

    @Binding var areaIsClosed: Bool
    @Binding var areaPointsCount: Int
    @Binding var backTrigger: Int
    @Binding var trashTrigger: Int

    @Binding var lineItems: [String]
    @Binding var linesDeleteIndex: Int
    @Binding var linesDeleteTrigger: Int
    @Binding var linesDeleteAllTrigger: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(
            unitSystem: $unitSystem,
            points: $points,
            totalLength: $totalLength,
            areaIsClosed: $areaIsClosed,
            areaPointsCount: $areaPointsCount,
            lineItems: $lineItems
        )
    }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        view.automaticallyUpdatesLighting = true
        view.scene = SCNScene()

        let cfg = ARWorldTrackingConfiguration()
        cfg.planeDetection = [.horizontal, .vertical]
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            cfg.sceneReconstruction = .mesh
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            cfg.frameSemantics.insert(.sceneDepth)
        }
        if ARWorldTrackingConfiguration.supportsFrameSemantics(
            .smoothedSceneDepth
        ) {
            cfg.frameSemantics.insert(.smoothedSceneDepth)
        }
        cfg.environmentTexturing = .automatic

        view.session.run(
            cfg,
            options: [.resetTracking, .removeExistingAnchors]
        )

        let reticle = ReticleView()
        reticle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(reticle)
        NSLayoutConstraint.activate([
            reticle.widthAnchor.constraint(equalToConstant: 56),
            reticle.heightAnchor.constraint(equalTo: reticle.widthAnchor),
            reticle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            reticle.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        context.coordinator.attach(to: view)
        context.coordinator.reticleView = reticle

        #if DEBUG
            view.debugOptions = [.showFeaturePoints]
        #endif
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {

        context.coordinator.setUnitSystem(unitSystem)

        if context.coordinator.lastTrigger != placePointTrigger {
            context.coordinator.lastTrigger = placePointTrigger
            context.coordinator.placePointFromCenter()
        }
        if context.coordinator.lastCaptureTrigger != captureTrigger {
            context.coordinator.lastCaptureTrigger = captureTrigger
            context.coordinator.captureSnapshotAndSave()
        }

        if context.coordinator.lastBackTrigger != backTrigger {
            context.coordinator.lastBackTrigger = backTrigger
            context.coordinator.undoLastAreaPoint()
        }
        if context.coordinator.lastTrashTrigger != trashTrigger {
            context.coordinator.lastTrashTrigger = trashTrigger
            context.coordinator.deleteArea()
        }

        if context.coordinator.lastLinesDeleteTrigger != linesDeleteTrigger {
            context.coordinator.lastLinesDeleteTrigger = linesDeleteTrigger
            context.coordinator.deleteSegment(at: linesDeleteIndex)
        }
        if context.coordinator.lastLinesDeleteAllTrigger
            != linesDeleteAllTrigger
        {
            context.coordinator.lastLinesDeleteAllTrigger =
                linesDeleteAllTrigger
            context.coordinator.deleteAllSegments()
        }

        context.coordinator.updateMode(mode)
    }

    final class Coordinator: NSObject {
        weak var view: ARSCNView?
        private(set) var unitSystem: UnitSystem
        @Binding var points: [SCNVector3]
        @Binding var totalLength: Float
        @Binding var lineItems: [String]
        var lastLinesDeleteTrigger = 0
        var lastLinesDeleteAllTrigger = 0

        @Binding var areaIsClosed: Bool
        @Binding var areaPointsCount: Int
        var lastBackTrigger: Int = 0
        var lastTrashTrigger: Int = 0
        private var areaClosed = false

        private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
        private let hapticSuccess = UINotificationFeedbackGenerator()
        private let hapticWarn = UINotificationFeedbackGenerator()

        private var startNode: SCNNode?
        private var previewDashed: SCNNode?
        private var isArmedForSecond = false

        private var previewLabel: SCNNode?

        weak var reticleView: ReticleView?

        var lastCaptureTrigger: Int = 0

        private(set) var mode: MeasureMode = .line

        private var areaNodes: [SCNNode] = []
        private var areaLines: [SCNNode] = []
        private var areaLabel: SCNNode?

        private var blockColor: UIColor { .systemRed }

        private var areaFill: SCNNode?

        @inline(__always) private func clamp(
            _ v: Float,
            _ lo: Float,
            _ hi: Float
        ) -> Float {
            return min(hi, max(lo, v))
        }
        @inline(__always) private func clamp(
            _ v: CGFloat,
            _ lo: CGFloat,
            _ hi: CGFloat
        ) -> CGFloat {
            return min(hi, max(lo, v))
        }

        func updateMode(_ new: MeasureMode) {
            guard new != mode else { return }
            mode = new

            previewDashed?.removeFromParentNode()
            previewDashed = nil
            previewLabel?.removeFromParentNode()
            previewLabel = nil
            isArmedForSecond = false
            startNode = nil
            reticleView?.setQuality(.none)

            clearSegments()
            clearArea()
        }

        private func clearArea() {
            areaNodes.forEach { $0.removeFromParentNode() }
            areaLines.forEach { $0.removeFromParentNode() }
            areaLabel?.removeFromParentNode()
            areaFill?.removeFromParentNode()

            areaNodes.removeAll()
            areaLines.removeAll()
            areaLabel = nil
            areaFill = nil
            areaClosed = false

            DispatchQueue.main.async {
                self.areaIsClosed = false
                self.areaPointsCount = 0
            }
        }

        private func clearSegments() {
            for seg in segments {
                seg.a.removeFromParentNode()
                seg.b.removeFromParentNode()
                seg.line.removeFromParentNode()
                seg.label.removeFromParentNode()
            }
            segments.removeAll()
            DispatchQueue.main.async {
                self.points.removeAll()
                self.totalLength = 0
                self.lineItems.removeAll()
            }
        }

        private let verticalCosThreshold: Float = 0.92

        private func isVertical(_ a: SCNVector3, _ b: SCNVector3) -> Bool {
            let v = simd_normalize(simd_float3(b.x - a.x, b.y - a.y, b.z - a.z))
            let up = simd_float3(0, 1, 0)
            return abs(simd_dot(v, up)) >= verticalCosThreshold
        }

        private func isSegmentAllowed(a: SCNVector3, b: SCNVector3) -> Bool {
            switch mode {
            case .line: return !isVertical(a, b)
            case .height: return isVertical(a, b)
            case .area: return true
            }
        }

        private func tintedImage(_ image: UIImage, color: UIColor) -> UIImage {
            UIGraphicsBeginImageContextWithOptions(
                image.size,
                false,
                image.scale
            )
            color.set()
            image.withRenderingMode(.alwaysTemplate)
                .draw(in: CGRect(origin: .zero, size: image.size))
            let out = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return out
        }

        private func makeAreaBadge(
            iconName: String,
            text: String,
            height h: CGFloat
        ) -> SCNNode {

            let labelNode = makePillLabel(text: text, height: h)
            let labelW = (labelNode.geometry as? SCNPlane)?.width ?? h * 2.0

            let iconNode = SCNNode()
            if let baseImg = UIImage(named: iconName) {
                let whiteImg = tintedImage(baseImg, color: .white)
                let plane = SCNPlane(width: h, height: h)
                let mat = SCNMaterial()
                mat.lightingModel = .constant
                mat.diffuse.contents = whiteImg
                mat.isDoubleSided = true
                plane.firstMaterial = mat
                iconNode.geometry = plane
            } else {

                iconNode.geometry = SCNPlane(width: h, height: h)
                iconNode.geometry?.firstMaterial?.diffuse.contents =
                    UIColor.clear
            }

            let parent = SCNNode()
            let bill = SCNBillboardConstraint()
            bill.freeAxes = .all
            parent.constraints = [bill]
            parent.renderingOrder = 1000

            let spacing: CGFloat = h * 0.18
            let totalW = h + spacing + labelW
            iconNode.position.x = -Float((totalW / 2) - h / 2)
            labelNode.position.x = Float((totalW / 2) - labelW / 2)

            parent.addChildNode(iconNode)
            parent.addChildNode(labelNode)
            return parent
        }

        private func makeAreaFill(_ pts: [SCNVector3]) -> SCNNode {
            guard pts.count >= 3 else { return SCNNode() }

            var n = simd_float3(0, 0, 0)
            for i in 0..<pts.count {
                let a = simd_float3(pts[i])
                let b = simd_float3(pts[(i + 1) % pts.count])
                n += simd_cross(a, b)
            }
            let len = simd_length(n)
            let normal = (len > 1e-6) ? (n / len) : simd_float3(0, 1, 0)

            let eps: Float = 0.0025
            let offset = normal * eps

            let v: [SCNVector3] = pts.map { p in
                let s = simd_float3(p) + offset
                return SCNVector3(s.x, s.y, s.z)
            }

            let vertices = v.map { SIMD3<Float>($0.x, $0.y, $0.z) }
            let vertexData = Data(
                bytes: vertices,
                count: MemoryLayout<SIMD3<Float>>.stride * vertices.count
            )
            let src = SCNGeometrySource(
                data: vertexData,
                semantic: .vertex,
                vectorCount: vertices.count,
                usesFloatComponents: true,
                componentsPerVector: 3,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<SIMD3<Float>>.stride
            )

            let idx: [UInt16] = [0, 1, 2, 0, 2, 3]
            let idxData = Data(
                bytes: idx,
                count: MemoryLayout<UInt16>.size * idx.count
            )
            let elem = SCNGeometryElement(
                data: idxData,
                primitiveType: .triangles,
                primitiveCount: 2,
                bytesPerIndex: MemoryLayout<UInt16>.size
            )

            let geom = SCNGeometry(sources: [src], elements: [elem])

            let mat = SCNMaterial()
            mat.lightingModel = .constant
            mat.diffuse.contents = UIColor.white.withAlphaComponent(0.25)
            mat.blendMode = .alpha
            mat.isDoubleSided = true
            mat.readsFromDepthBuffer = true
            mat.writesToDepthBuffer = false
            geom.firstMaterial = mat

            let node = SCNNode(geometry: geom)
            node.renderingOrder = 50
            return node
        }

        private func cameraDistance(to p: SCNVector3) -> Float {
            guard let pov = view?.pointOfView else { return 1.0 }
            let t = pov.worldTransform
            let c = SCNVector3(t.m41, t.m42, t.m43)
            let dx = p.x - c.x
            let dy = p.y - c.y
            let dz = p.z - c.z
            return sqrt(dx * dx + dy * dy + dz * dz)
        }

        private func dotRadius(for d: Float) -> CGFloat {
            let diam = worldSizeForPixels(8, at: d)
            return clamp(diam / 2, 0.0015, 0.009)
        }

        private func lineRadius(for d: Float) -> CGFloat {
            let thickness = worldSizeForPixels(2.4, at: d)
            return clamp(thickness / 2, 0.0008, 0.003)
        }

        private func dashParams(for d: Float) -> (dash: CGFloat, gap: CGFloat) {
            let dash = clamp(worldSizeForPixels(22, at: d), 0.008, 0.08)
            let gap = clamp(worldSizeForPixels(12, at: d), 0.005, 0.05)
            return (dash, gap)
        }

        private func labelHeight(for d: Float) -> CGFloat {
            return clamp(worldSizeForPixels(32, at: d), 0.014, 0.090)
        }

        private struct Segment {
            var a: SCNNode
            var b: SCNNode
            var line: SCNNode
            var label: SCNNode
            var len: Float
        }
        private var segments: [Segment] = []

        var lastTrigger: Int = 0

        private static let deviceHasLiDAR =
            ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
            || ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)

        private var minHit: Float { Self.deviceHasLiDAR ? 0.02 : 0.10 }
        private var maxHit: Float { Self.deviceHasLiDAR ? 25.0 : 15.0 }
        private let minPreviewLabelDistance: Float = 0.03
        private var mainColor: UIColor {

            UIColor(Color("MainColor"))
        }

        private var displayLink: CADisplayLink?

        init(
            unitSystem: Binding<UnitSystem>,
            points: Binding<[SCNVector3]>,
            totalLength: Binding<Float>,
            areaIsClosed: Binding<Bool>,
            areaPointsCount: Binding<Int>,
            lineItems: Binding<[String]>
        ) {
            self.unitSystem = unitSystem.wrappedValue
            _points = points
            _totalLength = totalLength
            _areaIsClosed = areaIsClosed
            _areaPointsCount = areaPointsCount
            _lineItems = lineItems
        }

        private func syncLineItems() {
            DispatchQueue.main.async {
                self.lineItems = self.segments.map { self.format($0.len) }
            }
        }

        func attach(to view: ARSCNView) {
            self.view = view
            let dl = CADisplayLink(target: self, selector: #selector(tick))
            dl.add(to: .main, forMode: .common)
            displayLink = dl

            hapticImpact.prepare()
            hapticSuccess.prepare()
            hapticWarn.prepare()
        }

        deinit { displayLink?.invalidate() }
        func setUnitSystem(_ new: UnitSystem) {
            guard new != unitSystem else { return }
            unitSystem = new
            refreshLabels()
        }

        func captureSnapshotAndSave() {
            guard let view = view else { return }

            let image = view.snapshot()

            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else {

                    UINotificationFeedbackGenerator().notificationOccurred(
                        .error
                    )
                    print("⚠️ No Photos permission to add.")
                    return
                }
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    DispatchQueue.main.async {
                        if success {
                            UINotificationFeedbackGenerator()
                                .notificationOccurred(.success)
                        } else {
                            UINotificationFeedbackGenerator()
                                .notificationOccurred(.error)
                            if let error = error {
                                print("❌ Save error:", error)
                            }
                        }
                    }
                }
            }
        }

        private func worldSizeForPixels(_ px: CGFloat, at d: Float) -> CGFloat {

            guard let v = view, let cam = v.pointOfView?.camera else {

                return CGFloat(d) * (px / 1400.0)
            }

            let fovY = CGFloat(cam.fieldOfView) * .pi / 180.0

            let worldScreenH = 2 * CGFloat(d) * tan(fovY / 2)

            let screenPixH = v.bounds.height * v.contentScaleFactor

            return worldScreenH * (px / screenPixH)
        }

        private func pillImageWithIcon(
            text: String,
            color: UIColor,
            icon: UIImage
        ) -> UIImage {
            let font = UIFont.systemFont(ofSize: 18, weight: .bold)
            let padH: CGFloat = 16
            let padV: CGFloat = 6
            let spacing: CGFloat = 10

            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let tSize = (text as NSString).size(withAttributes: attrs)

            let iconTargetH = max(16, tSize.height)
            let scale = iconTargetH / icon.size.height
            let iconW = icon.size.width * scale
            let iconH = iconTargetH

            let width = padH + iconW + spacing + tSize.width + padH
            let height = max(iconH, tSize.height) + padV * 2
            let size = CGSize(width: ceil(width), height: ceil(height))

            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            let ctx = UIGraphicsGetCurrentContext()!

            let path = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: size),
                cornerRadius: size.height / 2
            )
            color.setFill()
            path.fill()

            let iconY = (size.height - iconH) / 2
            icon.draw(
                in: CGRect(x: padH, y: iconY, width: iconW, height: iconH)
            )

            let textX = padH + iconW + spacing
            let textRect = CGRect(
                x: textX,
                y: (size.height - tSize.height) / 2,
                width: tSize.width,
                height: tSize.height
            )
            (text as NSString).draw(
                in: textRect,
                withAttributes: [.font: font, .foregroundColor: UIColor.white]
            )

            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.12).cgColor)
            ctx.setLineWidth(1)
            path.stroke()

            let out = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return out
        }

        private func makePillLabel(
            text: String,
            height h: CGFloat,
            leftIconName: String? = nil
        ) -> SCNNode {
            let img: UIImage
            if let name = leftIconName,
                let base = UIImage(named: name)
            {
                img = pillImageWithIcon(
                    text: text,
                    color: mainColor,
                    icon: tintedImage(base, color: .white)
                )
            } else {
                img = pillImage(text: text, color: mainColor)
            }

            let aspect = img.size.width / img.size.height
            let plane = SCNPlane(width: h * aspect, height: h)
            plane.cornerRadius = h * 0.5 * 0.80

            let mat = SCNMaterial()
            mat.lightingModel = .constant
            mat.isDoubleSided = true
            mat.diffuse.contents = img
            mat.readsFromDepthBuffer = false
            mat.writesToDepthBuffer = false
            plane.firstMaterial = mat

            let node = SCNNode(geometry: plane)
            node.renderingOrder = 1000
            let bill = SCNBillboardConstraint()
            bill.freeAxes = .all
            node.constraints = [bill]
            return node
        }

        private func pillImage(text: String, color: UIColor) -> UIImage {
            let font = UIFont.systemFont(ofSize: 18, weight: .bold)
            let padH: CGFloat = 16
            let padV: CGFloat = 6
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let tSize = (text as NSString).size(withAttributes: attrs)
            let size = CGSize(
                width: tSize.width + padH * 2,
                height: tSize.height + padV * 2
            )

            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            let ctx = UIGraphicsGetCurrentContext()!

            let path = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: size),
                cornerRadius: size.height / 2
            )
            color.setFill()
            path.fill()

            (text as NSString).draw(
                in: CGRect(
                    x: (size.width - tSize.width) / 2,
                    y: (size.height - tSize.height) / 2,
                    width: tSize.width,
                    height: tSize.height
                ),
                withAttributes: [.font: font, .foregroundColor: UIColor.white]
            )

            ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.12).cgColor)
            ctx.setLineWidth(1)
            path.stroke()

            let img = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return img
        }

        private func raycastFromCenterDetailed() -> (
            transform: simd_float4x4, quality: ReticleView.Quality
        )? {
            guard let view = view else { return nil }
            let p = CGPoint(x: view.bounds.midX, y: view.bounds.midY)

            func dist(_ t: simd_float4x4) -> Float {
                guard let cam = view.pointOfView?.simdWorldTransform else {
                    return .infinity
                }
                let c = simd_make_float3(cam.columns.3)
                let w = simd_make_float3(t.columns.3)
                return simd_length(w - c)
            }
            func valid(_ t: simd_float4x4) -> Bool {
                let d = dist(t)
                return d >= minHit && d <= maxHit
            }

            if let q = view.raycastQuery(
                from: p,
                allowing: .existingPlaneGeometry,
                alignment: .any
            ),
                let r = view.session.raycast(q).first, valid(r.worldTransform)
            {
                return (r.worldTransform, .strong)
            }
            if let q = view.raycastQuery(
                from: p,
                allowing: .estimatedPlane,
                alignment: .any
            ),
                let r = view.session.raycast(q).first, valid(r.worldTransform)
            {
                return (r.worldTransform, .weak)
            }
            if let r = view.hitTest(p, types: .featurePoint).first,
                valid(r.worldTransform)
            {
                return (r.worldTransform, .weak)
            }
            return nil
        }

        func placePointFromCenter() {
            guard let hit = raycastFromCenterDetailed() else {
                hapticWarn.notificationOccurred(.warning)
                return
            }
            let t = hit.transform
            let p = SCNVector3(t.columns.3.x, t.columns.3.y, t.columns.3.z)

            switch mode {
            case .line, .height:
                placePointForLineOrHeight(p)
            case .area:
                placePointForArea(p)
            }
        }

        private func placePointForLineOrHeight(_ p: SCNVector3) {
            guard let view = view else { return }
            if !isArmedForSecond {
                guard segments.count < 10 else {
                    hapticWarn.notificationOccurred(.warning)
                    return
                }

                startNode = makeDot(at: p)
                view.scene.rootNode.addChildNode(startNode!)
                points = [p]
                isArmedForSecond = true
                hapticImpact.impactOccurred()
            } else {
                let a = startNode!.worldPosition
                let b = p
                guard isSegmentAllowed(a: a, b: b) else {

                    hapticWarn.notificationOccurred(.warning)
                    return
                }

                let end = makeDot(at: b)
                view.scene.rootNode.addChildNode(end)

                previewDashed?.removeFromParentNode()
                previewDashed = nil
                previewLabel?.removeFromParentNode()
                previewLabel = nil

                let line = solidLine(from: a, to: b, color: mainColor)
                view.scene.rootNode.addChildNode(line)

                let dist = distance(a, b)
                let mid = SCNVector3(
                    (a.x + b.x) / 2,
                    (a.y + b.y) / 2,
                    (a.z + b.z) / 2
                )
                let hLbl = labelHeight(for: cameraDistance(to: mid))

                if mode != .height || isVertical(a, b) {
                    let label = makePillLabel(text: format(dist), height: hLbl)
                    label.position = midpointTowardsCamera(a, b, offset: 0.009)
                    view.scene.rootNode.addChildNode(label)

                    segments.append(
                        .init(
                            a: startNode!,
                            b: end,
                            line: line,
                            label: label,
                            len: dist
                        )
                    )
                    syncLineItems()
                }

                isArmedForSecond = false
                startNode = nil
                hapticSuccess.notificationOccurred(.success)
                reticleView?.setQuality(.none)
            }
        }

        private func placePointForArea(_ p: SCNVector3) {
            guard let view = view else { return }
            if areaClosed {
                hapticWarn.notificationOccurred(.warning)
                return
            }

            if areaNodes.count >= 4 {
                hapticWarn.notificationOccurred(.warning)
                return
            }

            let node = makeDot(at: p)
            view.scene.rootNode.addChildNode(node)

            if let last = areaNodes.last {
                let ln = solidLine(
                    from: last.worldPosition,
                    to: p,
                    color: mainColor
                )
                view.scene.rootNode.addChildNode(ln)
                areaLines.append(ln)
            }
            areaNodes.append(node)
            areaPointsCount = areaNodes.count
            hapticImpact.impactOccurred()

            if areaNodes.count == 4, let first = areaNodes.first {
                let lastPos = areaNodes[3].worldPosition
                let firstPos = first.worldPosition
                let closeLine = solidLine(
                    from: lastPos,
                    to: firstPos,
                    color: mainColor
                )
                view.scene.rootNode.addChildNode(closeLine)
                areaLines.append(closeLine)

                let pts = areaNodes.map { $0.worldPosition }
                let areaM2 = polygonArea3D(pts)

                let centroid = SCNVector3(
                    pts.map { $0.x }.reduce(0, +) / 4,
                    pts.map { $0.y }.reduce(0, +) / 4,
                    pts.map { $0.z }.reduce(0, +) / 4
                )

                let hLbl = labelHeight(for: cameraDistance(to: centroid))
                let badge = makePillLabel(
                    text: formatArea(areaM2),
                    height: hLbl,
                    leftIconName: "app_btn_menu03"
                )
                badge.position = midpointTowardsCamera(
                    centroid,
                    centroid,
                    offset: 0.012
                )
                view.scene.rootNode.addChildNode(badge)
                areaLabel = badge

                areaFill?.removeFromParentNode()
                let fill = makeAreaFill(pts)
                view.scene.rootNode.addChildNode(fill)
                areaFill = fill
                DispatchQueue.main.async {
                    self.areaClosed = true
                    self.areaIsClosed = true
                }
                previewDashed?.removeFromParentNode()
                previewDashed = nil
                hapticSuccess.notificationOccurred(.success)

            }
        }

        private func polygonArea3D(_ v: [SCNVector3]) -> Float {
            guard v.count >= 3 else { return 0 }
            var x = simd_float3(0, 0, 0)
            for i in 0..<v.count {
                let a = simd_float3(v[i].x, v[i].y, v[i].z)
                let b = simd_float3(
                    v[(i + 1) % v.count].x,
                    v[(i + 1) % v.count].y,
                    v[(i + 1) % v.count].z
                )
                x += simd_cross(a, b)
            }

            return 0.5 * simd_length(x)
        }

        private func formatArea(_ m2: Float) -> String {
            switch unitSystem {
            case .metric:
                if m2 < 1 { return String(format: "%.0f cm²", m2 * 10_000) }
                return String(format: "%.2f m²", m2)
            case .imperial:
                let ft2 = m2 * 10.7639
                return String(format: "%.2f ft²", ft2)
            }
        }

        @objc private func tick() {
            guard let view = view else {
                displayLink?.invalidate()
                displayLink = nil
                return
            }
            guard let hit = raycastFromCenterDetailed() else {
                previewDashed?.removeFromParentNode()
                previewDashed = nil
                previewLabel?.removeFromParentNode()
                previewLabel = nil
                reticleView?.setQuality(.none)
                return
            }
            reticleView?.setQuality(hit.quality)
            let t = hit.transform
            let b = SCNVector3(t.columns.3.x, t.columns.3.y, t.columns.3.z)

            switch mode {
            case .line, .height:
                guard isArmedForSecond, let a = startNode?.worldPosition else {
                    previewDashed?.removeFromParentNode()
                    previewDashed = nil
                    previewLabel?.removeFromParentNode()
                    previewLabel = nil
                    return
                }
                let allowed = isSegmentAllowed(a: a, b: b)

                previewDashed?.removeFromParentNode()
                let dashed = dashedLine(
                    from: a,
                    to: b,
                    color: allowed ? mainColor : blockColor
                )
                view.scene.rootNode.addChildNode(dashed)
                previewDashed = dashed

                let d = distance(a, b)
                previewLabel?.removeFromParentNode()
                if allowed && d >= minPreviewLabelDistance {
                    let mid = SCNVector3(
                        (a.x + b.x) / 2,
                        (a.y + b.y) / 2,
                        (a.z + b.z) / 2
                    )
                    let hLbl = labelHeight(for: cameraDistance(to: mid))
                    let lbl = makePillLabel(text: format(d), height: hLbl)
                    lbl.position = midpointTowardsCamera(a, b, offset: 0.009)
                    view.scene.rootNode.addChildNode(lbl)
                    previewLabel = lbl
                } else {
                    previewLabel = nil
                }

            case .area:
                if areaClosed {
                    previewDashed?.removeFromParentNode()
                    previewDashed = nil
                    previewLabel?.removeFromParentNode()
                    previewLabel = nil
                    return
                }
                if let last = areaNodes.last {
                    previewDashed?.removeFromParentNode()
                    let dashed = dashedLine(
                        from: last.worldPosition,
                        to: b,
                        color: mainColor
                    )
                    view.scene.rootNode.addChildNode(dashed)
                    previewDashed = dashed
                } else {
                    previewDashed?.removeFromParentNode()
                    previewDashed = nil
                }
                previewLabel?.removeFromParentNode()
                previewLabel = nil
            }
        }

        func undoLastAreaPoint() {
            guard !areaClosed else { return }
            guard view != nil else { return }
            guard !areaNodes.isEmpty else { return }

            previewDashed?.removeFromParentNode()
            previewDashed = nil

            if let lastLine = areaLines.popLast() {
                lastLine.removeFromParentNode()
            }

            if let lastNode = areaNodes.popLast() {
                lastNode.removeFromParentNode()
                hapticImpact.impactOccurred()
            }

            areaPointsCount = areaNodes.count
        }

        func deleteArea() {

            previewDashed?.removeFromParentNode()
            previewDashed = nil
            previewLabel?.removeFromParentNode()
            previewLabel = nil

            clearArea()
            hapticSuccess.notificationOccurred(.success)
        }

        private func raycastTransformFromCenter() -> simd_float4x4? {
            guard let view = view else { return nil }
            let p = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
            func valid(_ t: simd_float4x4) -> Bool {
                guard let cam = view.pointOfView?.simdWorldTransform else {
                    return true
                }
                let c = simd_make_float3(cam.columns.3)
                let w = simd_make_float3(t.columns.3)
                let d = simd_length(w - c)
                return d >= minHit && d <= maxHit
            }

            if let q = view.raycastQuery(
                from: p,
                allowing: .existingPlaneGeometry,
                alignment: .any
            ),
                let r = view.session.raycast(q).first, valid(r.worldTransform)
            {
                return r.worldTransform
            }
            if let q = view.raycastQuery(
                from: p,
                allowing: .estimatedPlane,
                alignment: .any
            ),
                let r = view.session.raycast(q).first, valid(r.worldTransform)
            {
                return r.worldTransform
            }
            if let r = view.hitTest(p, types: .featurePoint).first,
                valid(r.worldTransform)
            {
                return r.worldTransform
            }
            return nil
        }

        private func makeDot(at p: SCNVector3) -> SCNNode {
            let d = cameraDistance(to: p)
            let s = SCNSphere(radius: dotRadius(for: d))
            let m = SCNMaterial()
            m.lightingModel = .constant
            m.diffuse.contents = mainColor
            m.emission.contents = mainColor
            s.firstMaterial = m
            let n = SCNNode(geometry: s)
            n.position = p
            return n
        }

        private func dashedLine(
            from: SCNVector3,
            to: SCNVector3,
            color: UIColor
        ) -> SCNNode {
            let total = CGFloat(distance(from, to))
            let parent = SCNNode()
            guard total > 0.0005 else { return parent }

            let mid = SCNVector3(
                (from.x + to.x) / 2,
                (from.y + to.y) / 2,
                (from.z + to.z) / 2
            )
            let dCam = cameraDistance(to: mid)
            let (dash, gap) = dashParams(for: dCam)
            let radius = lineRadius(for: dCam)

            let step = max(0.001, dash + gap)
            let count = max(1, Int(ceil(total / step)))
            let dir = SCNVector3(
                (to.x - from.x) / Float(total),
                (to.y - from.y) / Float(total),
                (to.z - from.z) / Float(total)
            )

            let mat = SCNMaterial()
            mat.lightingModel = .constant
            mat.diffuse.contents = color
            mat.emission.contents = color

            for i in 0..<count {
                let startD = CGFloat(i) * step
                let endD = min(startD + dash, total)
                if endD <= startD { continue }

                let centerD = (startD + endD) / 2
                let segLen = endD - startD

                let center = SCNVector3(
                    from.x + Float(centerD) * dir.x,
                    from.y + Float(centerD) * dir.y,
                    from.z + Float(centerD) * dir.z
                )

                let cyl = SCNCylinder(radius: radius, height: segLen)
                cyl.firstMaterial = mat
                let n = SCNNode(geometry: cyl)
                n.position = center
                orientNode(n, from: from, to: to)
                n.renderingOrder = 200
                parent.addChildNode(n)
            }
            return parent
        }

        private func solidLine(from: SCNVector3, to: SCNVector3, color: UIColor)
            -> SCNNode
        {
            let h = CGFloat(distance(from, to))
            let mid = SCNVector3(
                (from.x + to.x) / 2,
                (from.y + to.y) / 2,
                (from.z + to.z) / 2
            )
            let dCam = cameraDistance(to: mid)
            let cyl = SCNCylinder(radius: lineRadius(for: dCam), height: h)

            let m = SCNMaterial()
            m.lightingModel = .constant
            m.diffuse.contents = color
            m.emission.contents = color
            cyl.firstMaterial = m

            let n = SCNNode(geometry: cyl)
            n.position = mid
            orientNode(n, from: from, to: to)
            n.renderingOrder = 200
            return n
        }

        private func makeLabel(text: String) -> SCNNode {
            let t = SCNText(string: text, extrusionDepth: 0.001)
            t.font = .systemFont(ofSize: 0.08, weight: .bold)
            t.firstMaterial?.lightingModel = .constant
            t.firstMaterial?.diffuse.contents = UIColor.white

            let node = SCNNode(geometry: t)
            let (minB, maxB) = t.boundingBox
            node.pivot = SCNMatrix4MakeTranslation(
                (maxB.x - minB.x) / 2,
                minB.y,
                0
            )
            node.scale = SCNVector3(0.01, 0.01, 0.01)

            let bg = SCNPlane(
                width: CGFloat(maxB.x - minB.x) * 0.012 + 0.02,
                height: 0.018
            )
            bg.cornerRadius = 0.009
            let bm = SCNMaterial()
            bm.lightingModel = .constant
            bm.diffuse.contents = mainColor
            bg.firstMaterial = bm

            let bgNode = SCNNode(geometry: bg)
            bgNode.position = SCNVector3(0, -0.002, -0.005)
            node.addChildNode(bgNode)

            let bill = SCNBillboardConstraint()
            bill.freeAxes = .all
            node.constraints = [bill]
            node.renderingOrder = 1000
            return node
        }

        func refreshLabels() {
            guard let view = view else { return }

            for i in segments.indices {
                let seg = segments[i]
                seg.label.removeFromParentNode()

                let mid = SCNVector3(
                    (seg.a.worldPosition.x + seg.b.worldPosition.x) / 2,
                    (seg.a.worldPosition.y + seg.b.worldPosition.y) / 2,
                    (seg.a.worldPosition.z + seg.b.worldPosition.z) / 2
                )
                let hLbl = labelHeight(for: cameraDistance(to: mid))
                let label = makePillLabel(text: format(seg.len), height: hLbl)
                label.position = midpointTowardsCamera(
                    seg.a.worldPosition,
                    seg.b.worldPosition,
                    offset: 0.009
                )
                view.scene.rootNode.addChildNode(label)
                segments[i].label = label
                DispatchQueue.main.async { self.syncLineItems() }
            }

            if areaLabel != nil, areaNodes.count >= 3 {
                areaLabel?.removeFromParentNode()
                let pts = areaNodes.map { $0.worldPosition }
                let areaM2 = polygonArea3D(pts)

                let centroid = SCNVector3(
                    pts.map { $0.x }.reduce(0, +) / Float(pts.count),
                    pts.map { $0.y }.reduce(0, +) / Float(pts.count),
                    pts.map { $0.z }.reduce(0, +) / Float(pts.count)
                )
                let hLbl = labelHeight(for: cameraDistance(to: centroid))
                let lbl = makePillLabel(
                    text: formatArea(areaM2),
                    height: hLbl,
                    leftIconName: "app_btn_menu03"
                )
                lbl.position = midpointTowardsCamera(
                    centroid,
                    centroid,
                    offset: 0.012
                )
                view.scene.rootNode.addChildNode(lbl)
                areaLabel = lbl
            }
        }

        private func distance(_ a: SCNVector3, _ b: SCNVector3) -> Float {
            let dx = a.x - b.x
            let dy = a.y - b.y
            let dz = a.z - b.z
            return sqrt(dx * dx + dy * dy + dz * dz)
        }

        private func orientNode(
            _ node: SCNNode,
            from: SCNVector3,
            to: SCNVector3
        ) {
            let u = simd_float3(0, 1, 0)
            let v = simd_normalize(
                simd_float3(to.x - from.x, to.y - from.y, to.z - from.z)
            )
            var axis = simd_cross(u, v)
            var axisLen = simd_length(axis)

            if axisLen < 1e-6 {

                let dot = simd_dot(u, v)
                if dot > 0 {
                    node.simdOrientation = simd_quatf(
                        angle: 0,
                        axis: simd_float3(0, 1, 0)
                    )
                } else {

                    node.simdOrientation = simd_quatf(
                        angle: .pi,
                        axis: simd_float3(1, 0, 0)
                    )
                }
                return
            }

            axis /= axisLen
            let angle = acos(max(-1, min(1, simd_dot(u, v))))
            node.simdOrientation = simd_quatf(angle: angle, axis: axis)
        }
        private func midpointTowardsCamera(
            _ a: SCNVector3,
            _ b: SCNVector3,
            offset: Float
        ) -> SCNVector3 {
            var m = SCNVector3(
                (a.x + b.x) / 2,
                (a.y + b.y) / 2,
                (a.z + b.z) / 2
            )
            if let pov = view?.pointOfView {
                let t = pov.worldTransform
                let cam = SCNVector3(t.m41, t.m42, t.m43)
                let v = SCNVector3(cam.x - m.x, cam.y - m.y, cam.z - m.z)
                let L = max(0.0001, sqrt(v.x * v.x + v.y * v.y + v.z * v.z))
                m = SCNVector3(
                    m.x + v.x / L * offset,
                    m.y + v.y / L * offset,
                    m.z + v.z / L * offset
                )
            }
            return m
        }
        private func format(_ meters: Float) -> String {
            switch unitSystem {
            case .metric:
                return meters < 1
                    ? "\(Int(round(meters*100))) cm"
                    : String(format: "%.2f m", meters)
            case .imperial:
                let ftTotal = meters * 3.28084
                if ftTotal < 3 {
                    return String(format: "%.0f in", round(ftTotal * 12))
                }
                let ft = floor(ftTotal)
                let inch = round((ftTotal - ft) * 12)
                return String(format: "%.0f ft %.0f in", ft, inch)
            }
        }

        func deleteSegment(at index: Int) {
            guard index >= 0, index < segments.count else { return }
            let seg = segments.remove(at: index)
            seg.a.removeFromParentNode()
            seg.b.removeFromParentNode()
            seg.line.removeFromParentNode()
            seg.label.removeFromParentNode()
            totalLength = max(0, totalLength - seg.len)
            syncLineItems()
            hapticSuccess.notificationOccurred(.success)
        }

        func deleteAllSegments() {
            clearSegments()
            syncLineItems()
            hapticSuccess.notificationOccurred(.success)
        }
    }

}
