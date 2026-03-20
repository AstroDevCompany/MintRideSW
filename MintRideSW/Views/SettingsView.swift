import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var telemetryManager: TelemetryManager

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                settingsCard(title: "Theme", subtitle: "Minimal appearance mode") {
                    HStack(spacing: 12) {
                        ForEach(AppTheme.allCases) { theme in
                            SelectionChip(
                                title: theme.title,
                                subtitle: theme == .dark ? "Low glare" : "High contrast",
                                isSelected: settings.theme == theme
                            ) {
                                settings.theme = theme
                            }
                        }
                    }
                }

                settingsCard(title: "Time Font", subtitle: "Six built-in display faces") {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(TimeFontOption.allCases) { option in
                            Button {
                                settings.timeFont = option
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(option.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)

                                    Text("01:28.64")
                                        .font(option.font(size: 26))
                                        .monospacedDigit()
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)

                                    Text(option.sampleLabel.uppercased())
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(settings.timeFont == option ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.05))
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(settings.timeFont == option ? Color.accentColor : Color.clear, lineWidth: 1.5)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                settingsCard(title: "Units", subtitle: "Switch speed and benchmark targets") {
                    HStack(spacing: 12) {
                        ForEach(DisplayUnit.allCases) { unit in
                            SelectionChip(
                                title: unit.title,
                                subtitle: unit == .metric ? "0-100 / 400 m" : "0-60 / quarter",
                                isSelected: settings.unit == unit
                            ) {
                                settings.unit = unit
                            }
                        }
                    }
                }

                settingsCard(title: "Sensors", subtitle: "GPS and accelerometer status") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(telemetryManager.permissionSummary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            MetricTile(title: "GPS", value: telemetryManager.gpsStatusText, subtitle: nil)
                            MetricTile(title: "Motion", value: telemetryManager.motionStatusText, subtitle: nil)
                        }

                        HStack(spacing: 12) {
                            Button("Enable GPS") {
                                telemetryManager.requestPermissions()
                                telemetryManager.startTracking()
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Reset Run Data") {
                                telemetryManager.resetBenchmarks()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.12), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    @ViewBuilder
    private func settingsCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.primary.opacity(0.045))
        }
    }
}

private struct SelectionChip: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.05))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}
