import Foundation
import AppIntents

/// Registers this package's intents with the App Intents metadata of the app and of the widget
/// extension (each includes it from its own `AppIntentsPackage`).
public struct FocusGlanceIntents: AppIntentsPackage {}

#if os(iOS)

/// What the app does when a Live Activity button is pressed. The app sets `GlanceActions.handler` as
/// it launches. The intents below conform to `LiveActivityIntent`, so iOS always runs them in the
/// app's process, launching it in the background first if it isn't running; the widget extension only
/// draws the buttons. That's why a plain static handler is enough to reach the app's model.
@MainActor
public protocol GlanceActionHandling: AnyObject {
    /// Done: the same as Done in Focus mode. Marks the task done and ends the session.
    func endFocusSession() async
    /// +5 min.
    func extendFocusSession(byMinutes minutes: Int) async
    /// Logs everything set for about now through the double-dose guard; returns the spoken reply.
    func logEverythingSetForNow() async -> String
}

@MainActor
public enum GlanceActions {
    public static var handler: (any GlanceActionHandling)?
}

/// Done, from Focus mode's Live Activity.
public struct EndFocusSessionIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "End Focus mode"
    public static let description = IntentDescription("Marks the task you’re focusing on as done and ends Focus mode.")
    /// Only for the Live Activity's button, not for Shortcuts or Spotlight.
    public static let isDiscoverable = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        await GlanceActions.handler?.endFocusSession()
        return .result()
    }
}

/// +5 min, from Focus mode's Live Activity.
public struct ExtendFocusSessionIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Five more minutes"
    public static let description = IntentDescription("Adds five minutes to Focus mode.")
    public static let isDiscoverable = false

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult {
        await GlanceActions.handler?.extendFocusSession(byMinutes: 5)
        return .result()
    }
}

/// One press, everything set for about now gets logged. Works from the Action button, Siri,
/// Shortcuts, Spotlight, the Lock Screen and the Your day Live Activity, and goes through exactly the
/// same double-dose check as the Log all button. It lives here, not in the app target, so the widget
/// extension can put it on a button; as a `LiveActivityIntent` it still runs in the app's process.
public struct LogMedicationIntent: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Log my medication"
    public static let description = IntentDescription("Logs every dose you’ve set for about now, with the same double-dose check as the app.")
    /// Runs without opening the app.
    public static let supportedModes: IntentModes = .background
    /// Medication data is fully protected while the phone is locked, so logging asks for Face ID first
    /// (it also means nobody else can log on a locked phone).
    public static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let spoken = await GlanceActions.handler?.logEverythingSetForNow() ?? "Couldn’t save that. Nothing was changed."
        return .result(dialog: IntentDialog(stringLiteral: spoken))
    }
}

#endif
