import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark:
            "Dark"
        case .light:
            "Light"
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .dark:
            .dark
        case .light:
            .light
        }
    }
}

enum DisplayUnit: String, CaseIterable, Identifiable {
    case metric
    case imperial

    var id: String { rawValue }

    var title: String {
        switch self {
        case .metric:
            "Metric"
        case .imperial:
            "Imperial"
        }
    }

    var speedUnitTitle: String {
        switch self {
        case .metric:
            "km/h"
        case .imperial:
            "mph"
        }
    }

    var distanceUnitTitle: String {
        switch self {
        case .metric:
            "km"
        case .imperial:
            "mi"
        }
    }

    var primarySpeedBenchmark: BenchmarkDefinition {
        switch self {
        case .metric:
            BenchmarkDefinition(id: "speed-100", title: "0-100 km/h", kind: .speed(27.777_778))
        case .imperial:
            BenchmarkDefinition(id: "speed-60", title: "0-60 mph", kind: .speed(26.822_4))
        }
    }

    var distanceBenchmarks: [BenchmarkDefinition] {
        switch self {
        case .metric:
            [
                BenchmarkDefinition(id: "distance-100m", title: "100 m", kind: .distance(100)),
                BenchmarkDefinition(id: "distance-400m", title: "400 m", kind: .distance(400))
            ]
        case .imperial:
            [
                BenchmarkDefinition(id: "distance-eighth", title: "1/8 mi", kind: .distance(201.168)),
                BenchmarkDefinition(id: "distance-quarter", title: "1/4 mi", kind: .distance(402.336))
            ]
        }
    }

    var allBenchmarks: [BenchmarkDefinition] {
        [primarySpeedBenchmark] + distanceBenchmarks
    }
}

enum TimeFontOption: String, CaseIterable, Identifiable {
    case systemMono
    case rounded
    case serif
    case avenir
    case menlo
    case typewriter

    var id: String { rawValue }

    var title: String {
        switch self {
        case .systemMono:
            "Mono"
        case .rounded:
            "Rounded"
        case .serif:
            "Serif"
        case .avenir:
            "Avenir"
        case .menlo:
            "Menlo"
        case .typewriter:
            "Typewriter"
        }
    }

    var sampleLabel: String {
        switch self {
        case .systemMono:
            "Precise"
        case .rounded:
            "Soft"
        case .serif:
            "Classic"
        case .avenir:
            "Lean"
        case .menlo:
            "Race"
        case .typewriter:
            "Retro"
        }
    }

    func font(size: CGFloat) -> Font {
        switch self {
        case .systemMono:
            .system(size: size, weight: .semibold, design: .monospaced)
        case .rounded:
            .system(size: size, weight: .semibold, design: .rounded)
        case .serif:
            .system(size: size, weight: .semibold, design: .serif)
        case .avenir:
            .custom("AvenirNextCondensed-DemiBold", size: size)
        case .menlo:
            .custom("Menlo-Bold", size: size)
        case .typewriter:
            .custom("AmericanTypewriter-Bold", size: size)
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    private enum StorageKey {
        static let theme = "app.theme"
        static let unit = "app.unit"
        static let timeFont = "app.timeFont"
    }

    @Published var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: StorageKey.theme) }
    }

    @Published var unit: DisplayUnit {
        didSet { defaults.set(unit.rawValue, forKey: StorageKey.unit) }
    }

    @Published var timeFont: TimeFontOption {
        didSet { defaults.set(timeFont.rawValue, forKey: StorageKey.timeFont) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        theme = AppTheme(rawValue: defaults.string(forKey: StorageKey.theme) ?? "") ?? .dark
        unit = DisplayUnit(rawValue: defaults.string(forKey: StorageKey.unit) ?? "") ?? .metric
        timeFont = TimeFontOption(rawValue: defaults.string(forKey: StorageKey.timeFont) ?? "") ?? .systemMono
    }
}
