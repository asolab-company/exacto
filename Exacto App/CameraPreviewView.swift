import AVFoundation
import SwiftUI

struct CameraPreview: UIViewRepresentable {
    private let session = AVCaptureSession()

    func makeUIView(context: Context) -> PreviewView {
        let v = PreviewView()
        v.videoPreviewLayer.videoGravity = .resizeAspectFill

        guard
            let cam = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: .back
            ),
            let input = try? AVCaptureDeviceInput(device: cam),
            session.canAddInput(input)
        else { return v }

        session.beginConfiguration()
        if session.canSetSessionPreset(.high) { session.sessionPreset = .high }
        session.addInput(input)
        session.commitConfiguration()

        v.videoPreviewLayer.session = session
        session.startRunning()
        return v
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    static func dismantleUIView(_ uiView: PreviewView, coordinator: ()) {
        uiView.videoPreviewLayer.session?.stopRunning()
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
