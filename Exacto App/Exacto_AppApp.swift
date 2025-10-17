import SwiftUI

@main
struct Exacto_AppApp: App {

    @StateObject private var overlay = OverlayManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(IAPManager.shared)
                .environmentObject(overlay)

        }
    }
}
