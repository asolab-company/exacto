import SwiftUI

struct SettingsItem: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let action: () -> Void
}

struct SettingsView: View {
    @EnvironmentObject var overlay: OverlayManager
    @EnvironmentObject var iap: IAPManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage(Prefs.unitSystemKey) private var unitRaw: String = UnitSystem
        .metric.rawValue
    private var unitSelectedBinding: Binding<UnitSystem> {
        Binding(
            get: { UnitSystem(rawValue: unitRaw) ?? .metric },
            set: { unitRaw = $0.rawValue }
        )
    }

    private var unitSelected: Binding<UnitSystem> { unitSelectedBinding }

    var items: [SettingsItem] {
        [

            SettingsItem(
                icon: "ic_file",
                label: "Terms and Conditions",
                action: { UIApplication.shared.open(Constants.termsURL) }
            ),
            SettingsItem(
                icon: "ic_policy",
                label: "Privacy",
                action: { UIApplication.shared.open(Constants.privacyURL) }
            ),
            SettingsItem(
                icon: "ic_restore",
                label: "Restore Purchases",
                action: {
                    Task {
                        await iap.restore()
                    }
                }
            ),
        ]
    }

    var body: some View {
        ZStack {
            Color(hex: "#383B3E")
                .ignoresSafeArea()

            VStack(alignment: .center, spacing: 30) {

                ZStack {

                    HStack {
                        Spacer()

                        Button(action: {
                            dismiss()
                        }) {
                            Image("ic_closes")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    ZStack {
                                        Circle().fill(.ultraThinMaterial)
                                        Circle().fill(Color.black.opacity(0.76))
                                    }
                                    .frame(width: 46, height: 46)
                                )
                        }
                    }

                    Text("Settings")
                        .font(.custom("SFProDisplay-Regular", size: 20))
                        .foregroundColor(.white)
                }

                if !iap.isSubscribed {
                    Button(action: {
                        overlay.show()
                    }) {
                        HStack(spacing: 12) {

                            Image("ic_vip")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.yellow)

                            HStack(spacing: 0) {
                                Text("Become ")
                                    .foregroundColor(.white)
                                    .font(
                                        .custom(
                                            "SFProDisplay-Regular",
                                            size: 20
                                        )
                                    )
                                Text("Premium ")
                                    .foregroundColor(.white)
                                    .font(
                                        .custom("SFProDisplay-Bold", size: 20)
                                    )
                                Text("User")
                                    .foregroundColor(.white)
                                    .font(
                                        .custom(
                                            "SFProDisplay-Regular",
                                            size: 20
                                        )
                                    )
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("MainColor"),
                                            Color("MainColor"),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )

                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {

                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.white.opacity(0.9))
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .frame(width: 28, height: 28)

                        Text(
                            "We’ll make sure that the app displays\nmeasurements in selected units"
                        )
                        .foregroundColor(.white)
                        .font(.custom("SFProDisplay-Regular", size: 16))
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 1)

                    VStack(spacing: 0) {
                        ForEach(
                            Array(UnitSystem.allCases.enumerated()),
                            id: \.offset
                        ) { idx, system in
                            UnitRow(system: system, selected: unitSelected)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 10)

                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.5))

                )

                VStack(spacing: 10) {
                    ForEach(items) { item in
                        Button(action: item.action) {
                            HStack {
                                Image(item.icon)
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .semibold))
                                    .frame(width: 24)

                                Text(item.label)
                                    .foregroundColor(.white)
                                    .font(
                                        .custom(
                                            "SFProDisplay-Regular",
                                            size: 16
                                        )
                                    )
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                                    .padding(.leading, 5)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.white)
                            }

                            .padding(.vertical, 14)
                            .padding(.horizontal, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.black.opacity(0.5))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                    }
                }

                Spacer()

            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }

    }
}

struct UnitRow: View {
    let system: UnitSystem
    @Binding var selected: UnitSystem

    var body: some View {
        Button {
            selected = system

            #if !DEBUG
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #else
                if ProcessInfo.processInfo.environment[
                    "XCODE_RUNNING_FOR_PREVIEWS"
                ] != "1" {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            #endif
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(system.rawValue)
                        .foregroundColor(.white)
                        .font(.custom("SFProDisplay-Semibold", size: 14))
                    Text(system.description)
                        .foregroundColor(.white.opacity(0.85))
                        .font(.custom("SFProDisplay-Regular", size: 11))
                }

                Spacer()

                if selected == system {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.12))
                        Circle().stroke(Color.white.opacity(0.25), lineWidth: 2)
                        Circle().fill(Color("MainColor")).frame(
                            width: 22,
                            height: 22
                        )
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .frame(width: 22, height: 22)
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 22, height: 22)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
        .environmentObject(IAPManager.shared)
        .environmentObject(OverlayManager())
}
