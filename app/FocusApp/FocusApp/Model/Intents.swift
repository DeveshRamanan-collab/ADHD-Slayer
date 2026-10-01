import AppIntents
import Foundation

/// One press, everything due gets logged. Works from the Action button, Siri, Shortcuts, Spotlight and
/// the Lock Screen, and goes through exactly the same double-dose check as the Log all button.
struct LogMedicationIntent: AppIntent {
    static let title: LocalizedStringResource = "Log my medication"
    static let description = IntentDescription("Logs every dose you’ve set for about now, with the same double-dose check as the app.")
    static let openAppWhenRun = false
    /// Medication data is fully protected while the phone is locked, so logging asks for Face ID first
    /// (it also means nobody else can log on a locked phone).
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Dependency private var model: AppModel

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let spoken = await model.logAllDue(origin: .actionButton).spoken
        return .result(dialog: IntentDialog(stringLiteral: spoken))
    }
}

struct OpenMedicationIntent: AppIntent {
    static let title: LocalizedStringResource = "Open my medication"
    static let description = IntentDescription("Opens the Medication page.")
    static let openAppWhenRun = true

    @Dependency private var model: AppModel

    @MainActor func perform() async throws -> some IntentResult {
        model.route = .medication
        return .result()
    }
}

struct FocusShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: LogMedicationIntent(),
                    phrases: ["Log my meds in \(.applicationName)", "Log my medication in \(.applicationName)", "\(.applicationName) log meds"],
                    shortTitle: "Log my meds", systemImageName: "checkmark.circle")
        AppShortcut(intent: OpenMedicationIntent(),
                    phrases: ["Open my medication in \(.applicationName)"],
                    shortTitle: "Medication", systemImageName: "pills")
    }
    static let shortcutTileColor: ShortcutTileColor = .grayBrown
}
