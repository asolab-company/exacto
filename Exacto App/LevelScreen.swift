import SwiftUI

struct LevelScreen: View {
    @Binding var isLocked: Bool
    @State private var mode: LevelMode

    init(initialMode: LevelMode = .horizontal, isLocked: Binding<Bool>) {
        _mode = State(initialValue: initialMode)
        _isLocked = isLocked
    }

    var body: some View {
        ZStack {
            CameraPreview().ignoresSafeArea()
            LevelOverlay(mode: $mode, isLocked: $isLocked)
                .ignoresSafeArea()
        }
        .overlay(alignment: .bottom) {
            Picker("", selection: $mode) {
                Text("Horizontal").tag(LevelMode.horizontal)
                Text("Vertical").tag(LevelMode.vertical)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .onAppear { isLocked = false }
        .onDisappear { isLocked = false }
    }
}

enum LevelMode { case horizontal, vertical }

#Preview("Horizontal") {
    LevelScreen(initialMode: .horizontal, isLocked: .constant(false))
}
#Preview("Vertical") {
    LevelScreen(initialMode: .vertical, isLocked: .constant(false))
}
