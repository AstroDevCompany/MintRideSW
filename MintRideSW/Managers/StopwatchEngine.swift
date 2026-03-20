import Combine
import Foundation

@MainActor
final class StopwatchEngine: ObservableObject {
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var isRunning = false

    private var startDate: Date?
    private var storedElapsed: TimeInterval = 0
    private var timerCancellable: AnyCancellable?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        startDate = Date()
        startTimer()
    }

    func pause() {
        guard isRunning else { return }
        storedElapsed = elapsed
        isRunning = false
        startDate = nil
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func reset() {
        isRunning = false
        startDate = nil
        storedElapsed = 0
        elapsed = 0
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    private func startTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.02, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self else { return }
                elapsed = computedElapsed(at: now)
            }
    }

    private func computedElapsed(at date: Date) -> TimeInterval {
        guard let startDate else { return storedElapsed }
        return storedElapsed + date.timeIntervalSince(startDate)
    }
}
