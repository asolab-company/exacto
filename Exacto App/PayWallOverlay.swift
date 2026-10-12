import StoreKit
import SwiftUI

enum PlanType {
    case weekly, yearly
}

struct PayWall: View {
    @Environment(\.windowMetrics) private var windowMetrics
    @EnvironmentObject var iap: IAPManager

    @State private var weeklyTrialEligible = false

    @State private var selectedPlan: PlanType = .weekly
    @State private var isTrialEnabled: Bool = true

    @Environment(\.dismiss) private var dismiss

    @State private var purchasing = false
    @State private var purchaseMessage: String? = nil

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack(alignment: .top) {

                Color(hex: "#383B3E")
                    .ignoresSafeArea()

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image("ic_close")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundStyle(.white)
                    }
                    .accessibilityLabel("Close paywall")

                    Spacer()
                }
                .padding(.horizontal)

                VStack {
                    VStack(spacing: height * 0.015) {

                        Image("app_ic_paywall")
                            .resizable()
                            .scaledToFit()

                        Text("Get Unlimited Access")
                            .font(
                                .system(size: windowMetrics.isSmall ? 22 : 28, weight: .heavy)
                            )
                            .foregroundStyle(Color("MainColor"))
                            .multilineTextAlignment(.center)
                            .dynamicTypeSize(.medium ... .xxLarge)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom)

                        let columns = [
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20),
                        ]

                        LazyVGrid(
                            columns: columns,
                            alignment: .center,
                            spacing: 20
                        ) {

                            FeatureTile(
                                icon: "app_ic_paywall04",

                                line1: Text("Create a full"),
                                line2: Text("Room Plan").foregroundStyle(
                                    Color("MainColor")
                                )
                            )

                            FeatureTile(
                                icon: "app_ic_paywall01",

                                line1: Text("Take \(Text("unlimited").foregroundStyle(Color("MainColor")))"),
                                line2: Text("measurements")
                            )

                            FeatureTile(
                                icon: "app_ic_paywall03",

                                line1: Text("Auto-calculate").foregroundStyle(
                                    Color("MainColor")
                                ),
                                line2: Text("perimeter")
                            )

                            FeatureTile(
                                icon: "app_ic_paywall02",

                                line1: Text("Measure").foregroundStyle(
                                    Color("MainColor")
                                ),
                                line2: Text("the level")
                            )
                        }
                        .padding(.bottom)

                        if weeklyFreeTrialOffer != nil {
                            HStack {
                                Text("Free Trial Enabled")
                                    .foregroundStyle(
                                        selectedPlan == .weekly
                                            ? .white : Color.init(hex: "7E7E7E")
                                    )
                                    .font(.system(size: 15, weight: .medium))
                                    .dynamicTypeSize(.medium ... .xxLarge)

                                Spacer()

                                Toggle("", isOn: $isTrialEnabled)
                                    .labelsHidden()
                                    .tint(Color(hex: "#419400"))
                                    .onChange(of: isTrialEnabled) { _, newValue in
                                        if newValue {
                                            selectedPlan = .weekly
                                        } else {
                                            selectedPlan = .yearly
                                        }
                                    }
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "#000000"),
                                                Color(hex: "#000000"),
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ).opacity(0.5)
                                    )

                            )

                        }

                        PlanCard(
                            title: "Yearly Access",
                            subtitle: yearlySubtitle(),
                            badgeText: "BEST OFFER",
                            isSelected: selectedPlan == .yearly,

                            planType: .yearly
                        ) {
                            selectedPlan = .yearly
                            isTrialEnabled = false
                        }

                        PlanCard(
                            title: weeklyTitle(),
                            subtitle: weeklySubtitle(),
                            badgeText: weeklyBadge(),
                            isSelected: selectedPlan == .weekly,
                            planType: .weekly
                        ) {
                            selectedPlan = .weekly
                            isTrialEnabled = true
                        }

                    }
                    .padding(.horizontal, width * 0.08)
                    .padding(.bottom, height * 0.015)

                    Button(action: {
                        guard !purchasing else { return }
                        Task {
                            purchasing = true
                            defer { purchasing = false }

                            if iap.products.isEmpty {
                                await iap.fetchProducts()
                            }

                            guard AppStore.canMakePayments else {
                                purchaseMessage =
                                    "In-App Purchases are disabled on this device."
                                return
                            }
                            guard
                                let product = iap.products.first(where: {
                                    $0.id
                                        == (selectedPlan == .weekly
                                            ? Constants.weekly
                                            : Constants.yearly)
                                })
                            else {
                                purchaseMessage =
                                    "Products are not loaded yet. Please try again."
                                return
                            }

                            do {
                                switch try await iap.purchase(product: product) {
                                case .purchased:
                                    if iap.isSubscribed { dismiss() }
                                case .cancelled:
                                    break
                                case .pending:
                                    purchaseMessage = "Your purchase is pending approval."
                                }
                            } catch {
                                purchaseMessage = error.localizedDescription
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Continue")
                                .foregroundStyle(.white)
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(Color("MainColor"))
                        .clipShape(.rect(cornerRadius: 10))
                    }
                    .disabled(purchasing || !AppStore.canMakePayments)
                    .frame(height: 55)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 10)

                    VStack(spacing: 20) {

                        HStack(spacing: 8) {
                            Image("ic_shield")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)

                            Text(
                                includesFreeTrial
                                    ? "No Payment Now" : "Cancel Anytime"
                            )
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "ffffff"))
                        }

                        HStack(spacing: 40) {
                            Button(action: {
                                UIApplication.shared.open(Constants.privacyURL)
                            }) {
                                Text("Privacy Policy")
                                    .font(
                                        .system(size: 14, weight: .regular)
                                    )
                                    .foregroundStyle(Color(hex: "#BDBDBD"))
                            }

                            Button(action: {
                                guard !purchasing else { return }
                                purchasing = true
                                Task {
                                    defer { purchasing = false }
                                    do {
                                        if try await iap.restore() {
                                            dismiss()
                                        } else {
                                            purchaseMessage = "No active subscription was found."
                                        }
                                    } catch {
                                        purchaseMessage = error.localizedDescription
                                    }
                                }
                            }) {
                                Text("Restore")
                                    .font(
                                        .system(size: 14, weight: .regular)
                                    )
                                    .foregroundStyle(Color(hex: "#BDBDBD"))
                            }

                            Button(action: {
                                UIApplication.shared.open(Constants.termsURL)
                            }) {
                                Text("Terms of Use")
                                    .font(
                                        .system(size: 14, weight: .regular)
                                    )
                                    .foregroundStyle(Color(hex: "#BDBDBD"))
                            }
                        }
                    }
                    .padding(.bottom)
                }
                if purchasing || iap.isLoadingProducts {
                    ZStack {

                        Color.black.opacity(0.35).ignoresSafeArea()
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    }
                }
            }

        }.task(id: iap.products.map(\.id)) {
            if iap.products.isEmpty { await iap.fetchProducts() }
            weeklyTrialEligible = await weeklyProduct()?.subscription?.isEligibleForIntroOffer ?? false
        }

        .onChange(of: iap.isSubscribed) { _, subscribed in
            if subscribed { dismiss() }
        }
        .alert(
            "Purchase",
            isPresented: Binding(
                get: { purchaseMessage != nil },
                set: { if !$0 { purchaseMessage = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) { purchaseMessage = nil }
            },
            message: {
                Text(purchaseMessage ?? "")
            }
        )

    }

    private func weeklyProduct() -> Product? {
        iap.products.first { $0.id == Constants.weekly }
    }

    private func yearlyProduct() -> Product? {
        iap.products.first { $0.id == Constants.yearly }
    }

    private var weeklyFreeTrialOffer: Product.SubscriptionOffer? {
        guard weeklyTrialEligible,
              let offer = weeklyProduct()?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return offer
    }

    private var includesFreeTrial: Bool {
        selectedPlan == .weekly && weeklyFreeTrialOffer != nil
    }

    private func weeklyTitle() -> String {
        guard let offer = weeklyFreeTrialOffer else { return "Weekly Access" }
        let unit: String
        switch offer.period.unit {
        case .day: unit = "Day"
        case .week: unit = "Week"
        case .month: unit = "Month"
        case .year: unit = "Year"
        @unknown default: return "Free Trial"
        }
        return "\(offer.period.value)-\(unit) Free Trial"
    }

    private func weeklySubtitle() -> String {
        guard let product = weeklyProduct() else { return "Loading price…" }
        let prefix = weeklyFreeTrialOffer == nil ? "" : "then "
        return "\(prefix)\(product.displayPrice) / week"
    }

    private func weeklyBadge() -> String {
        guard let offer = weeklyFreeTrialOffer else { return "POPULAR" }
        return introBadge(from: offer.period) ?? "FREE TRIAL"
    }

    private func yearlySubtitle() -> String {
        guard let product = yearlyProduct() else { return "Loading price…" }
        return "\(product.displayPrice) / year"
    }

    private func introBadge(from period: Product.SubscriptionPeriod) -> String?
    {
        switch period.unit {
        case .day: return "\(period.value) DAYS FREE"
        case .week: return "\(period.value) WEEKS FREE"
        case .month: return "\(period.value) MONTHS FREE"
        case .year: return "\(period.value) YEARS FREE"
        @unknown default: return "FREE TRIAL"
        }
    }

}

