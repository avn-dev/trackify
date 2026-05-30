import SwiftUI

struct PrimaryButton: View {
    @Environment(\.theme) private var t
    var title: String
    var systemIcon: String? = nil
    var fullWidth: Bool = true
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                HStack(spacing: 8) {
                    if let systemIcon {
                        Image(systemName: systemIcon).font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(.custom(Typography.geist, size: 16).weight(.semibold))
                }
                .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .tint(t.accentText)
                }
            }
            .foregroundStyle(t.accentText)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 52)
            .padding(.horizontal, fullWidth ? 0 : 24)
            .background(Capsule().fill(t.accent))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

struct GhostButton: View {
    @Environment(\.theme) private var t
    var title: String
    var systemIcon: String? = nil
    var fullWidth: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemIcon {
                    Image(systemName: systemIcon).font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(.custom(Typography.geist, size: 15).weight(.medium))
            }
            .foregroundStyle(t.text)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 52)
            .padding(.horizontal, fullWidth ? 0 : 24)
            .overlay(Capsule().stroke(t.borderStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct CircleBtn: View {
    @Environment(\.theme) private var t
    var systemIcon: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemIcon)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(t.text)
                .frame(width: 40, height: 40)
                .background(Circle().fill(t.surface2))
                .overlay(Circle().stroke(t.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
