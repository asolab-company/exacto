import SwiftUI

struct BottomBarItem: Identifiable {
    var id: String { title }
    let title: String
    let iconName: String
    var locked: Bool = false
}

struct BottomBar: View {
    @Environment(\.windowMetrics) private var windowMetrics
    let items: [BottomBarItem]
    @Binding var selected: Int

    var onTap: ((Int) -> Void)? = nil
    var onLockedTap: ((Int) -> Void)? = nil

    var canSelect: ((BottomBarItem, Int) -> Bool)? = nil

    var activeColor: Color = Color("MainColor")
    var inactiveColor: Color = Color(hex: "7E7E7E")
    private var iconSize: CGFloat { windowMetrics.isSmall ? 26 : 32 }
    var lockBadgeSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                let isSelected = (i == selected)

                Button {

                    let allowedToUse = canSelect?(item, i) ?? !item.locked

                    selected = i

                    if item.locked && !allowedToUse {
                        onLockedTap?(i)
                    } else {
                        onTap?(i)
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack(alignment: .topTrailing) {
                            Image(item.iconName)
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(width: iconSize, height: iconSize)
                                .foregroundStyle(
                                    isSelected ? activeColor : inactiveColor
                                )

                            if item.locked {
                                Circle()
                                    .fill(.white)
                                    .frame(
                                        width: lockBadgeSize,
                                        height: lockBadgeSize
                                    )
                                    .overlay(
                                        Image("ic_lock")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 11, height: 11)
                                            .foregroundStyle(activeColor)
                                    )
                                    .offset(x: 10, y: -10)
                            }
                        }

                        Text(item.title)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(
                                isSelected ? activeColor : inactiveColor
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityValue(item.locked ? "Requires Premium" : "Available")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial).ignoresSafeArea(
                    edges: .bottom
                )
                Rectangle().fill(Color.black.opacity(0.76)).ignoresSafeArea(
                    edges: .bottom
                )
            }
        )
    }
}
