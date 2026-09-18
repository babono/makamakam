import UIKit
import Observation

/// Touch, and nothing else. No sound, ever (PRD §6) — a cemetery is not a place
/// to be chimed at.
enum Feedback {
    static func enteringNear() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func arrived() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

/// A pulse that quickens and strengthens as the grave gets closer, so the last
/// stretch can be walked with the phone at your side and your eyes on the rows
/// rather than on a screen.
///
/// It is not a proximity *measurement* — the accuracy line on screen is still the
/// honest number, and it does not improve as you approach (PRD §7). The pulse
/// paces the walk; it does not claim to find the plot.
@Observable
final class ApproachPulse {
    /// Some people will not want a phone buzzing at a graveside at all, so this
    /// is a setting rather than a fact of the product.
    var enabled: Bool {
        didSet { UserDefaults.standard.set(enabled, forKey: Self.key) }
    }

    private static let key = "haptics.approachPulse"
    private var timer: Timer?
    private var rehearsal: Timer?
    /// Where the rehearsal has got to, for the field sheet's readout.
    var rehearsedDistance: Double?
    private let generator = UIImpactFeedbackGenerator(style: .soft)
    private var lastDistance: Double?

    init() {
        if UserDefaults.standard.object(forKey: Self.key) == nil {
            enabled = true
        } else {
            enabled = UserDefaults.standard.bool(forKey: Self.key)
        }
    }

    /// Far off it is a slow, faint tap every three seconds; at the handoff it is
    /// a firm one three times a second. In between it moves smoothly, so the
    /// change itself is the signal.
    func update(distance: Double?) {
        lastDistance = distance
        guard enabled, let distance, distance.isFinite else { return stop() }
        guard distance <= 80 else { return stop() }

        let interval = Self.interval(for: distance)
        if timer == nil || abs((timer?.timeInterval ?? 0) - interval) > 0.12 {
            start(interval: interval)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func start(interval: TimeInterval) {
        timer?.invalidate()
        generator.prepare()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self, let distance = self.lastDistance else { return }
            self.generator.impactOccurred(intensity: Self.intensity(for: distance))
            self.generator.prepare()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // MARK: Rehearsal (field sheet only)

    /// Walks the pulse from 80 m in to the handoff without anyone walking
    /// anywhere, so the escalation can be felt at a desk. Ends with the arrival
    /// tap, exactly as the real approach does.
    func rehearse(seconds: TimeInterval = 18) {
        rehearsal?.invalidate()
        let start: Double = 80
        let end = 6.0
        let began = Date()

        let ticker = Timer(timeInterval: 0.25, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let elapsed = Date().timeIntervalSince(began)
            guard elapsed < seconds else {
                timer.invalidate()
                self.rehearsal = nil
                self.stop()
                Feedback.arrived()
                self.rehearsedDistance = nil
                return
            }
            let progress = elapsed / seconds
            let distance = start + (end - start) * progress
            self.rehearsedDistance = distance
            self.update(distance: distance)
        }
        RunLoop.main.add(ticker, forMode: .common)
        rehearsal = ticker
        rehearsedDistance = start
        update(distance: start)
    }

    func stopRehearsing() {
        rehearsal?.invalidate()
        rehearsal = nil
        rehearsedDistance = nil
        stop()
    }

    var isRehearsing: Bool { rehearsal != nil }

    /// 3 s at 80 m, down to 0.32 s at the handoff.
    static func interval(for distance: Double) -> TimeInterval {
        let clamped = min(max(distance, 6), 80)
        let t = (clamped - 6) / (80 - 6)
        return 0.32 + (3.0 - 0.32) * t
    }

    /// Faint far away, full strength at the handoff.
    static func intensity(for distance: Double) -> CGFloat {
        let clamped = min(max(distance, 6), 80)
        let t = (clamped - 6) / (80 - 6)
        return 1.0 - 0.7 * CGFloat(t)
    }
}