struct PlanCard: View {
    let title: String
    let subtitle: String
    let badgeText: String
    let isSelected: Bool
    let planType: PlanType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.white)
                }

                Spacer()

                if planType == .yearly {

                    Text(badgeText)
                        .font(.system(size: 11, weight: .medium))
                        .fontWeight(.bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("MainColor"),
                                            Color("MainColor"),
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundStyle(.white)
                        .padding(.trailing, 10)

                }

                ZStack {
                    Circle()
                        .strokeBorder(
                            Color.gray.opacity(0.6),
                            lineWidth: 2
                        )
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(Color("MainColor"))
                            .frame(width: 20, height: 20)
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white)
                            .font(
                                .system(size: 12, weight: .bold)
                            )
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#000000"), Color(hex: "#000000"),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ).opacity(0.5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(hex: "#ffffff"),
                                        Color(hex: "#ffffff"),
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: isSelected ? 1 : 0
                            )
                    )
            )
        }
    }
}

struct FeatureTile<Line1: View, Line2: View>: View {
    @Environment(\.windowMetrics) private var windowMetrics
    let icon: String

    let line1: Line1
    let line2: Line2

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(
                    width: windowMetrics.isSmall ? 34 : 44,
                    height: windowMetrics.isSmall ? 34 : 44
                )

            VStack(alignment: .leading, spacing: 4) {
                line1
                    .font(
                        .system(size: windowMetrics.isSmall ? 13 : 16, weight: .regular)
                    )
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                line2
                    .font(
                        .system(size: windowMetrics.isSmall ? 13 : 16, weight: .regular)
                    )
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
