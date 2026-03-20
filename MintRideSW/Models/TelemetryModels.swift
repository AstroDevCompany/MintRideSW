import Foundation

enum BenchmarkKind: Equatable {
    case speed(Double)
    case distance(Double)
}

struct BenchmarkDefinition: Identifiable, Equatable {
    let id: String
    let title: String
    let kind: BenchmarkKind
}

struct BenchmarkResult: Identifiable, Equatable {
    let definition: BenchmarkDefinition
    var elapsed: TimeInterval?

    var id: String { definition.id }
}

struct RunSnapshot: Equatable {
    let results: [BenchmarkResult]
    let currentSpeedMPS: Double
    let peakSpeedMPS: Double
    let distanceMeters: Double
    let accelerationG: Double
    let isRunActive: Bool
}
