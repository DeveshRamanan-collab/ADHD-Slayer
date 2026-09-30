import AppIntents
import Foundation
import FocusGlance

// The intents the Live Activity buttons run live in FocusGlance, so the widget extension can put them
// on buttons as well: `LogMedicationIntent` ("Log my medication": Face ID first, then the same
// double-dose check as Log all), `EndFocusSessionIntent` (Done) and `ExtendFocusSessionIntent`
// (+5 min). All three conform to `LiveActivityIntent`, so iOS runs them in this app's process, where
// `LiveActivityController` (set as `GlanceActions.handler` at launch) carries them out with `AppModel`.

/// Brings FocusGlance's intents into the app's App Intents metadata.
nonisolated struct FocusAppIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { [FocusGlanceIntents.self] }
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
