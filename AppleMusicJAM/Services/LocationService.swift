import Foundation
import CoreLocation

/// Service for keeping the app alive in the background by tracking location.
///
/// This serves the dual purpose of powering the "Roadtrip Map" feature
/// and keeping the MQTT session alive indefinitely while in the background,
/// without requiring active audio playback or hacky audio sessions.
@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Singleton

    static let shared = LocationService()

    // MARK: - Private Properties

    private let locationManager = CLLocationManager()
    
    @Published var trackedLocations: [CLLocation] = []
    @Published var isTracking: Bool = false

    // MARK: - Initialization

    private override init() {
        super.init()
        locationManager.delegate = self
        // Set desired accuracy depending on needs. For a roadtrip map, 
        // hundredMeters is usually enough and saves battery compared to best.
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        // This is the critical property that allows continuous background execution.
        locationManager.allowsBackgroundLocationUpdates = true
        
        // Prevent the OS from automatically pausing updates if it thinks the user stopped.
        // We want continuous tracking for the session.
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - Public Methods

    /// Starts the location tracking, requesting authorization if necessary.
    func startTracking() {
        let status = locationManager.authorizationStatus
        
        if status == .notDetermined {
            // Request "Always" authorization so the app can track seamlessly in the background.
            locationManager.requestAlwaysAuthorization()
        } else if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            isTracking = true
            print("[LocationService] Started background location tracking.")
        } else {
            print("[LocationService] Location tracking denied or restricted.")
        }
    }
    
    /// Stops the location tracking.
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        isTracking = false
        print("[LocationService] Stopped background location tracking.")
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                manager.startUpdatingLocation()
                self.isTracking = true
                print("[LocationService] Authorization granted. Started background location tracking.")
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            self.trackedLocations.append(location)
            // Here we could correlate `location` with `MusicPlayerService.shared.currentSong` 
            // to build the Roadtrip Map data model.
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationService] Location update failed: \(error.localizedDescription)")
    }
}
