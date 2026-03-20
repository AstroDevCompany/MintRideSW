import CoreLocation
import CoreMotion
import Foundation

@MainActor
final class TelemetryManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentSpeedMPS: Double = 0
    @Published private(set) var peakSpeedMPS: Double = 0
    @Published private(set) var sessionDistanceMeters: Double = 0
    @Published private(set) var accelerationG: Double = 0
    @Published private(set) var peakAccelerationG: Double = 0
    @Published private(set) var currentAltitudeMeters: Double = 0
    @Published private(set) var benchmarkResults: [BenchmarkResult]
    @Published private(set) var gpsStatusText = "GPS idle"
    @Published private(set) var motionStatusText = "Motion idle"
    @Published private(set) var isRunActive = false

    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()
    private let tracker: RunTrackerCore

    private var cumulativeDistanceMeters: Double = 0
    private var sessionDistanceOrigin: Double = 0
    private var lastLocation: CLLocation?

    init(unit: DisplayUnit) {
        authorizationStatus = locationManager.authorizationStatus
        tracker = RunTrackerCore(unit: unit)
        benchmarkResults = tracker.results
        super.init()
        locationManager.delegate = self
        locationManager.activityType = .automotiveNavigation
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    var permissionSummary: String {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            "GPS access is enabled."
        case .denied, .restricted:
            "Enable Location Services in Settings to unlock speed and distance timing."
        case .notDetermined:
            "Grant location access to start 0-100 and distance timing."
        @unknown default:
            "Location permission state is unknown."
        }
    }

    var hasGPSPermission: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    func startTracking() {
        requestPermissions()
        startMotionUpdates()

        guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse else {
            gpsStatusText = "Waiting for GPS permission"
            return
        }

        locationManager.startUpdatingLocation()
        gpsStatusText = "GPS starting"
    }

    func requestPermissions() {
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func updateUnit(_ unit: DisplayUnit) {
        tracker.configure(for: unit)
        benchmarkResults = tracker.results
        sessionDistanceOrigin = cumulativeDistanceMeters
        sessionDistanceMeters = 0
        peakSpeedMPS = 0
        isRunActive = false
    }

    func resetBenchmarks() {
        tracker.resetBenchmarks()
        benchmarkResults = tracker.results
        sessionDistanceOrigin = cumulativeDistanceMeters
        sessionDistanceMeters = 0
        peakSpeedMPS = 0
        peakAccelerationG = 0
        isRunActive = false
    }

    func resetBenchmark(id: String) {
        tracker.resetBenchmark(id: id)
        benchmarkResults = tracker.results
    }

    func resetDistanceSession() {
        sessionDistanceOrigin = cumulativeDistanceMeters
        sessionDistanceMeters = 0
    }

    func resetPeakSpeed() {
        tracker.resetPeakSpeed()
        peakSpeedMPS = 0
    }

    func resetPeakAcceleration() {
        peakAccelerationG = 0
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            motionStatusText = "Motion unavailable"
            return
        }

        guard !motionManager.isDeviceMotionActive else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self else { return }

            if let error {
                motionStatusText = "Motion error: \(error.localizedDescription)"
                return
            }

            guard let motion else {
                motionStatusText = "Motion unavailable"
                return
            }

            let launchG = hypot(motion.userAcceleration.x, motion.userAcceleration.y)
            accelerationG = launchG
            peakAccelerationG = max(peakAccelerationG, launchG)
            motionStatusText = "Accel live"
        }
    }
}

extension TelemetryManager: @preconcurrency CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            startTracking()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
            gpsStatusText = "GPS blocked"
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        gpsStatusText = "GPS error: \(error.localizedDescription)"
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations where location.horizontalAccuracy >= 0 && location.horizontalAccuracy <= 40 {
            var derivedSpeed = max(0, location.speed)

            if let lastLocation {
                let deltaDistance = location.distance(from: lastLocation)
                let deltaTime = location.timestamp.timeIntervalSince(lastLocation.timestamp)

                if deltaTime > 0 {
                    if location.speed < 0 {
                        derivedSpeed = max(0, deltaDistance / deltaTime)
                    }

                    if deltaDistance <= max(80, deltaTime * 75) {
                        cumulativeDistanceMeters += max(0, deltaDistance)
                    }
                }
            }

            lastLocation = location
            sessionDistanceMeters = max(0, cumulativeDistanceMeters - sessionDistanceOrigin)
            if location.verticalAccuracy >= 0 {
                currentAltitudeMeters = location.altitude
            }

            let snapshot = tracker.processSample(
                timestamp: location.timestamp,
                speedMPS: derivedSpeed,
                distanceMeters: sessionDistanceMeters,
                accelerationG: accelerationG
            )

            currentSpeedMPS = snapshot.currentSpeedMPS
            peakSpeedMPS = snapshot.peakSpeedMPS
            benchmarkResults = snapshot.results
            isRunActive = snapshot.isRunActive
            gpsStatusText = String(format: "GPS ±%.0f m", location.horizontalAccuracy)
        }
    }
}
