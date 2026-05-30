import SwiftUI

struct ScreenHeader<Action: View>: View {
    @Environment(\.theme) private var t
    var title: String
    var eyebrow: String? = nil
    var back: String? = nil
    var onBack: (() -> Void)? = nil
    @ViewBuilder var action: () -> Action

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                if let back {
                    Button {
                        onBack?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text(back).font(.custom(Typography.geist, size: 14))
                        }
                        .foregroundStyle(t.textMid)
                    }
                    .buttonStyle(.plain)
                }
                if let eyebrow {
                    Eyebrow(text: eyebrow)
                }
                Text(title)
                    .font(Typography.title(32))
                    .kerning(Tracking.titleTight)
                    .foregroundStyle(t.text)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            action()
        }
        .padding(.top, 54)
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, 14)
    }
}

extension ScreenHeader where Action == EmptyView {
    init(title: String, eyebrow: String? = nil, back: String? = nil, onBack: (() -> Void)? = nil) {
        self.title = title
        self.eyebrow = eyebrow
        self.back = back
        self.onBack = onBack
        self.action = { EmptyView() }
    }
}
