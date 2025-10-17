import SwiftUI

struct AppRootView: View {
    @EnvironmentObject var iap: IAPManager
    @EnvironmentObject var overlay: OverlayManager

    @State private var state: AppState = .loading

    enum AppState {
        case loading
        case onboarding
        case main
    }

    var body: some View {
        Group {
            switch state {
            case .loading:
                Loading {
                    let passed = UserDefaults.standard.bool(
                        forKey: "onboarding_passed"
                    )
                    state = passed ? .main : .onboarding
                }

            case .onboarding:
                Onboarding {
                    state = .main
                }

            case .main:
                ContentView()

            }
        }
        .environmentObject(iap)
        .environmentObject(overlay)

    }
}
