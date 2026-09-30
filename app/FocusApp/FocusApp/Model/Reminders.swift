import Foundation
import UserNotifications

/// Local notifications the app schedules for itself. Nothing names a condition or a medicine on the
/// Lock Screen, and medication reminders only ever fire at times the person set themselves.
enum Reminders {
    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Two days before a free trial ends, at 10 am: an honest heads-up, with no pressure either way.
    static func scheduleTrialEnding(on end: Date) async {
        guard await requestPermission() else { return }
        let calendar = Calendar.current
        guard let twoDaysBefore = calendar.date(byAdding: .day, value: -2, to: end),
              var fire = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: twoDaysBefore) else { return }
        if fire < .now { fire = .now.addingTimeInterval(60) }
        let content = UNMutableNotificationContent()
        content.title = "Your free month ends \(end.formatted(.dateTime.weekday(.wide)))"
        content.body = "Keep Plus, or let it lapse and carry on free. Both are completely fine. You can change it in Settings."
        content.interruptionLevel = .passive
        let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire), repeats: false)
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "trial-ending", content: content, trigger: trigger))
    }
}
