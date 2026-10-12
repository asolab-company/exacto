import AVFoundation
import SwiftUI

struct CameraPreview: UIViewRepresentable {
    func makeCoordinator() -> CameraCaptureController {
        CameraCaptureController()
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        context.coordinator.startPreview(in: view)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: PreviewView, coordinator: CameraCaptureController) {
        coordinator.stopPreview(in: uiView)
    }
}

nonisolated final class CameraCaptureController: @unchecked Sendable {
    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "com.exacto.app.camera")
    private var configured = false

    @MainActor
    func startPreview(in view: PreviewView) {
        view.videoPreviewLayer.session = session
        queue.async { [self] in
            if !configured {
                guard let camera = AVCaptureDevice.default(
                    .builtInWideAngleCamera, for: .video, position: .back
                ), let input = try? AVCaptureDeviceInput(device: camera),
                      session.canAddInput(input) else { return }
                session.beginConfiguration()
                if session.canSetSessionPreset(.high) { session.sessionPreset = .high }
                session.addInput(input)
                session.commitConfiguration()
                configured = true
            }
            if !session.isRunning { session.startRunning() }
        }
    }

    @MainActor
    func stopPreview(in view: PreviewView) {
        view.videoPreviewLayer.session = nil
        queue.async { [self] in
            if session.isRunning { session.stopRunning() }
        }
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
