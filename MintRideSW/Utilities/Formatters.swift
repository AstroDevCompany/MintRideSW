import Foundation

enum StopwatchFormatter {
    static func format(_ interval: TimeInterval) -> String {
        let totalCentiseconds = Int((interval * 100).rounded(.down))
        let hours = totalCentiseconds / 360_000
        let minutes = (totalCentiseconds / 6_000) % 60
        let seconds = (totalCentiseconds / 100) % 60
        let centiseconds = totalCentiseconds % 100
        return String(format: "%02d:%02d:%02d.%02d", hours, minutes, seconds, centiseconds)
    }

    static func formatBenchmark(_ interval: TimeInterval?) -> String {
        guard let interval else { return "--.--s" }
        return String(format: "%.2fs", interval)
    }
}

enum TelemetryFormatter {
    static func speed(_ speedMPS: Double, unit: DisplayUnit) -> String {
        switch unit {
        case .metric:
            String(format: "%.0f", speedMPS * 3.6)
        case .imperial:
            String(format: "%.0f", speedMPS * 2.236_94)
        }
    }

    static func distance(_ meters: Double, unit: DisplayUnit) -> String {
        switch unit {
        case .metric:
            String(format: "%.2f", meters / 1_000)
        case .imperial:
            String(format: "%.2f", meters / 1_609.344)
        }
    }

    static func gForce(_ accelerationG: Double) -> String {
        String(format: "%.2f g", accelerationG)
    }

    static func altitude(_ meters: Double, unit: DisplayUnit) -> String {
        switch unit {
        case .metric:
            String(format: "%.0f m", meters)
        case .imperial:
            String(format: "%.0f ft", meters * 3.280_84)
        }
    }
}
