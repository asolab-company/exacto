import ARKit
import AVFoundation
import SceneKit
import SwiftUI

struct LockedOverlayData {
    let title: String
    let subtitle: String
    let bgImageName: String?
}

enum MeasureMode: String {
    case line
    case area
    case height
}

struct ContentView: View {
    @Environment(\.windowMetrics) private var windowMetrics
    @EnvironmentObject var iap: IAPManager
    @EnvironmentObject var overlay: OverlayManager
    @State private var status = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var isTorchOn = false
    @State private var selected = 0
    @State private var showSettings = false
    @State private var didPresentInitialPaywall = false
    @State private var mode: MeasureMode = .line

    @State private var areaIsClosed = false
    @State private var areaPointsCount = 0
    @State private var backTrigger = 0
    @State private var trashTrigger = 0

    @State private var lineItems: [String] = []
    @State private var linesDeleteIndex: Int = -1
    @State private var linesDeleteTrigger: Int = 0
    @State private var linesDeleteAllTrigger: Int = 0

    @State private var isLevelLocked = false

    @AppStorage(Prefs.unitSystemKey) private var unitRaw: String = UnitSystem
        .metric.rawValue

    private var unitSystemBinding: Binding<UnitSystem> {
        Binding(
            get: { UnitSystem(rawValue: unitRaw) ?? .metric },
            set: { unitRaw = $0.rawValue }
        )
    }

    private var isPlusDisabled: Bool {
        mode == .area && areaIsClosed
    }

    private var isLevelOrRulerSelected: Bool {
        currentItem.title == "Level" || currentItem.title == "Ruler"
    }

    private var isLevelSelected: Bool {
        currentItem.title == "Level"
    }

    private var isRulerSelected: Bool {
        currentItem.title == "Ruler"
    }

    @State private var measurePoints: [SCNVector3] = []
    @State private var measureTotal: Float = 0

    @State private var placePointTrigger: Int = 0
    @State private var captureTrigger = 0

    private let baseItems: [BottomBarItem] = [
        .init(title: "Measure", iconName: "app_btn_menu05", locked: true),
        .init(title: "Square", iconName: "app_btn_menu03", locked: true),
        .init(title: "Height", iconName: "app_btn_menu04", locked: true),
        .init(title: "Level", iconName: "app_btn_menu02", locked: true),
        .init(title: "Ruler", iconName: "app_btn_menu01", locked: true),
    ]

    private var items: [BottomBarItem] {
        baseItems.map { item in
            var item = item
            item.locked = !iap.isSubscribed
            return item
        }
    }

    private var currentItem: BottomBarItem {
        let idx = min(max(selected, 0), items.count - 1)
        return items[idx]
    }

    private var lockedOverlay: LockedOverlayData? {
        guard currentItem.locked else { return nil }
        switch currentItem.title {
        case "Measure":
            return .init(
                title: "Measure Distance",
                subtitle: "Use your camera to measure\ndistances and objects",
                bgImageName: "app_ic_onbording01"
            )
        case "Square":
            return .init(
                title: "Measure Square",
                subtitle: "Use your camera to measure\nsquare of rooms or objects",
                bgImageName: "square_vip"
            )
        case "Height":
            return .init(
                title: "Measure Height",
                subtitle: "Use your camera to measure\nheight of rooms or objects",
                bgImageName: "height_vip"
            )
        case "Level":
            return .init(
                title: "Bubble Level",
                subtitle: "Check if surfaces are perfectly straight or aligned.\nIdeal for hanging shelves, pictures, or floor.",
                bgImageName: "bubble_vip"
            )
        default:
            return .init(
                title: "Measure with a Smart Ruler",
                subtitle: "Turn your phone into a digital ruler. Quickly measure small objects with precision, anytime and anywhere.",
                bgImageName: "ruller_vip"
            )
        }
    }

