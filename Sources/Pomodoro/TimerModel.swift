import Foundation

/// Countdown state. Running time is tracked against a wall-clock end date,
/// so the timer stays correct across sleep and missed ticks.
final class TimerModel: ObservableObject {
    static let presets = [15, 30, 45, 60, 75, 90]

    enum State { case idle, running, paused, done }

    @Published private(set) var state: State = .idle
    @Published private(set) var minutes: Int
    @Published private(set) var remaining: Int

    var onFinish: (() -> Void)?

    private var endDate: Date?
    private var ticker: Timer?
    private static let defaultsKey = "selectedMinutes"

    var total: Int { minutes * 60 }
    var fractionLeft: Double { total == 0 ? 0 : Double(remaining) / Double(total) }
    var canPickPreset: Bool { state == .idle || state == .done }

    init() {
        let saved = UserDefaults.standard.integer(forKey: Self.defaultsKey)
        let m = Self.presets.contains(saved) ? saved : 30
        minutes = m
        remaining = m * 60
    }

    func select(_ m: Int) {
        guard canPickPreset else { return }
        minutes = m
        UserDefaults.standard.set(m, forKey: Self.defaultsKey)
        remaining = total
        state = .idle
    }

    func toggle() {
        state == .running ? pause() : start()
    }

    func start() {
        if state == .done { remaining = total }
        endDate = Date().addingTimeInterval(TimeInterval(remaining))
        state = .running
        startTicker()
    }

    func pause() {
        guard state == .running else { return }
        tick()
        stopTicker()
        endDate = nil
        state = .paused
    }

    func end() {
        stopTicker()
        endDate = nil
        remaining = total
        state = .idle
    }

    private func tick() {
        guard let endDate else { return }
        let left = max(0, Int(endDate.timeIntervalSinceNow.rounded(.up)))
        if left != remaining { remaining = left }
        if left == 0 { finish() }
    }

    private func finish() {
        stopTicker()
        endDate = nil
        state = .done
        onFinish?()
    }

    private func startTicker() {
        stopTicker()
        let t = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in self?.tick() }
        // .common keeps it ticking while the popover or a menu is being tracked.
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }
}

func formatClock(_ seconds: Int) -> String {
    String(format: "%02d:%02d", seconds / 60, seconds % 60)
}
