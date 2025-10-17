import StoreKit
import SwiftUI

enum PlanType {
    case weekly, yearly
}

struct PayWall: View {
    @EnvironmentObject var iap: IAPManager

    @State private var currentTab = 0

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
                            .foregroundColor(.white)
                    }

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
                                .custom(
                                    "SFProDisplay-Heavy",
                                    size: Device.isSmall ? 22 : 28
                                )
                            )
                            .foregroundColor(Color("MainColor"))
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
                                line2: Text("Room Plan").foregroundColor(
                                    Color("MainColor")
                                )
                            )

                            FeatureTile(
                                icon: "app_ic_paywall01",

                                line1: Text("Take ")
                                    + Text("unlimited").foregroundColor(
                                        Color("MainColor")
                                    ),
                                line2: Text("measurements")
                            )

                            FeatureTile(
                                icon: "app_ic_paywall03",

                                line1: Text("Auto-calculate").foregroundColor(
                                    Color("MainColor")
                                ),
                                line2: Text("perimeter")
                            )

                            FeatureTile(
                                icon: "app_ic_paywall02",

                                line1: Text("Measure").foregroundColor(
                                    Color("MainColor")
                                ),
                                line2: Text("the level")
                            )
                        }
                        .padding(.bottom)

                        HStack {
                            Text("Free Trial Enabled")
                                .foregroundColor(
                                    selectedPlan == .weekly
                                        ? .white : Color.init(hex: "7E7E7E")
                                )
                                .font(.custom("SFProDisplay-Medium", size: 15))
                                .dynamicTypeSize(.medium ... .xxLarge)

                            Spacer()

                            Toggle("", isOn: $isTrialEnabled)
                                .labelsHidden()
                                .tint(Color(hex: "#419400"))
                                .onChange(of: isTrialEnabled) { newValue in
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
                                let result = try await product.purchase()
                                switch result {
                                case .success(let verification):
                                    switch verification {
                                    case .verified(let tx):
                                        await tx.finish()
                                        await iap.refreshEntitlements()
                                        dismiss()
                                    case .unverified(_, let error):
                                        purchaseMessage =
                                            "Purchase couldn’t be verified: \(error.localizedDescription)"
                                    }
                                case .userCancelled:
                                    break
                                case .pending:
                                    purchaseMessage =
                                        "Your purchase is pending approval."
                                @unknown default:
                                    break
                                }
                            } catch {
                                purchaseMessage = error.localizedDescription
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Continue")
                                .foregroundColor(.white)
                                .font(.custom("SFProDisplay-Bold", size: 16))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color("MainColor"))
                        .cornerRadius(10)
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
                                isTrialEnabled
                                    ? "No Payment Now" : "Cancel Anytime"
                            )
                            .font(.custom("SFProDisplay-Bold", size: 13))
                            .foregroundColor(Color(hex: "ffffff"))
                        }

                        HStack(spacing: 40) {
                            Button(action: {
                                UIApplication.shared.open(Constants.privacyURL)
                            }) {
                                Text("Privacy Policy")
                                    .font(
                                        .custom(
                                            "SFProDisplay-Regular",
                                            size: 14
                                        )
                                    )
                                    .foregroundColor(Color(hex: "#BDBDBD"))
                            }

                            Button(action: {
                                Task {
                                    await iap.restore()

                                }
                            }) {
                                Text("Restore")
                                    .font(
                                        .custom(
                                            "SFProDisplay-Regular",
                                            size: 14
                                        )
                                    )
                                    .foregroundColor(Color(hex: "#BDBDBD"))
                            }

                            Button(action: {
                                UIApplication.shared.open(Constants.termsURL)
                            }) {
                                Text("Terms of Use")
                                    .font(
                                        .custom(
                                            "SFProDisplay-Regular",
                                            size: 14
                                        )
                                    )
                                    .foregroundColor(Color(hex: "#BDBDBD"))
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

        }.task {
            if iap.products.isEmpty {
                await iap.fetchProducts()
            }
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

    private func weeklyTitle() -> String {
        if let offer = weeklyProduct()?.subscription?.introductoryOffer,
            offer.type == .introductory, offer.price == 0
        {
            return "3–Days Free Trial"
        }
        return "Weekly Access"
    }

    private func weeklySubtitle() -> String {
        guard let product = weeklyProduct() else { return "$9.99 / week" }
        if let offer = product.subscription?.introductoryOffer,
            offer.type == .introductory, offer.price == 0
        {
            return "then \(product.displayPrice) / week"
        }
        return "\(product.displayPrice) / week"
    }

    private func weeklyBadge() -> String {
        if let offer = weeklyProduct()?.subscription?.introductoryOffer,
            offer.type == .introductory, offer.price == 0
        {
            return introBadge(from: offer.period) ?? "FREE TRIAL"
        }
        return "POPULAR"
    }

    private func yearlySubtitle() -> String {
        guard let product = yearlyProduct() else { return "$44.99 / year" }
        return "\(product.displayPrice) / year"
    }

    private func continueButtonTitle() -> String {
        guard
            let product =
                (selectedPlan == .weekly ? weeklyProduct() : yearlyProduct())
        else { return "Continue" }
        if let offer = product.subscription?.introductoryOffer,
            offer.type == .introductory, offer.price == 0
        {
            return "Continue"
        }
        return "Continue – \(product.displayPrice)"
    }

    private func bottomHint() -> String {
        if let product =
            (selectedPlan == .weekly ? weeklyProduct() : yearlyProduct()),
            let offer = product.subscription?.introductoryOffer,
            offer.type == .introductory, offer.price == 0
        {
            return "No Payment Now"
        }
        return "Cancel Anytime"
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
                        .font(.custom("SFProDisplay-Medium", size: 15))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.custom("SFProDisplay-Regular", size: 12))
                        .foregroundColor(.white)
                }

                Spacer()

                if planType == .yearly {

                    Text(badgeText)
                        .font(.custom("SFProDisplay-Medium", size: 11))
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
                        .foregroundColor(.white)
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
                            .foregroundColor(.white)
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
    let icon: String

    let line1: Line1
    let line2: Line2

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(
                    width: Device.isSmall ? 34 : 44,
                    height: Device.isSmall ? 34 : 44
                )

            VStack(alignment: .leading, spacing: 4) {
                line1
                    .font(
                        .custom(
                            "SFProDisplay-Regular",
                            size: Device.isSmall ? 13 : 16
                        )
                    )
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                line2
                    .font(
                        .custom(
                            "SFProDisplay-Regular",
                            size: Device.isSmall ? 13 : 16
                        )
                    )
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PayWall()
        .environmentObject(IAPManager.shared)
}
