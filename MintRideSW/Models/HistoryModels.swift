import Foundation

struct SessionBenchmarkRecord: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let elapsed: TimeInterval

    init(title: String, elapsed: TimeInterval) {
        id = title
        self.title = title
        self.elapsed = elapsed
    }
}

struct SessionHistoryEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let elapsedTimer: TimeInterval
    let unitRawValue: String
    let topSpeedMPS: Double
    let peakAccelerationG: Double
    let peakCorneringG: Double
    let distanceMeters: Double
    let benchmarks: [SessionBenchmarkRecord]

    var unit: DisplayUnit {
        DisplayUnit(rawValue: unitRawValue) ?? .metric
    }
}

struct OverallHistoryRecords: Codable, Equatable {
    var topSpeedMPS: Double = 0
    var peakAccelerationG: Double = 0
    var peakCorneringG: Double = 0
    var longestDistanceMeters: Double = 0
    var benchmarkBestTimes: [String: TimeInterval] = [:]
}