    var body: some View {
        ZStack {

            if lockedOverlay != nil {
                Color(hex: "#383B3E")
                    .ignoresSafeArea()
            } else if status == .authorized {

                if isARItem(currentItem.title) {
                    ARMeasureView(
                        unitSystem: unitSystemBinding,
                        points: $measurePoints,
                        totalLength: $measureTotal,
                        placePointTrigger: $placePointTrigger,
                        captureTrigger: $captureTrigger,
                        mode: $mode,

                        areaIsClosed: $areaIsClosed,
                        areaPointsCount: $areaPointsCount,
                        backTrigger: $backTrigger,
                        trashTrigger: $trashTrigger,

                        lineItems: $lineItems,
                        linesDeleteIndex: $linesDeleteIndex,
                        linesDeleteTrigger: $linesDeleteTrigger,
                        linesDeleteAllTrigger: $linesDeleteAllTrigger
                    )
                    .ignoresSafeArea()

                } else if isLevelSelected {
                    LevelScreen(isLocked: $isLevelLocked)
                } else {
                    Color(hex: "#BABABA")
                        .ignoresSafeArea()
                }

            } else {
                Color(hex: "#383B3E")
                    .ignoresSafeArea()
            }

            if let locked = lockedOverlay, let bg = locked.bgImageName {
                VStack {
                    Image(bg)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                        .offset(y: windowMetrics.isSmall ? -140 : 0)

                    Spacer()
                }

            }

            VStack {

                ZStack {

                    HStack(spacing: 40) {

                        if status == .authorized, lockedOverlay == nil,
                            !isRulerSelected
                        {
                            Button(action: {
                                if iap.isSubscribed {
                                    toggleTorch()
                                } else {
                                    overlay.show()
                                }
                            }) {
                                ZStack(alignment: .topTrailing) {
                                    Image("ic_flashlight")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundStyle(
                                            isTorchOn
                                                ? Color("MainColor") : .white
                                        )
                                        .padding(12)
                                        .background(
                                            ZStack {
                                                Circle().fill(
                                                    .ultraThinMaterial
                                                )
                                                Circle().fill(
                                                    Color.black.opacity(0.76)
                                                )
                                            }
                                            .frame(width: 46, height: 46)
                                        )

                                    if !iap.isSubscribed {
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 18, height: 18)
                                            .overlay(
                                                Image("ic_lock")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(
                                                        width: 10,
                                                        height: 10
                                                    )
                                                    .foregroundStyle(
                                                        Color("MainColor")
                                                    )
                                            )
                                            .offset(x: 3, y: 0)
                                    }
                                }
                            }
                        }
                        Spacer()

                        Button(action: {
                            showSettings = true
                        }) {
                            Image("ic_settings")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundStyle(.white)
                                .padding(12)
                                .background(
                                    ZStack {
                                        Circle().fill(.ultraThinMaterial)
                                        Circle().fill(Color.black.opacity(0.76))
                                    }
                                    .frame(width: 46, height: 46)
                                )
                        }
                        .accessibilityLabel("Settings")

                    }.padding(.horizontal)
                        .padding(.top)

                    HStack(spacing: 8) {
                        Image(currentItem.iconName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.white)

                        Text(currentItem.title)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.white)

                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color("MainColor"))
                    )

                }

                if let locked = lockedOverlay {

                    lockedOverlayView(locked)
                        .padding(.horizontal)
                        .transition(.opacity)
                } else if status != .authorized {

                    overlayCamera
                        .padding(.horizontal)
                        .transition(.opacity)
                } else {

                    if isRulerSelected {
                        DualRulerView().padding(.top, 5)
                    } else {
                        Spacer()
                    }
                }

