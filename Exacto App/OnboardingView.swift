import SwiftUI

enum UnitSystem: String, CaseIterable {
    case metric = "Metric System"
    case imperial = "Imperial System"

    var description: String {
        switch self {
        case .metric: return "Meters"
        case .imperial: return "Feet, inches"
        }
    }
}

enum Prefs {
    static let unitSystemKey = "unit_system"
}

struct Onboarding: View {
    @State private var currentTab = 0
    @State private var isPreparing = false

    var onFinish: () -> Void = {}

    var body: some View {
        ZStack {

            TabView(selection: $currentTab) {
                OnboardingScreen1()
                    .tag(0)
                OnboardingScreen2()
                    .tag(1)
                OnboardingScreen3()
                    .tag(2)
                OnboardingScreen4(isPreparing: $isPreparing)
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .background(
                ZStack(alignment: .top) {
                    Color(hex: "383B3E").ignoresSafeArea()
                    Image("onb_top")
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                }
            )
            .ignoresSafeArea()
            .overlay(
                Group {
                    if currentTab == 3 && isPreparing {
                        Color.clear
                            .contentShape(Rectangle())
                            .ignoresSafeArea()
                            .allowsHitTesting(true)
                    }
                }
            )
            .overlay(
                VStack {
                    Spacer()

                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(
                                    index == currentTab
                                        ? Color("MainColor")
                                        : Color(hex: ("BABABA"))
                                )
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 10)

                    Button(action: {
                        if currentTab < 3 {
                            currentTab += 1
                        } else {
                            UserDefaults.standard.set(
                                true,
                                forKey: "onboarding_passed"
                            )
                            onFinish()
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

                        .opacity(currentTab == 3 && isPreparing ? 0.5 : 1.0)
                    }
                    .disabled(currentTab == 3 && isPreparing)
                    .frame(height: 55)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 10)

                    if !(currentTab == 3 && isPreparing) {
                        VStack(spacing: 2) {
                            Text("By Proceeding You Accept")
                                .foregroundColor(Color(hex: "BABABA"))
                                .font(.custom("SFProDisplay-Medium", size: 13))
                            HStack(spacing: 4) {
                                Text("Our")
                                    .foregroundColor(Color(hex: "BABABA"))
                                    .font(
                                        .custom("SFProDisplay-Medium", size: 13)
                                    )
                                Button {
                                    UIApplication.shared.open(
                                        Constants.termsURL
                                    )
                                } label: {
                                    Text("Terms Of Use")
                                        .foregroundColor(Color("MainColor"))
                                        .font(
                                            .custom(
                                                "SFProDisplay-Medium",
                                                size: 13
                                            )
                                        )
                                }
                                Text("And")
                                    .foregroundColor(Color(hex: "BABABA"))
                                    .font(
                                        .custom("SFProDisplay-Medium", size: 13)
                                    )
                                Button {
                                    UIApplication.shared.open(
                                        Constants.privacyURL
                                    )
                                } label: {
                                    Text("Privacy Policy")
                                        .foregroundColor(Color("MainColor"))
                                        .font(
                                            .custom(
                                                "SFProDisplay-Medium",
                                                size: 13
                                            )
                                        )
                                }
                            }
                        }
                        .opacity(currentTab == 0 ? 1 : 0)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    }

                    if currentTab == 3 && isPreparing {
                        VStack(spacing: 2) {
                            Text("It will just take a couple of seconds")
                                .foregroundColor(Color(hex: "BABABA"))
                                .font(.custom("SFProDisplay-Medium", size: 13))
                            HStack(spacing: 4) {
                                Text("")
                                    .foregroundColor(Color(hex: "BABABA"))
                                    .font(
                                        .custom("SFProDisplay-Medium", size: 13)
                                    )
                                Button {

                                } label: {
                                    Text("")
                                        .foregroundColor(Color("MainColor"))
                                        .font(
                                            .custom(
                                                "SFProDisplay-Medium",
                                                size: 13
                                            )
                                        )
                                }
                                Text("")
                                    .foregroundColor(Color(hex: "BABABA"))
                                    .font(
                                        .custom("SFProDisplay-Medium", size: 13)
                                    )
                                Button {

                                } label: {
                                    Text("")
                                        .foregroundColor(Color("MainColor"))
                                        .font(
                                            .custom(
                                                "SFProDisplay-Medium",
                                                size: 13
                                            )
                                        )
                                }
                            }
                        }

                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                    }

                }
            )

        }

    }
}

struct OnboardingScreen1: View {
    var body: some View {

        VStack {
            Image("app_ic_onbording01")
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
                .offset(y: Device.isSmall ? -140 : 0)

            Spacer()
        }

    }
}

struct OnboardingScreen2: View {
    var body: some View {

        ZStack {

            VStack {
                Image("app_ic_onbording02")
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .offset(y: Device.isSmall ? -140 : 0)

                Spacer()
            }

            VStack {
                Spacer()
                Text("Measure Length")
                    .font(
                        .custom(
                            "SFProDisplay-Heavy",
                            size: 32,
                            relativeTo: .title
                        )
                    )
                    .foregroundColor(Color("MainColor"))

                Text(
                    "Use your camera to measure\nlength of rooms or objects"
                )
                .font(.custom("SFProDisplay-Regular", size: 16))
                .foregroundColor(Color(hex: "ffffff"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            }.padding(.bottom, 170)

        }
    }
}

struct OnboardingScreen3: View {
    @AppStorage(Prefs.unitSystemKey)
    private var unitRaw: String = UnitSystem.metric.rawValue

    private var selected: UnitSystem {
        UnitSystem(rawValue: unitRaw) ?? .metric
    }

    var body: some View {
        ZStack {
            VStack {
                Image("app_ic_onbording03")
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .offset(y: Device.isSmall ? -160 : 0)

                Spacer()
            }

            VStack {
                Spacer()
                Text("Choose units")
                    .font(
                        .custom(
                            "SFProDisplay-Heavy",
                            size: 32,
                            relativeTo: .title
                        )
                    )
                    .foregroundColor(Color("MainColor"))

                Text(
                    "We’ll make sure that the app displays\nmeasurements in selected units"
                )
                .font(.custom("SFProDisplay-Regular", size: 16))
                .foregroundColor(Color(hex: "ffffff"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.bottom)

                VStack(spacing: 10) {
                    ForEach(UnitSystem.allCases, id: \.self) { system in
                        let isSelected = (selected == system)

                        Button {
                            unitRaw = system.rawValue
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(system.rawValue)
                                        .font(
                                            .custom(
                                                "SFProDisplay-Medium",
                                                size: 14
                                            )
                                        )
                                        .foregroundColor(.white)

                                    Text(system.description)
                                        .font(
                                            .custom(
                                                "SFProDisplay-Regular",
                                                size: 11
                                            )
                                        )
                                        .foregroundColor(.white)
                                }
                                Spacer()

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
                            .padding(.vertical, 8)
                            .padding(.horizontal, 30)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        isSelected ? Color.white : Color.clear,
                                        lineWidth: 2
                                    )
                                    .background(
                                        Color.black.opacity(50).cornerRadius(10)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 30)
            }
            .padding(.bottom, 170)
        }
    }
}

struct OnboardingScreen4: View {
    @Binding var isPreparing: Bool

    struct Step: Identifiable {
        let id = UUID()
        let title: String
    }

    private let steps: [Step] = [
        .init(title: "Adapting The Interface To Your Needs"),
        .init(title: "Starting Up All Necessary Functions"),
        .init(title: "Preparing Your First Measurement"),
    ]

    var stepDuration: TimeInterval = 1.6
    var ringSize: CGFloat = 20
    var ringLineWidth: CGFloat = 2

    @State private var currentStepIndex: Int = 0
    @State private var stepProgress: CGFloat = 0.0
    @State private var totalProgress: CGFloat = 0.0
    @State private var completed: Set<Int> = []
    @State private var didStart = false

    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    Image("app_ic_onbording04")
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                        .offset(y: Device.isSmall ? -160 : 0)

                    CircleProgressView(progress: $totalProgress)
                        .offset(y: Device.isSmall ? -90 : -60)
                }
                Spacer()
            }

            VStack {
                Spacer()
                Text("Preparing the app")
                    .font(
                        .custom(
                            "SFProDisplay-Heavy",
                            size: 32,
                            relativeTo: .title
                        )
                    )
                    .foregroundColor(Color("MainColor"))

                ForEach(steps.indices, id: \.self) { idx in
                    HStack {
                        Text(steps[idx].title)
                            .font(.custom("SFProDisplay-Medium", size: 14))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if completed.contains(idx) {
                            ZStack {
                                Circle().fill(Color(hex: "419400"))
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .frame(width: ringSize, height: ringSize)
                        } else if currentStepIndex == idx {
                            CircularProgress(
                                progress: stepProgress,
                                size: ringSize,
                                lineWidth: ringLineWidth
                            )
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: ringSize, height: ringSize)
                        }
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.5))
                    )
                }
            }
            .padding(.horizontal, 30)
        }
        .padding(.bottom, 170)
        .onAppear {

            guard !didStart else { return }
            didStart = true
            isPreparing = true
            runSequence()
        }
    }

    private func runSequence() {
        Task {
            completed.removeAll()
            totalProgress = 0

            for idx in steps.indices {
                currentStepIndex = idx
                stepProgress = 0

                let frames = 60
                for f in 0...frames {
                    try? await Task.sleep(
                        nanoseconds: UInt64(
                            (stepDuration / Double(frames)) * 1_000_000_000
                        )
                    )
                    let p = CGFloat(f) / CGFloat(frames)

                    await MainActor.run {
                        withAnimation(
                            .linear(duration: stepDuration / Double(frames))
                        ) {
                            stepProgress = p
                        }
                        totalProgress =
                            (CGFloat(idx) + p) / CGFloat(steps.count)
                    }
                }

                await MainActor.run {
                    completed.insert(idx)
                    stepProgress = 0
                }
            }

            await MainActor.run {
                totalProgress = 1.0
                isPreparing = false
            }
        }
    }
}

struct CircleProgressView: View {
    @Binding var progress: CGFloat

    let size: CGFloat = Device.isSmall ? 190 : 250
    let lineWidth: CGFloat = 10

    var body: some View {
        ZStack {

            Circle()
                .fill(Color.black.opacity(0.5))
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    Color("MainColor"),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
                .animation(.linear(duration: 0.05), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.custom("SFProDisplay-Black", size: 48))
                .foregroundColor(.white)
        }
    }
}

struct CircularProgress: View {
    let progress: CGFloat
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(
                    Color.white.opacity(0.9),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: progress)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    Onboarding()
}
