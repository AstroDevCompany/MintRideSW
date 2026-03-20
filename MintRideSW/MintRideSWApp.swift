import SwiftUI

@main
struct MintRideSWApp: App {
    @StateObject private var settings: AppSettings
    @StateObject private var telemetryManager: TelemetryManager
    @StateObject private var historyStore = HistoryStore()
    private let isRunningTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    init() {
        let loadedSettings = AppSettings()
        _settings = StateObject(wrappedValue: loadedSettings)
        _telemetryManager = StateObject(wrappedValue: TelemetryManager(unit: loadedSettings.unit))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainStopwatchView()
            }
            .environmentObject(settings)
            .environmentObject(telemetryManager)
            .environmentObject(historyStore)
            .preferredColorScheme(settings.theme.colorScheme)
            .task {
                guard !isRunningTests else { return }
                telemetryManager.startTracking()
            }
            .onChange(of: settings.unit) { _, newValue in
                telemetryManager.updateUnit(newValue)
            }
        }
    }
}
