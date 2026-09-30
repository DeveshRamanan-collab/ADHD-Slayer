import SwiftUI
import CoreHaptics
import UIKit

/// Designed haptics: touch is how a lot of people with ADHD stay anchored, so nearly every moment
/// in the app has a feel. Each one is a Core Haptics pattern, scaled by the strength slider in
/// Customise, and everything can be switched off in Settings (some people find vibration intrusive).
@MainActor
final class Haptics {
    static let shared = Haptics()

    enum Moment {
        /// The starting page: a slow swell as the day "arrives", with soft landings as words appear.
        case arrival
        /// First launch: the logo drawing itself, a long soft swell then a bloom.
        case splash
        /// One word landing.
        case land
        /// A dose logged: two soft taps, the second a touch firmer ("tick, tock, done").
        case logged
        /// Several doses logged at once: one tap per dose, climbing, then a warm hum.
        case logAll
        /// A block done: a small rising three-step.
        case complete
        /// Picking an answer, a chip, a day.
        case choose
        /// Any button.
        case tap
        /// A switch flipped.
        case toggle
        /// A slider passing a step.
        case tick
        /// "I understand" on the medical notice: firm and deliberate.
        case acknowledge
        /// Account made, trial started, setup finished.
        case success
        /// A coach mark appearing.
        case nudge
        /// Something needs a second look (the double-dose guard, a limit reached).
        case caution
        /// One breath of the breathing page: in (rising) or out (falling).
        case breatheIn, breatheOut
    }

    var isEnabled: Bool { UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true }
    private var strength: Float { Float(UserDefaults.standard.object(forKey: "hapticStrength") as? Double ?? 1) }
    private var sliderTicks: Bool { UserDefaults.standard.object(forKey: "sliderTicks") as? Bool ?? true }

    private let player = HapticPlayer()
    private var lastTick = Date.distantPast

    func play(_ moment: Moment) {
        guard isEnabled else { return }
        if moment == .tick {
            guard sliderTicks, Date.now.timeIntervalSince(lastTick) > 0.035 else { return }
            lastTick = .now
        }
        let scaled = moment.events.map { ($0.0, min(1, $0.1 * strength), $0.2, $0.3) }
        if !player.play(scaled) { fallback(moment) }
    }

    /// A continuous rise while the person holds "log another" — they can feel the confirm arriving.
    func beginHoldRamp(seconds: Double) {
        guard isEnabled else { return }
        _ = player.startRamp(seconds: seconds)
    }

    func endHoldRamp() { player.stopRamp() }

    private func fallback(_ moment: Moment) {
        switch moment {
        case .logged, .logAll, .complete, .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .caution: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .choose, .land, .tick, .toggle: UISelectionFeedbackGenerator().selectionChanged()
        case .tap, .nudge: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .acknowledge: UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .arrival, .splash, .breatheIn, .breatheOut: UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.6)
        }
    }
}

