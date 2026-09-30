import Foundation

/// Times as the app writes them: "1:40" rather than "1:40 pm" where the time of day is obvious
/// ("h:mm" in 12-hour locales, "HH:mm" in 24-hour ones), and minutes left as "24:00".
public enum GlanceFormat {
    public static func time(_ date: Date, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        let template = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) ?? "h"
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = template.contains("H") ? "HH:mm" : "h:mm"
        return formatter.string(from: date)
    }

    /// A still timer for a paused session, written like the running one (`showsHours: false`):
    /// "24:00", and "80:00" rather than "1:20:00".
    public static func timer(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    /// "24 minutes left", for VoiceOver.
    public static func minutesLeft(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int((interval / 60).rounded(.up)))
        return minutes == 1 ? "1 minute left" : "\(minutes) minutes left"
    }
}
