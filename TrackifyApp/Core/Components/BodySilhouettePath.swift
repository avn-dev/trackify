import SwiftUI

/// A simplified human body outline as a SwiftUI Shape.
/// All coordinates are normalised to a 1×1 unit square and scaled to the bounding rect.
struct BodySilhouettePath: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height

        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: w * x, y: h * y) }
        func c(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: w * x, y: h * y) } // alias for readability

        var path = Path()

        // ── HEAD ──────────────────────────────────────────────────────────────
        path.addEllipse(in: CGRect(x: w * 0.355, y: h * 0.01, width: w * 0.29, height: h * 0.145))

        // ── TORSO + ARMS ──────────────────────────────────────────────────────
        // Start at left neck base
        path.move(to: p(0.38, 0.145))

        // Left shoulder curve
        path.addCurve(to: p(0.20, 0.215),
                      control1: c(0.30, 0.155),
                      control2: c(0.22, 0.185))

        // Left upper arm outer
        path.addLine(to: p(0.155, 0.375))

        // Left wrist / hand
        path.addLine(to: p(0.175, 0.490))
        path.addLine(to: p(0.225, 0.490))

        // Left upper arm inner (back up)
        path.addLine(to: p(0.245, 0.370))

        // Left armpit → left torso
        path.addCurve(to: p(0.285, 0.430),
                      control1: c(0.255, 0.240),
                      control2: c(0.260, 0.370))

        // Left torso narrows to waist
        path.addCurve(to: p(0.280, 0.460),
                      control1: c(0.270, 0.435),
                      control2: c(0.270, 0.450))

        // Left hip widens
        path.addCurve(to: p(0.285, 0.540),
                      control1: c(0.262, 0.482),
                      control2: c(0.262, 0.530))

        // Left thigh outer
        path.addLine(to: p(0.265, 0.720))

        // Left knee
        path.addCurve(to: p(0.270, 0.760),
                      control1: c(0.258, 0.735),
                      control2: c(0.258, 0.752))

        // Left calf outer
        path.addLine(to: p(0.275, 0.900))

        // Left foot
        path.addCurve(to: p(0.335, 0.940),
                      control1: c(0.270, 0.928),
                      control2: c(0.305, 0.940))

        // Left inner leg bottom → up
        path.addLine(to: p(0.335, 0.760))
        path.addLine(to: p(0.340, 0.640))

        // Crotch
        path.addCurve(to: p(0.500, 0.590),
                      control1: c(0.345, 0.580),
                      control2: c(0.430, 0.575))
        path.addCurve(to: p(0.660, 0.640),
                      control1: c(0.570, 0.575),
                      control2: c(0.655, 0.580))

        // Right inner leg
        path.addLine(to: p(0.665, 0.760))
        path.addLine(to: p(0.665, 0.940))

        // Right foot
        path.addCurve(to: p(0.725, 0.900),
                      control1: c(0.695, 0.940),
                      control2: c(0.730, 0.928))

        // Right calf outer
        path.addLine(to: p(0.730, 0.760))

        // Right knee
        path.addCurve(to: p(0.735, 0.720),
                      control1: c(0.742, 0.752),
                      control2: c(0.742, 0.735))

        // Right thigh outer
        path.addLine(to: p(0.715, 0.540))

        // Right hip → waist
        path.addCurve(to: p(0.720, 0.460),
                      control1: c(0.738, 0.530),
                      control2: c(0.738, 0.482))

        path.addCurve(to: p(0.715, 0.430),
                      control1: c(0.730, 0.450),
                      control2: c(0.730, 0.435))

        // Right torso → armpit
        path.addCurve(to: p(0.755, 0.370),
                      control1: c(0.740, 0.370),
                      control2: c(0.745, 0.240))

        // Right arm inner (back down)
        path.addLine(to: p(0.775, 0.490))
        path.addLine(to: p(0.825, 0.490))

        // Right wrist → upper arm outer
        path.addLine(to: p(0.845, 0.375))

        // Right shoulder curve → right neck
        path.addCurve(to: p(0.620, 0.145),
                      control1: c(0.778, 0.185),
                      control2: c(0.700, 0.155))

        path.closeSubpath()

        return path
    }
}

#Preview {
    BodySilhouettePath()
        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
        .frame(width: 140, height: 360)
        .padding()
        .background(Color(red: 0.06, green: 0.06, blue: 0.07))
}