extension Haptics.Moment {
    /// (time, intensity, sharpness, duration — 0 means transient)
    var events: [(Double, Float, Float, Double)] {
        switch self {
        case .arrival: [(0, 0.12, 0.05, 1.1), (0.35, 0.35, 0.2, 0), (0.62, 0.45, 0.25, 0), (0.95, 0.6, 0.3, 0)]
        case .splash: [(0, 0.08, 0.05, 1.6), (0.9, 0.3, 0.15, 0), (1.3, 0.45, 0.2, 0), (1.65, 0.8, 0.35, 0), (1.72, 0.25, 0.1, 0.5)]
        case .land: [(0, 0.35, 0.2, 0)]
        case .logged: [(0, 0.45, 0.3, 0), (0.13, 0.75, 0.45, 0), (0.2, 0.18, 0.1, 0.35)]
        case .logAll: [(0, 0.4, 0.3, 0), (0.12, 0.55, 0.38, 0), (0.24, 0.7, 0.45, 0), (0.36, 0.9, 0.55, 0), (0.44, 0.22, 0.1, 0.5)]
        case .complete: [(0, 0.35, 0.25, 0), (0.09, 0.5, 0.35, 0), (0.18, 0.75, 0.5, 0)]
        case .choose: [(0, 0.5, 0.4, 0)]
        case .tap: [(0, 0.35, 0.5, 0)]
        case .toggle: [(0, 0.5, 0.6, 0), (0.06, 0.25, 0.3, 0)]
        case .tick: [(0, 0.28, 0.7, 0)]
        case .acknowledge: [(0, 0.7, 0.6, 0), (0.16, 0.9, 0.7, 0)]
        case .success: [(0, 0.3, 0.2, 0), (0.1, 0.55, 0.3, 0), (0.22, 0.85, 0.4, 0), (0.3, 0.2, 0.1, 0.6)]
        case .nudge: [(0, 0.25, 0.15, 0), (0.18, 0.35, 0.2, 0)]
        case .caution: [(0, 0.6, 0.8, 0), (0.12, 0.6, 0.8, 0)]
        case .breatheIn: [(0, 0.05, 0.05, 4.0), (1.0, 0.12, 0.08, 0), (2.0, 0.2, 0.1, 0), (3.0, 0.3, 0.12, 0)]
        case .breatheOut: [(0, 0.3, 0.12, 0), (1.5, 0.2, 0.1, 0), (3.0, 0.12, 0.08, 0), (4.5, 0.06, 0.05, 0)]
        }
    }
}

/// Owns the Core Haptics engine off the main actor. Engines are recreated lazily after resets.
nonisolated final class HapticPlayer: @unchecked Sendable {
    private let lock = NSLock()
    private var engine: CHHapticEngine?
    private var ramp: CHHapticAdvancedPatternPlayer?
    private let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private func readyEngine() -> CHHapticEngine? {
        guard supported else { return nil }
        if engine == nil {
            engine = try? CHHapticEngine()
            engine?.isAutoShutdownEnabled = true
            engine?.stoppedHandler = { [weak self] _ in self?.reset() }
            engine?.resetHandler = { [weak self] in self?.reset() }
        }
        try? engine?.start()
        return engine
    }

    private func reset() {
        lock.lock(); defer { lock.unlock() }
        engine = nil
        ramp = nil
    }

    /// Returns false when haptics aren't available (e.g. Simulator) so callers can fall back.
    func play(_ events: [(Double, Float, Float, Double)]) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard let engine = readyEngine() else { return false }
        let hapticEvents = events.map { time, intensity, sharpness, duration in
            CHHapticEvent(eventType: duration > 0 ? .hapticContinuous : .hapticTransient,
                          parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                       CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)],
                          relativeTime: time, duration: duration)
        }
        guard let pattern = try? CHHapticPattern(events: hapticEvents, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return false }
        try? player.start(atTime: CHHapticTimeImmediate)
        return true
    }

    func startRamp(seconds: Double) -> Bool {
        lock.lock(); defer { lock.unlock() }
        guard let engine = readyEngine() else { return false }
        let event = CHHapticEvent(eventType: .hapticContinuous,
                                  parameters: [CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                                               CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)],
                                  relativeTime: 0, duration: seconds)
        let curve = CHHapticParameterCurve(parameterID: .hapticIntensityControl,
                                           controlPoints: [.init(relativeTime: 0, value: 0.08), .init(relativeTime: seconds, value: 0.8)],
                                           relativeTime: 0)
        guard let pattern = try? CHHapticPattern(events: [event], parameterCurves: [curve]),
              let player = try? engine.makeAdvancedPlayer(with: pattern) else { return false }
        ramp = player
        try? player.start(atTime: CHHapticTimeImmediate)
        return true
    }

    func stopRamp() {
        lock.lock(); defer { lock.unlock() }
        try? ramp?.stop(atTime: CHHapticTimeImmediate)
        ramp = nil
    }
}
