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
                                .foregroundStyle(.white)
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(Color("MainColor"))
                        .clipShape(.rect(cornerRadius: 10))

                        .opacity(currentTab == 3 && isPreparing ? 0.5 : 1.0)
                    }
                    .disabled(currentTab == 3 && isPreparing)
                    .frame(height: 55)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 10)

                    if !(currentTab == 3 && isPreparing) {
                        VStack(spacing: 2) {
                            Text("By Proceeding You Accept")
                                .foregroundStyle(Color(hex: "BABABA"))
                                .font(.system(size: 13, weight: .medium))
                            HStack(spacing: 4) {
                                Text("Our")
                                    .foregroundStyle(Color(hex: "BABABA"))
                                    .font(
                                        .system(size: 13, weight: .medium)
                                    )
                                Button {
                                    UIApplication.shared.open(
                                        Constants.termsURL
                                    )
                                } label: {
                                    Text("Terms Of Use")
                                        .foregroundStyle(Color("MainColor"))
                                        .font(
                                            .system(size: 13, weight: .medium)
                                        )
                                }
                                Text("And")
                                    .foregroundStyle(Color(hex: "BABABA"))
                                    .font(
                                        .system(size: 13, weight: .medium)
                                    )
                                Button {
                                    UIApplication.shared.open(
                                        Constants.privacyURL
                                    )
                                } label: {
                                    Text("Privacy Policy")
                                        .foregroundStyle(Color("MainColor"))
                                        .font(
                                            .system(size: 13, weight: .medium)
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
                                .foregroundStyle(Color(hex: "BABABA"))
                                .font(.system(size: 13, weight: .medium))
                            HStack(spacing: 4) {
                                Text("")
                                    .foregroundStyle(Color(hex: "BABABA"))
                                    .font(
                                        .system(size: 13, weight: .medium)
                                    )
                                Button {

                                } label: {
                                    Text("")
                                        .foregroundStyle(Color("MainColor"))
                                        .font(
                                            .system(size: 13, weight: .medium)
                                        )
                                }
                                Text("")
                                    .foregroundStyle(Color(hex: "BABABA"))
                                    .font(
                                        .system(size: 13, weight: .medium)
                                    )
                                Button {

                                } label: {
                                    Text("")
                                        .foregroundStyle(Color("MainColor"))
                                        .font(
                                            .system(size: 13, weight: .medium)
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
    @Environment(\.windowMetrics) private var windowMetrics
    var body: some View {

        VStack {
            Image("app_ic_onbording01")
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
                .offset(y: windowMetrics.isSmall ? -140 : 0)

            Spacer()
        }

    }
}

struct OnboardingScreen2: View {
    @Environment(\.windowMetrics) private var windowMetrics
    @ScaledMetric(relativeTo: .title) private var titleSize = 32.0
    var body: some View {

        ZStack {

            VStack {
                Image("app_ic_onbording02")
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()
                    .offset(y: windowMetrics.isSmall ? -140 : 0)

                Spacer()
            }

            VStack {
                Spacer()
                Text("Measure Length")
                    .font(
                        .system(size: titleSize, weight: .heavy)
                    )
                    .foregroundStyle(Color("MainColor"))

                Text(
                    "Use your camera to measure\nlength of rooms or objects"
                )
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color(hex: "ffffff"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            }.padding(.bottom, 170)

        }
    }
}

struct OnboardingScreen3: View {
    @Environment(\.windowMetrics) private var windowMetrics
    @ScaledMetric(relativeTo: .title) private var titleSize = 32.0
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
                    .offset(y: windowMetrics.isSmall ? -160 : 0)

                Spacer()
            }

            VStack {
                Spacer()
                Text("Choose units")
                    .font(
                        .system(size: titleSize, weight: .heavy)
                    )
                    .foregroundStyle(Color("MainColor"))

                Text(
                    "We’ll make sure that the app displays\nmeasurements in selected units"
                )
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(Color(hex: "ffffff"))
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
                                            .system(size: 14, weight: .medium)
                                        )
                                        .foregroundStyle(.white)

                                    Text(system.description)
                                        .font(
                                            .system(size: 11, weight: .regular)
                                        )
                                        .foregroundStyle(.white)
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
                                            .foregroundStyle(.white)
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
                                        Color.black.opacity(50).clipShape(.rect(cornerRadius: 10))
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
    @Environment(\.windowMetrics) private var windowMetrics
    @ScaledMetric(relativeTo: .title) private var titleSize = 32.0
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

    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    Image("app_ic_onbording04")
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                        .offset(y: windowMetrics.isSmall ? -160 : 0)

                    CircleProgressView(progress: $totalProgress)
                        .offset(y: windowMetrics.isSmall ? -90 : -60)
                }
                Spacer()
            }

            VStack {
                Spacer()
                Text("Preparing the app")
                    .font(
                        .system(size: titleSize, weight: .heavy)
                    )
                    .foregroundStyle(Color("MainColor"))

                ForEach(steps.indices, id: \.self) { idx in
                    HStack {
                        Text(steps[idx].title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        if completed.contains(idx) {
                            ZStack {
                                Circle().fill(Color(hex: "419400"))
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.white)
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
        .task {
            isPreparing = true
            do {
                try await runSequence()
            } catch {
                isPreparing = false
            }
        }
    }

    private func runSequence() async throws {
        completed.removeAll()
        totalProgress = 0

        for idx in steps.indices {
            currentStepIndex = idx
            stepProgress = 0
            let frames = 60
            for frame in 0...frames {
                try await Task.sleep(for: .seconds(stepDuration / Double(frames)))
                let progress = CGFloat(frame) / CGFloat(frames)
                withAnimation(.linear(duration: stepDuration / Double(frames))) {
                    stepProgress = progress
                }
                totalProgress = (CGFloat(idx) + progress) / CGFloat(steps.count)
            }
            completed.insert(idx)
            stepProgress = 0
        }
        totalProgress = 1
        isPreparing = false
    }
}

struct CircleProgressView: View {
    @Environment(\.windowMetrics) private var windowMetrics
    @Binding var progress: CGFloat

    private var size: CGFloat { windowMetrics.isSmall ? 190 : 250 }
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
                .font(.system(size: 48, weight: .black))
                .foregroundStyle(.white)
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
