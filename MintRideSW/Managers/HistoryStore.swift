import Foundation

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var overallRecords: OverallHistoryRecords
    @Published private(set) var sessions: [SessionHistoryEntry]

    private enum StorageKey {
        static let overallRecords = "history.overallRecords"
        static let sessions = "history.sessions"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        overallRecords = Self.loadValue(
            forKey: StorageKey.overallRecords,
            defaults: defaults,
            decoder: decoder
        ) ?? OverallHistoryRecords()
        sessions = Self.loadValue(
            forKey: StorageKey.sessions,
            defaults: defaults,
            decoder: decoder
        ) ?? []
    }

    func storeSession(_ session: SessionHistoryEntry) {
        sessions.insert(session, at: 0)
        overallRecords.topSpeedMPS = max(overallRecords.topSpeedMPS, session.topSpeedMPS)
        overallRecords.peakAccelerationG = max(overallRecords.peakAccelerationG, session.peakAccelerationG)
        overallRecords.peakCorneringG = max(overallRecords.peakCorneringG, session.peakCorneringG)
        overallRecords.longestDistanceMeters = max(overallRecords.longestDistanceMeters, session.distanceMeters)

        for benchmark in session.benchmarks {
            if let existing = overallRecords.benchmarkBestTimes[benchmark.title] {
                overallRecords.benchmarkBestTimes[benchmark.title] = min(existing, benchmark.elapsed)
            } else {
                overallRecords.benchmarkBestTimes[benchmark.title] = benchmark.elapsed
            }
        }

        persist()
    }

    func deleteAll() {
        overallRecords = OverallHistoryRecords()
        sessions = []
        defaults.removeObject(forKey: StorageKey.overallRecords)
        defaults.removeObject(forKey: StorageKey.sessions)
    }

    private func persist() {
        if let recordsData = try? encoder.encode(overallRecords) {
            defaults.set(recordsData, forKey: StorageKey.overallRecords)
        }

        if let sessionsData = try? encoder.encode(sessions) {
            defaults.set(sessionsData, forKey: StorageKey.sessions)
        }
    }

    private static func loadValue<T: Decodable>(
        forKey key: String,
        defaults: UserDefaults,
        decoder: JSONDecoder
    ) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
}
