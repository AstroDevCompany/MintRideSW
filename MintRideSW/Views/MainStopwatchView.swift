import SwiftUI

struct MainStopwatchView: View {
    private enum HoldResetTarget: Hashable {
        case timer
        case benchmark(String)
        case distance
        case peakSpeed
        case peakAcceleration
        case peakCornering
    }

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var telemetryManager: TelemetryManager

    @StateObject private var stopwatch = StopwatchEngine()
    @State private var showsSettings = false
    @State private var activeHoldTarget: HoldResetTarget?
    @State private var holdProgress: CGFloat = 0
    @State private var holdWarningText = ""

    var body: some View {
        GeometryReader { geometry in
            let timeFontSize = min(geometry.size.height * 0.28, geometry.size.width * 0.12)
            let leftColumnWidth = min(geometry.size.width * 0.54, 760)

            ZStack(alignment: .topTrailing) {
                HStack(spacing: 24) {
                    VStack(alignment: .center, spacing: 24) {
                        timerDisplay(fontSize: timeFontSize)
                            .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Run Benchmarks")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                ForEach(telemetryManager.benchmarkResults) { result in
                                    BenchmarkTile(
                                        title: result.definition.title,
                                        value: StopwatchFormatter.formatBenchmark(result.elapsed),
                                        highlight: result.elapsed != nil,
                                        holdProgress: holdProgress(for: .benchmark(result.definition.id))
                                    )
                                    .onLongPressGesture(
                                        minimumDuration: 1,
                                        maximumDistance: 30,
                                        pressing: { isPressing in
                                            handleHoldChange(
                                                isPressing: isPressing,
                                                target: .benchmark(result.definition.id),
                                                warning: "Keep holding to reset \(result.definition.title)."
                                            )
                                        },
                                        perform: {
                                            telemetryManager.resetBenchmark(id: result.definition.id)
                                            clearHoldState()
                                        }
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            if stopwatch.isRunning {
                                stopwatch.pause()
                            } else {
                                stopwatch.start()
                            }
                        } label: {
                            Text(stopwatch.isRunning ? "Pause" : "Start")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(width: leftColumnWidth)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            statusPill(title: telemetryManager.gpsStatusText)
                            statusPill(
                                title: TelemetryFormatter.altitude(telemetryManager.currentAltitudeMeters, unit: settings.unit),
                                icon: "mountain.2.fill"
                            )
                        }

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            MetricTile(
                                title: "Speed",
                                value: "\(TelemetryFormatter.speed(telemetryManager.currentSpeedMPS, unit: settings.unit)) \(settings.unit.speedUnitTitle)",
                                subtitle: telemetryManager.isRunActive ? "Run active" : "Waiting for launch"
                            )

                            MetricTile(
                                title: "Distance",
                                value: "\(TelemetryFormatter.distance(telemetryManager.sessionDistanceMeters, unit: settings.unit)) \(settings.unit.distanceUnitTitle)",
                                subtitle: "Hold to reset",
                                holdProgress: holdProgress(for: .distance)
                            )
                            .onLongPressGesture(
                                minimumDuration: 1,
                                maximumDistance: 30,
                                pressing: { isPressing in
                                    handleHoldChange(
                                        isPressing: isPressing,
                                        target: .distance,
                                        warning: "Keep holding to reset session distance."
                                    )
                                },
                                perform: {
                                    telemetryManager.resetDistanceSession()
                                    clearHoldState()
                                }
                            )

                            MetricTile(
                                title: "Peak",
                                value: "\(TelemetryFormatter.speed(telemetryManager.peakSpeedMPS, unit: settings.unit)) \(settings.unit.speedUnitTitle)",
                                subtitle: "Hold to reset",
                                holdProgress: holdProgress(for: .peakSpeed)
                            )
                            .onLongPressGesture(
                                minimumDuration: 1,
                                maximumDistance: 30,
                                pressing: { isPressing in
                                    handleHoldChange(
                                        isPressing: isPressing,
                                        target: .peakSpeed,
                                        warning: "Keep holding to reset peak speed."
                                    )
                                },
                                perform: {
                                    telemetryManager.resetPeakSpeed()
                                    clearHoldState()
                                }
                            )

                            MetricTile(
                                title: "Accel",
                                value: TelemetryFormatter.gForce(telemetryManager.accelerationG),
                                subtitle: "Peak \(TelemetryFormatter.gForce(telemetryManager.peakAccelerationG))",
                                holdProgress: holdProgress(for: .peakAcceleration)
                            )
                            .onLongPressGesture(
                                minimumDuration: 1,
                                maximumDistance: 30,
                                pressing: { isPressing in
                                    handleHoldChange(
                                        isPressing: isPressing,
                                        target: .peakAcceleration,
                                        warning: "Keep holding to reset peak acceleration."
                                    )
                                },
                                perform: {
                                    telemetryManager.resetPeakAcceleration()
                                    clearHoldState()
                                }
                            )
                        }

                        MetricTile(
                            title: "Cornering",
                            value: TelemetryFormatter.gForce(telemetryManager.corneringG),
                            subtitle: "Peak \(TelemetryFormatter.gForce(telemetryManager.peakCorneringG))",
                            holdProgress: holdProgress(for: .peakCornering)
                        )
                        .onLongPressGesture(
                            minimumDuration: 1,
                            maximumDistance: 30,
                            pressing: { isPressing in
                                handleHoldChange(
                                    isPressing: isPressing,
                                    target: .peakCornering,
                                    warning: "Keep holding to reset peak cornering G."
                                )
                            },
                            perform: {
                                telemetryManager.resetPeakCornering()
                                clearHoldState()
                            }
                        )

                        if !telemetryManager.hasGPSPermission || telemetryManager.authorizationStatus == .denied || telemetryManager.authorizationStatus == .restricted {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(telemetryManager.permissionSummary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack(spacing: 12) {
                                if !telemetryManager.hasGPSPermission {
                                    Button("Enable GPS") {
                                        telemetryManager.requestPermissions()
                                        telemetryManager.startTracking()
                                    }
                                    .buttonStyle(.bordered)
                                }

                                if telemetryManager.authorizationStatus == .denied || telemetryManager.authorizationStatus == .restricted {
                                    Text("Open Settings app to re-enable permissions.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            }
                        }

                    }
                    .frame(width: min(geometry.size.width * 0.34, 340), alignment: .topLeading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 28)
                .padding(.top, 18)
                .padding(.bottom, 28)
                .background(backgroundLayer)

                if !holdWarningText.isEmpty {
                    VStack {
                        holdWarningBanner
                        Spacer()
                    }
                    .padding(.top, max(geometry.safeAreaInsets.top, 8))
                    .padding(.horizontal, 20)
                }

                VStack(alignment: .trailing, spacing: 10) {
                    Button {
                        showsSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .accessibilityLabel("Open Settings")
                }
                .padding(.top, max(geometry.safeAreaInsets.top, 8))
                .padding(.trailing, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showsSettings) {
            SettingsView()
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            Color(uiColor: .systemBackground)

            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.18),
                    Color.clear,
                    Color.primary.opacity(0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.accentColor.opacity(0.09))
                .frame(width: 380, height: 380)
                .blur(radius: 40)
                .offset(x: 280, y: -170)
        }
        .ignoresSafeArea()
    }

    private func statusPill(title: String, icon: String? = nil) -> some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
            }

            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .fill(Color.primary.opacity(0.06))
        }
    }

    private func timerDisplay(fontSize: CGFloat) -> some View {
        let parts = StopwatchFormatter.components(stopwatch.elapsed)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                timerUnit("H")
                timerUnitSeparator(":")
                timerUnit("m")
                timerUnitSeparator(":")
                timerUnit("s")
                timerUnitSeparator(".")
                timerUnit("ms")
            }

            HStack(spacing: 0) {
                    timerSegment(parts.hours, fontSize: fontSize)
                    timerSeparator(":", fontSize: fontSize)
                    timerSegment(parts.minutes, fontSize: fontSize)
                    timerSeparator(":", fontSize: fontSize)
                    timerSegment(parts.seconds, fontSize: fontSize)
                    timerSeparator(".", fontSize: fontSize)
                    timerSegment(parts.centiseconds, fontSize: fontSize)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.primary.opacity(0.05))
                }
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color.accentColor.opacity(0.18))
                            .frame(width: proxy.size.width * holdProgress(for: .timer))
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .accessibilityLabel("Stopwatch \(StopwatchFormatter.format(stopwatch.elapsed))")
                .onLongPressGesture(
                    minimumDuration: 1,
                    maximumDistance: 30,
                    pressing: { isPressing in
                        handleHoldChange(
                            isPressing: isPressing,
                            target: .timer,
                            warning: "Keep holding to reset the main timer."
                        )
                    },
                    perform: {
                        stopwatch.reset()
                        clearHoldState()
                    }
                )
        }
            .frame(maxWidth: .infinity)
    }

    private func timerSegment(_ value: String, fontSize: CGFloat) -> some View {
        Text(value)
            .font(settings.timeFont.font(size: fontSize))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.35)
            .frame(maxWidth: .infinity)
    }

    private func timerSeparator(_ value: String, fontSize: CGFloat) -> some View {
        Text(value)
            .font(settings.timeFont.font(size: fontSize * 0.62))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .lineLimit(1)
            .minimumScaleFactor(0.35)
            .baselineOffset(fontSize * 0.02)
            .padding(.horizontal, 2)
    }

    private func timerUnit(_ value: String) -> some View {
        Text(value)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
    }

    private func timerUnitSeparator(_ value: String) -> some View {
        Text(value)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.clear)
            .padding(.horizontal, 2)
    }

    private var holdWarningBanner: some View {
        Text(holdWarningText)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func handleHoldChange(isPressing: Bool, target: HoldResetTarget, warning: String) {
        if isPressing {
            activeHoldTarget = target
            holdWarningText = warning
            holdProgress = 0
            withAnimation(.linear(duration: 1)) {
                holdProgress = 1
            }
        } else if activeHoldTarget == target {
            clearHoldState()
        }
    }

    private func clearHoldState() {
        activeHoldTarget = nil
        holdWarningText = ""
        withAnimation(.easeOut(duration: 0.2)) {
            holdProgress = 0
        }
    }

    private func holdProgress(for target: HoldResetTarget) -> CGFloat {
        activeHoldTarget == target ? holdProgress : 0
    }
}
