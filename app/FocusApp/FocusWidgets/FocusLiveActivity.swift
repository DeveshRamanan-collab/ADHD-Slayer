import SwiftUI
import WidgetKit
import FocusGlance

/// Both Live Activities share one configuration; the attributes' `kind` picks the views. The app
/// starts, updates and ends them (see `LiveActivityController`); nothing here fetches anything.
struct FocusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusActivityAttributes.self) { context in
            Group {
                switch context.attributes.kind {
                case .focusSession: FocusModeLockScreen(context: context)
                case .day: YourDayLockScreen(context: context)
                }
            }
            .activitySystemActionForegroundColor(GlancePalette.accent.darkColor)
        } dynamicIsland: { context in
            switch context.attributes.kind {
            case .focusSession: FocusModeIsland.make(context)
            case .day: YourDayIsland.make(context)
            }
        }
        // The Watch Smart Stack and CarPlay use the small family; the Lock Screen the medium one.
        .supplementalActivityFamilies([.small, .medium])
    }
}
