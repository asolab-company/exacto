import SwiftUI

struct BottomBarItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    var locked: Bool = false
}

struct BottomBar: View {
    let items: [BottomBarItem]
    @Binding var selected: Int

    var onTap: ((Int) -> Void)? = nil
    var onLockedTap: ((Int) -> Void)? = nil

    var canSelect: ((BottomBarItem, Int) -> Bool)? = nil

    var activeColor: Color = Color("MainColor")
    var inactiveColor: Color = Color(hex: "7E7E7E")
    var iconSize: CGFloat = Device.isSmall ? 26 : 32
    var lockBadgeSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                let item = items[i]
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
                                .foregroundColor(
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
                                            .foregroundColor(activeColor)
                                    )
                                    .offset(x: 10, y: -10)
                            }
                        }

                        Text(item.title)
                            .font(.custom("SFProDisplay-Regular", size: 12))
                            .foregroundColor(
                                isSelected ? activeColor : inactiveColor
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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

#Preview {
    StatefulPreviewWrapper(0) { selected in
        ZStack {
            Color(hex: "#383B3E")
                .ignoresSafeArea()
            VStack {
                Spacer()
                BottomBar(
                    items: [
                        BottomBarItem(
                            title: "Measure",
                            iconName: "app_btn_menu05",
                            locked: false
                        ),
                        BottomBarItem(
                            title: "Square",
                            iconName: "app_btn_menu03",
                            locked: true
                        ),
                        BottomBarItem(
                            title: "Height",
                            iconName: "app_btn_menu04",
                            locked: true
                        ),
                        BottomBarItem(
                            title: "Level",
                            iconName: "app_btn_menu02",
                            locked: true
                        ),
                        BottomBarItem(
                            title: "Ruler",
                            iconName: "app_btn_menu01",
                            locked: true
                        ),
                    ],
                    selected: selected,
                    onTap: { idx in
                        print("Selected: \(idx)")
                    },
                    onLockedTap: { idx in
                        print("Locked item tapped: \(idx)")
                    }
                )

            }
        }
    }
}

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State private var value: Value
    private let content: (Binding<Value>) -> Content

    init(
        _ initialValue: Value,
        @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        content($value)
    }
}
