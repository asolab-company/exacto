import SwiftUI
import UIKit

nonisolated struct ScreenMetrics: Equatable {
    var nativeSize: CGSize = .zero
    var nativeScale: CGFloat = 1
}

nonisolated struct WindowMetrics: Equatable {
    var size: CGSize = CGSize(width: 390, height: 844)
    var screen = ScreenMetrics()

    var isSmall: Bool { size.height < 700 }
}

extension EnvironmentValues {
    @Entry var windowMetrics = WindowMetrics()
}

struct WindowScreenReader: UIViewRepresentable {
    @Binding var metrics: ScreenMetrics

    func makeUIView(context: Context) -> ScreenReaderView {
        ScreenReaderView()
    }

    func updateUIView(_ uiView: ScreenReaderView, context: Context) {
        uiView.onUpdate = { value in
            if metrics != value { metrics = value }
        }
        uiView.reportScreen()
    }
}

final class ScreenReaderView: UIView {
    var onUpdate: ((ScreenMetrics) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        reportScreen()
    }

    func reportScreen() {
        guard let screen = window?.windowScene?.screen else { return }
        let value = ScreenMetrics(nativeSize: screen.nativeBounds.size, nativeScale: screen.nativeScale)
        DispatchQueue.main.async { [weak self] in self?.onUpdate?(value) }
    }
}
