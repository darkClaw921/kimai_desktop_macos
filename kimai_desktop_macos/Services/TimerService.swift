import Foundation
import Observation

@Observable
final class TimerService {
    private(set) var elapsed: TimeInterval = 0
    private(set) var isRunning = false
    private var startDate: Date?
    private var timer: DispatchSourceTimer?

    var formattedElapsed: String {
        DateFormatting.formatElapsed(elapsed)
    }

    func start(from date: Date = .now) {
        stop()
        startDate = date
        isRunning = true
        elapsed = Date.now.timeIntervalSince(date)

        let timerSource = DispatchSource.makeTimerSource(queue: .main)
        timerSource.schedule(deadline: .now() + 1, repeating: 1)
        timerSource.setEventHandler { [weak self] in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
        timerSource.resume()
        timer = timerSource
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
        elapsed = 0
        startDate = nil
    }

    private func tick() {
        guard let startDate else { return }
        elapsed = Date.now.timeIntervalSince(startDate)
    }
}
