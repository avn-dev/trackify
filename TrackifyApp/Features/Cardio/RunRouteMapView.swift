import SwiftUI
import MapKit
import CoreLocation

private let routeColor = Palette.accentLime

struct RunRouteMapView: View {
    var coordinates: [CLLocationCoordinate2D]
    var interactive: Bool = false

    private var cameraPosition: MapCameraPosition {
        guard coordinates.count > 1 else { return .automatic }
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.003, (lats.max()! - lats.min()!) * 1.6),
            longitudeDelta: max(0.003, (lons.max()! - lons.min()!) * 1.6)
        )
        return .region(MKCoordinateRegion(center: center, span: span))
    }

    var body: some View {
        if coordinates.count > 1 {
            Map(initialPosition: cameraPosition) {
                MapPolyline(coordinates: coordinates)
                    .stroke(routeColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                if let start = coordinates.first {
                    Annotation("", coordinate: start) {
                        Circle().fill(routeColor).frame(width: 9, height: 9)
                            .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    }
                }
                if let end = coordinates.last {
                    Annotation("", coordinate: end) {
                        Circle().fill(.white).frame(width: 9, height: 9)
                            .overlay(Circle().stroke(routeColor, lineWidth: 1.5))
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat))
            .allowsHitTesting(interactive)
        } else {
            MapPlaceholderView()
        }
    }
}

struct MapPlaceholderView: View {
    @Environment(\.theme) private var t
    var body: some View {
        ZStack {
            t.surface2
            Image(systemName: "map")
                .font(.system(size: 22))
                .foregroundStyle(t.textMuted)
        }
    }
}

func decodeRunCoordinates(_ data: Data) -> [CLLocationCoordinate2D] {
    guard let values = try? JSONDecoder().decode([Double].self, from: data),
          values.count >= 2 else { return [] }
    var coords: [CLLocationCoordinate2D] = []
    var i = 0
    while i + 1 < values.count {
        coords.append(CLLocationCoordinate2D(latitude: values[i], longitude: values[i + 1]))
        i += 2
    }
    return coords
}

func mockRouteCoordinates(center: CLLocationCoordinate2D = .init(latitude: 48.1551, longitude: 11.5418),
                          radiusLat: Double = 0.009, radiusLon: Double = 0.016,
                          points: Int = 80) -> Data {
    var values: [Double] = []
    for i in 0..<points {
        let angle = Double(i) / Double(points) * 2 * .pi
        values.append(center.latitude + radiusLat * sin(angle))
        values.append(center.longitude + radiusLon * cos(angle))
    }
    return (try? JSONEncoder().encode(values)) ?? Data()
}
