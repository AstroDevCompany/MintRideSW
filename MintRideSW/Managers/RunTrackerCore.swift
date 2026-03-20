import Foundation

final class RunTrackerCore {
    private(set) var definitions: [BenchmarkDefinition]
    private(set) var results: [BenchmarkResult]
    private(set) var peakSpeedMPS: Double = 0

    private var runStartDate: Date?
    private var runStartDistance: Double = 0
    private var lastSpeedMPS: Double = 0
    private var lastMovingDate: Date?

    init(unit: DisplayUnit) {
        definitions = unit.allBenchmarks
        results = unit.allBenchmarks.map { BenchmarkResult(definition: $0, elapsed: nil) }
    }

    func configure(for unit: DisplayUnit) {
        definitions = unit.allBenchmarks
        resetBenchmarks()
    }

    func resetBenchmarks() {
        results = definitions.map { BenchmarkResult(definition: $0, elapsed: nil) }
        peakSpeedMPS = 0
        runStartDate = nil
        runStartDistance = 0
        lastSpeedMPS = 0
        lastMovingDate = nil
    }

    func resetBenchmark(id: String) {
        guard let index = results.firstIndex(where: { $0.definition.id == id }) else { return }
        results[index].elapsed = nil
    }

    func resetPeakSpeed() {
        peakSpeedMPS = 0
    }

    func processSample(timestamp: Date, speedMPS: Double, distanceMeters: Double, accelerationG: Double) -> RunSnapshot {
        peakSpeedMPS = max(peakSpeedMPS, speedMPS)

        if speedMPS > 0.8 {
            lastMovingDate = timestamp
        }

        let launchDetected = accelerationG >= 0.06 || (speedMPS - lastSpeedMPS) >= 0.45
        if runStartDate == nil, speedMPS >= 1.4, launchDetected {
            results = definitions.map { BenchmarkResult(definition: $0, elapsed: nil) }
            runStartDate = timestamp
            runStartDistance = distanceMeters
        }

        if let startDate = runStartDate {
            let elapsed = timestamp.timeIntervalSince(startDate)
            let coveredDistance = max(0, distanceMeters - runStartDistance)

            for index in results.indices where results[index].elapsed == nil {
                switch results[index].definition.kind {
                case .speed(let targetSpeed) where speedMPS >= targetSpeed:
                    results[index].elapsed = elapsed
                case .distance(let targetDistance) where coveredDistance >= targetDistance:
                    results[index].elapsed = elapsed
                default:
                    break
                }
            }

            if let lastMovingDate, timestamp.timeIntervalSince(lastMovingDate) > 2.5, elapsed > 2 {
                runStartDate = nil
            }
        }

        lastSpeedMPS = speedMPS

        return RunSnapshot(
            results: results,
            currentSpeedMPS: speedMPS,
            peakSpeedMPS: peakSpeedMPS,
            distanceMeters: distanceMeters,
            accelerationG: accelerationG,
            isRunActive: runStartDate != nil
        )
    }
}
