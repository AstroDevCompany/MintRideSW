import CoreLocation
import CoreMotion
import Foundation

@MainActor
final class TelemetryManager: NSObject, ObservableObject {
    private enum MotionTuning {
        static let updateInterval = 1.0 / 50.0
        static let smoothingFactor = 0.18
        static let noiseFloorG = 0.015
    }

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentSpeedMPS: Double = 0
    @Published private(set) var peakSpeedMPS: Double = 0
    @Published private(set) var sessionDistanceMeters: Double = 0
    @Published private(set) var accelerationG: Double = 0
    @Published private(set) var peakAccelerationG: Double = 0
    @Published private(set) var corneringG: Double = 0
    @Published private(set) var peakCorneringG: Double = 0
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
    private var smoothedAccelerationG: Double = 0
    private var smoothedCorneringG: Double = 0
    private var travelHeadingRadians: Double?

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
        peakAccelerationG = 0
        peakCorneringG = 0
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

    func resetPeakCornering() {
        peakCorneringG = 0
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            motionStatusText = "Motion unavailable"
            return
        }

        guard !motionManager.isDeviceMotionActive else { return }

        motionManager.deviceMotionUpdateInterval = MotionTuning.updateInterval
        motionManager.startDeviceMotionUpdates(
            using: preferredMotionReferenceFrame,
            to: .main
        ) { [weak self] motion, error in
            guard let self else { return }

            if let error {
                motionStatusText = "Motion error: \(error.localizedDescription)"
                return
            }

            guard let motion else {
                motionStatusText = "Motion unavailable"
                return
            }

            let acceleration = filteredVehicleAcceleration(from: motion)
            accelerationG = acceleration.longitudinal
            corneringG = acceleration.lateral
            peakAccelerationG = max(peakAccelerationG, acceleration.longitudinal)
            peakCorneringG = max(peakCorneringG, acceleration.lateral)
            motionStatusText = "Accel filtered"
        }
    }

    private var preferredMotionReferenceFrame: CMAttitudeReferenceFrame {
        let available = CMMotionManager.availableAttitudeReferenceFrames()

        if available.contains(.xTrueNorthZVertical) {
            return .xTrueNorthZVertical
        }

        if available.contains(.xMagneticNorthZVertical) {
            return .xMagneticNorthZVertical
        }

        if available.contains(.xArbitraryCorrectedZVertical) {
            return .xArbitraryCorrectedZVertical
        }

        return .xArbitraryZVertical
    }

    private func filteredVehicleAcceleration(from motion: CMDeviceMotion) -> (longitudinal: Double, lateral: Double) {
        let rotation = motion.attitude.rotationMatrix
        let userAcceleration = motion.userAcceleration

        // rotationMatrix maps reference -> device, so transpose maps device -> reference.
        let worldX = rotation.m11 * userAcceleration.x + rotation.m21 * userAcceleration.y + rotation.m31 * userAcceleration.z
        let worldY = rotation.m12 * userAcceleration.x + rotation.m22 * userAcceleration.y + rotation.m32 * userAcceleration.z

        let projected: (Double, Double)
        if let heading = travelHeadingRadians {
            let headingVectorX = cos(heading)
            let headingVectorY = sin(heading)
            let lateralVectorX = -headingVectorY
            let lateralVectorY = headingVectorX

            projected = (
                abs(worldX * headingVectorX + worldY * headingVectorY),
                abs(worldX * lateralVectorX + worldY * lateralVectorY)
            )
        } else {
            projected = (hypot(worldX, worldY), 0)
        }

        let longitudinal = filteredG(
            rawValue: projected.0,
            previousValue: &smoothedAccelerationG
        )
        let lateral = filteredG(
            rawValue: projected.1,
            previousValue: &smoothedCorneringG
        )

        return (longitudinal, lateral)
    }

    private func filteredG(rawValue: Double, previousValue: inout Double) -> Double {
        let sanitized = rawValue < MotionTuning.noiseFloorG ? 0 : rawValue
        previousValue += (sanitized - previousValue) * MotionTuning.smoothingFactor
        return previousValue
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
            if location.course >= 0, derivedSpeed >= 2 {
                travelHeadingRadians = location.course * .pi / 180
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
