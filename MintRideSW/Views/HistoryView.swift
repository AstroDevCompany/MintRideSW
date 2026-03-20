import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var historyStore: HistoryStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                recordsSection
                sessionsSection
            }
            .padding(24)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Delete All", role: .destructive) {
                    historyStore.deleteAll()
                }
            }
        }
    }

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Records")
                .font(.headline)

            if historyStore.sessions.isEmpty {
                placeholderCard("No saved records yet.")
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        recordTile(
                            title: "Top Speed",
                            value: "\(TelemetryFormatter.speed(historyStore.overallRecords.topSpeedMPS, unit: .metric)) km/h"
                        )
                        recordTile(
                            title: "Peak Accel",
                            value: TelemetryFormatter.gForce(historyStore.overallRecords.peakAccelerationG)
                        )
                    }

                    HStack(spacing: 12) {
                        recordTile(
                            title: "Peak Cornering",
                            value: TelemetryFormatter.gForce(historyStore.overallRecords.peakCorneringG)
                        )
                        recordTile(
                            title: "Longest Distance",
                            value: "\(TelemetryFormatter.distance(historyStore.overallRecords.longestDistanceMeters, unit: .metric)) km"
                        )
                    }

                    if !historyStore.overallRecords.benchmarkBestTimes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(sortedBenchmarkTitles, id: \.self) { title in
                                HStack {
                                    Text(title)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(StopwatchFormatter.formatBenchmark(historyStore.overallRecords.benchmarkBestTimes[title]))
                                        .font(.subheadline.weight(.semibold))
                                }
                            }
                        }
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.primary.opacity(0.05))
                        }
                    }
                }
            }
        }
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sessions")
                .font(.headline)

            if historyStore.sessions.isEmpty {
                placeholderCard("Start the stopwatch and reset it to save a session.")
            } else {
                ForEach(historyStore.sessions) { session in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(StopwatchFormatter.format(session.elapsedTimer))
                                .font(.subheadline.weight(.semibold))
                        }

                        HStack(spacing: 12) {
                            sessionMetric(
                                "Top Speed",
                                "\(TelemetryFormatter.speed(session.topSpeedMPS, unit: session.unit)) \(session.unit.speedUnitTitle)"
                            )
                            sessionMetric("Accel", TelemetryFormatter.gForce(session.peakAccelerationG))
                        }

                        HStack(spacing: 12) {
                            sessionMetric("Cornering", TelemetryFormatter.gForce(session.peakCorneringG))
                            sessionMetric(
                                "Distance",
                                "\(TelemetryFormatter.distance(session.distanceMeters, unit: session.unit)) \(session.unit.distanceUnitTitle)"
                            )
                        }

                        if !session.benchmarks.isEmpty {
                            HStack(spacing: 12) {
                                ForEach(session.benchmarks) { benchmark in
                                    sessionMetric(
                                        benchmark.title,
                                        StopwatchFormatter.formatBenchmark(benchmark.elapsed)
                                    )
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.primary.opacity(0.05))
                    }
                }
            }
        }
    }

    private var sortedBenchmarkTitles: [String] {
        historyStore.overallRecords.benchmarkBestTimes.keys.sorted {
            let lhsSpeed = $0.hasPrefix("0-")
            let rhsSpeed = $1.hasPrefix("0-")
            if lhsSpeed != rhsSpeed { return lhsSpeed && !rhsSpeed }
            return $0.localizedStandardCompare($1) == .orderedAscending
        }
    }

    private func recordTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.primary.opacity(0.05))
        }
    }

    private func sessionMetric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func placeholderCard(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            }
    }
}
