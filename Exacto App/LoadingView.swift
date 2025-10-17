import SwiftUI

struct Loading: View {
    var onFinish: () -> Void = {}

    @State private var progress: CGFloat = 0
    let barWidth = UIScreen.main.bounds.width * 0.6
    let icWidth = UIScreen.main.bounds.width * 0.7
    var body: some View {
        ZStack {
            Color(hex: "#383B3E")
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 20) {
                    Image("ic_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: Device.isSmall ? 160 : 230)

                }

                Spacer()

                VStack(spacing: 8) {
                    Text("\(Int(progress * 100))%")
                        .font(.custom("SFProDisplay-Regular", size: 18))
                        .foregroundColor(.white)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: barWidth, height: 8)

                        Capsule()
                            .fill(Color.init("MainColor"))
                            .frame(width: barWidth * progress, height: 8)
                            .animation(
                                .easeInOut(duration: 0.2),
                                value: progress
                            )
                    }
                }
                .padding(.bottom, 50)
                .frame(height: 50)
            }
            .padding(.horizontal, 20)

        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) {
                timer in
                if self.progress < 1.0 {
                    self.progress += 0.01
                } else {
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onFinish()
                    }
                }
            }
        }
    }
}

#Preview {
    Loading()
}
