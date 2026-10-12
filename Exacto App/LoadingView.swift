import SwiftUI

struct Loading: View {
    @Environment(\.windowMetrics) private var windowMetrics
    var onFinish: () -> Void = {}
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width * 0.6
            ZStack {
                Color(hex: "#383B3E")
                    .ignoresSafeArea()

                VStack {
                    Spacer()
                    Image("ic_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: windowMetrics.isSmall ? 160 : 230)
                    Spacer()

                    VStack(spacing: 8) {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(.white)

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: barWidth, height: 8)
                            Capsule()
                                .fill(Color("MainColor"))
                                .frame(width: barWidth * progress, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: progress)
                        }
                    }
                    .padding(.bottom, 50)
                    .frame(height: 50)
                }
                .padding(.horizontal, 20)
            }
        }
        .task {
            progress = 0
            do {
                for step in 1...100 {
                    try await Task.sleep(for: .milliseconds(20))
                    progress = CGFloat(step) / 100
                }
                try await Task.sleep(for: .milliseconds(500))
                onFinish()
            } catch {
            }
        }
    }
}
