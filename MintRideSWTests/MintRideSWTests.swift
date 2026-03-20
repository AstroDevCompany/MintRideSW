import XCTest
@testable import MintRideSW

final class MintRideSWTests: XCTestCase {
    func testStopwatchFormatterUsesCentiseconds() {
        XCTAssertEqual(StopwatchFormatter.format(3_661.23), "01:01:01.23")
        XCTAssertEqual(StopwatchFormatter.formatBenchmark(4.567), "4.57s")
        XCTAssertEqual(StopwatchFormatter.formatBenchmark(nil), "--.--s")
    }

    func testMetricRunTrackerCapturesSpeedAndDistanceBenchmarks() throws {
        let tracker = RunTrackerCore(unit: .metric)
        let start = Date()

        _ = tracker.processSample(timestamp: start, speedMPS: 0, distanceMeters: 0, accelerationG: 0)
        _ = tracker.processSample(timestamp: start.addingTimeInterval(1), speedMPS: 8, distanceMeters: 5, accelerationG: 0.11)
        _ = tracker.processSample(timestamp: start.addingTimeInterval(2), speedMPS: 16, distanceMeters: 35, accelerationG: 0.08)
        _ = tracker.processSample(timestamp: start.addingTimeInterval(4), speedMPS: 28, distanceMeters: 110, accelerationG: 0.05)
        let snapshot = tracker.processSample(timestamp: start.addingTimeInterval(8), speedMPS: 31, distanceMeters: 420, accelerationG: 0.02)

        let zeroToHundred = try XCTUnwrap(snapshot.results.first(where: { $0.definition.id == "speed-100" })?.elapsed)
        let hundredMeters = try XCTUnwrap(snapshot.results.first(where: { $0.definition.id == "distance-100m" })?.elapsed)
        let fourHundredMeters = try XCTUnwrap(snapshot.results.first(where: { $0.definition.id == "distance-400m" })?.elapsed)

        XCTAssertEqual(zeroToHundred, 3, accuracy: 0.001)
        XCTAssertEqual(hundredMeters, 3, accuracy: 0.001)
        XCTAssertEqual(fourHundredMeters, 7, accuracy: 0.001)
    }
}