                if !isLevelOrRulerSelected {
                    if status == .authorized && lockedOverlay == nil {
                        ZStack {

                            HStack(spacing: 40) {

                                if mode == .area {

                                    Button(action: {
                                        if areaIsClosed {
                                            trashTrigger &+= 1
                                        } else {
                                            backTrigger &+= 1
                                        }
                                        UIImpactFeedbackGenerator(style: .light)
                                            .impactOccurred()
                                    }) {
                                        Image(
                                            areaIsClosed
                                                ? "ic_trash" : "ic_back"
                                        )
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundStyle(.white)
                                        .padding(12)
                                        .background(
                                            ZStack {
                                                Circle().fill(
                                                    .ultraThinMaterial
                                                )
                                                Circle().fill(
                                                    Color.black.opacity(0.76)
                                                )
                                            }
                                            .frame(width: 46, height: 46)
                                        )
                                    }
                                    .id(
                                        areaIsClosed
                                            ? "left_trash" : "left_back"
                                    )
                                    .animation(
                                        .easeInOut(duration: 0.2),
                                        value: areaIsClosed
                                    )
                                } else {

                                    Menu {
                                        if lineItems.isEmpty {
                                            Button("No measurements") {}
                                                .disabled(
                                                    true
                                                )
                                        } else {
                                            ForEach(
                                                Array(lineItems.enumerated()),
                                                id: \.offset
                                            ) { (idx, title) in
                                                Button(title) {
                                                    linesDeleteIndex = idx
                                                    linesDeleteTrigger &+= 1
                                                }
                                            }
                                            Divider()
                                            Button(role: .destructive) {
                                                linesDeleteAllTrigger &+= 1
                                            } label: {
                                                Label(
                                                    "Delete All",
                                                    systemImage: "trash"
                                                )
                                            }
                                        }
                                    } label: {
                                        Image("ic_trash")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundStyle(.white)
                                            .padding(12)
                                            .background(
                                                ZStack {
                                                    Circle().fill(
                                                        .ultraThinMaterial
                                                    )
                                                    Circle().fill(
                                                        Color.black.opacity(
                                                            0.76
                                                        )
                                                    )
                                                }
                                                .frame(width: 46, height: 46)
                                            )
                                    }
                                    .environment(\.colorScheme, .dark)
                                }

                                Spacer()
                                Button(action: {
                                    if iap.isSubscribed {
                                        captureTrigger &+= 1
                                        UIImpactFeedbackGenerator(style: .light)
                                            .impactOccurred()
                                    } else {

                                        overlay.show()
                                    }
                                }) {
                                    ZStack(alignment: .topTrailing) {
                                        Image("ic_camera")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20)
                                            .foregroundStyle(
                                                isTorchOn
                                                    ? Color("MainColor")
                                                    : .white
                                            )
                                            .padding(12)
                                            .background(
                                                ZStack {
                                                    Circle().fill(
                                                        .ultraThinMaterial
                                                    )
                                                    Circle().fill(
                                                        Color.black.opacity(
                                                            0.76
                                                        )
                                                    )
                                                }
                                                .frame(width: 46, height: 46)
                                            )

                                        if !iap.isSubscribed {
                                            Circle()
                                                .fill(.white)
                                                .frame(width: 18, height: 18)
                                                .overlay(
                                                    Image("ic_lock")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(
                                                            width: 10,
                                                            height: 10
                                                        )
                                                        .foregroundStyle(
                                                            Color("MainColor")
                                                        )
                                                )
                                                .offset(x: 3, y: 0)
                                        }
                                    }
                                }

                            }.padding(.horizontal)
                                .padding(.top)

                            Button(action: {
                                guard iap.isSubscribed else {
                                    overlay.show()
                                    return
                                }
                                if !isPlusDisabled { placePointTrigger &+= 1 }
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 64, height: 64)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                    .shadow(
                                        color: Color.black.opacity(0.25),
                                        radius: 6,
                                        x: 0,
                                        y: 3
                                    )
                            }
                            .accessibilityLabel("Add measurement point")
                            .disabled(isPlusDisabled)
                            .allowsHitTesting(!isPlusDisabled)
                            .opacity(isPlusDisabled ? 0.35 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.2),
                                value: isPlusDisabled
                            )

                        }.padding(.bottom)
                    }
                }

                if isLevelSelected, status == .authorized, lockedOverlay == nil
                {
                    VStack {
                        Spacer()
                        Button {
                            isLevelLocked.toggle()
                            UIImpactFeedbackGenerator(style: .rigid)
                                .impactOccurred()
                        } label: {
                            Image(isLevelLocked ? "ic_locks" : "ic_unlock")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundStyle(.white)
                                .padding(20)
                                .background(Color("MainColor"))
                                .clipShape(Circle())
                                .shadow(
                                    color: Color.black.opacity(0.25),
                                    radius: 6,
                                    x: 0,
                                    y: 3
                                )
                                .id(isLevelLocked ? "locked" : "unlocked")
                        }
                        .accessibilityLabel(
                            isLevelLocked ? "Unlock level" : "Lock level"
                        )
                        .padding(.bottom)
                    }
                }

                BottomBar(
                    items: items,
                    selected: $selected,
                    onTap: selectItem,
                    onLockedTap: selectItem
                )
            }

        }
        .onChange(of: iap.isSubscribed) { _, subscribed in
            if !subscribed { setTorch(false) }
        }
        .onChange(of: iap.hasLoadedEntitlements) { presentInitialPaywallIfNeeded() }
        .onDisappear { setTorch(false) }
        .onAppear {
            refreshStatus()
            presentInitialPaywallIfNeeded()
        }

        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification
            )
        ) { _ in
            refreshStatus()
        }

        .fullScreenCover(isPresented: $overlay.showPaywall) {
            PayWall()
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
        }

    }

    private func presentInitialPaywallIfNeeded() {
        guard iap.hasLoadedEntitlements, !didPresentInitialPaywall else { return }
        didPresentInitialPaywall = true
        if !iap.isSubscribed { overlay.show() }
    }

    private func selectItem(_ index: Int) {
        guard items.indices.contains(index) else { return }
        setTorch(false)
        selected = index
        mode = modeForTitle(items[index].title)
    }

    private func modeForTitle(_ title: String) -> MeasureMode {
        switch title {
        case "Measure": return .line
        case "Square": return .area
        case "Height": return .height
        default: return .line
        }
    }

    private func setTorch(_ on: Bool) {
        guard isTorchOn != on else { return }
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch
        else {
            return
        }
        do {
            try device.lockForConfiguration()
            defer { device.unlockForConfiguration() }
            if on {

                try device.setTorchModeOn(level: 0.8)
            } else {
                device.torchMode = .off
            }
            isTorchOn = on
        } catch {}
    }

    private func isARItem(_ title: String) -> Bool {
        return title == "Measure" || title == "Square" || title == "Height"
    }
    private func toggleTorch() {
        setTorch(!isTorchOn)
    }

    private var overlayCamera: some View {
        VStack {
            Spacer()

            Image("app_ic_no photo")
                .font(.system(size: 120, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.25))
                .padding(.bottom, 24)

            Text("Allow Camera Access")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Color("MainColor"))
                .padding(.bottom, 10)

            VStack(spacing: 4) {
                Text("Measure Height")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                Text("Use your camera to measure\nheight of walls and objects")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: primaryAction) {
                HStack {
                    Spacer()
                    Text(primaryTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .bold))
                }
                .padding()
                .background(Color("MainColor"))
                .clipShape(.rect(cornerRadius: 10))
            }
            .padding(.bottom, 20)
            .padding(.horizontal)
        }
    }

    private func lockedOverlayView(_ locked: LockedOverlayData) -> some View {

        VStack {
            Spacer()

            VStack(spacing: 12) {
                Text(locked.title)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Color("MainColor"))

                Text(locked.subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.bottom)

                Button(action: {
                    overlay.show()
                }) {
                    HStack {
                        Spacer()
                        Text("Become Premium User")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                    .padding()
                    .background(Color("MainColor"))
                    .clipShape(.rect(cornerRadius: 10))
                }
                .padding(.bottom, 20)
                .padding(.horizontal)
            }

        }
    }

    private var primaryTitle: String {
        switch status {
        case .denied, .restricted: return "Settings"
        case .authorized: return "Continue"
        case .notDetermined: return "Next"
        @unknown default: return "Allow"
        }
    }

    private func primaryAction() {
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { self.refreshStatus() }
            }
        case .denied, .restricted:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        case .authorized:

            break
        @unknown default:
            break
        }
    }

    private func refreshStatus() {
        status = AVCaptureDevice.authorizationStatus(for: .video)
    }
}
