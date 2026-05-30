import SwiftUI

struct SplashView: View {
    @Environment(\.theme) private var t
    var onComplete: () -> Void

    @State private var dotIndex = 0
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            t.bg.ignoresSafeArea()

            VStack(spacing: 32) {
                TrackifyLogomark(size: 108)
                VStack(spacing: 8) {
                    Text("Trackify")
                        .font(.custom(Typography.geist, size: 36).weight(.semibold))
                        .kerning(-1.4)
                        .foregroundStyle(t.text)
                    Text("TRAIN · RUN · MEASURE")
                        .font(Typography.eyebrow)
                        .kerning(1.2)
                        .foregroundStyle(t.textMuted)
                }
            }
            .opacity(opacity)

            VStack {
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Capsule()
                            .fill(i == dotIndex ? t.accent : t.borderStrong)
                            .frame(width: i == dotIndex ? 22 : 6, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: dotIndex)
                    }
                }
                .padding(.bottom, 56)
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.4)) { opacity = 1 }
            Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
                dotIndex = (dotIndex + 1) % 3
                if dotIndex == 2 {
                    timer.invalidate()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onComplete() }
                }
            }
        }
    }
}

struct TrackifyLogomark: View {
    @Environment(\.theme) private var t
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(t.text)
                .frame(width: size, height: size)
            Path { path in
                let s = size / 100
                path.move(to:    CGPoint(x: 22*s, y: 62*s))
                path.addLine(to: CGPoint(x: 40*s, y: 44*s))
                path.addLine(to: CGPoint(x: 52*s, y: 56*s))
                path.addLine(to: CGPoint(x: 78*s, y: 30*s))
            }
            .stroke(t.accent, style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round, lineJoin: .round))
            Circle()
                .fill(t.accent)
                .frame(width: size * 0.1, height: size * 0.1)
                .offset(x: 78 * size/100 - size/2, y: 30 * size/100 - size/2)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ThemedRoot { SplashView(onComplete: {}) }
}
