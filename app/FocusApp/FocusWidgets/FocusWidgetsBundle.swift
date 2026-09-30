import WidgetKit
import SwiftUI
import AppIntents
import FocusGlance

/// Focus's widget extension. For now it holds the two Live Activities (Focus mode and Your day);
/// widgets and the Control Center control will join this bundle later.
@main
struct FocusWidgetsBundle: WidgetBundle {
    var body: some Widget {
        FocusLiveActivity()
    }
}

/// Brings the Live Activity buttons' intents (they live in FocusGlance, shared with the app) into
/// this extension's App Intents metadata, so the buttons resolve. They still run in the app's process.
nonisolated struct FocusWidgetsIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { [FocusGlanceIntents.self] }
}
