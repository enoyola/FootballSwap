import Foundation
import CoreLocation

/// Thin async wrapper over CoreLocation for one-shot "where am I" lookups.
/// When-in-use only; no background tracking.
@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()
    private var locationContinuations: [CheckedContinuation<CLLocationCoordinate2D?, Never>] = []

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer // city-level is plenty
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestPermission() {
        #if DEBUG
        // Suppress the system prompt during automated screenshots (-uiScreenshots).
        if UserDefaults.standard.bool(forKey: "uiScreenshots") { return }
        #endif
        manager.requestWhenInUseAuthorization()
    }

    /// Requests a single location fix. Returns nil if unauthorized or it fails.
    func currentLocation() async -> CLLocationCoordinate2D? {
        guard isAuthorized else { return nil }
        return await withCheckedContinuation { continuation in
            locationContinuations.append(continuation)
            manager.requestLocation()
        }
    }

    /// Geocodes a free-text place (e.g. a profile city) to a coordinate. Used as a
    /// fallback for "near me" when device GPS isn't available. Results are cached
    /// for the session so repeated loads don't re-hit CLGeocoder (which is rate-limited).
    private static var cityCache: [String: CLLocationCoordinate2D] = [:]

    static func coordinate(forCity city: String) async -> CLLocationCoordinate2D? {
        let trimmed = city.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        if let cached = cityCache[trimmed] { return cached }
        guard let coord = try? await CLGeocoder().geocodeAddressString(trimmed).first?.location?.coordinate
        else { return nil }
        cityCache[trimmed] = coord
        return coord
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        resume(with: coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resume(with: nil)
    }

    private func resume(with coordinate: CLLocationCoordinate2D?) {
        let pending = locationContinuations
        locationContinuations.removeAll()
        for continuation in pending { continuation.resume(returning: coordinate) }
    }
}
