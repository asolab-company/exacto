import SwiftUI

@main
struct Exacto_AppApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var overlay = OverlayManager()
    @State private var screenMetrics = ScreenMetrics()

    var body: some Scene {
        WindowGroup {
            GeometryReader { geometry in
                AppRootView()
                    .environmentObject(IAPManager.shared)
                    .environmentObject(overlay)
                    .environment(\.windowMetrics, WindowMetrics(
                        size: CGSize(
                            width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
                            height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
                        ),
                        screen: screenMetrics
                    ))
                    .background {
                        WindowScreenReader(metrics: $screenMetrics)
                            .frame(width: 0, height: 0)
                    }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await IAPManager.shared.refreshEntitlements() }
                }
            }

        }
    }
}
