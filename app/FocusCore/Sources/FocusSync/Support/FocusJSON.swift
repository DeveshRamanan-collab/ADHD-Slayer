import Foundation

/// JSON as the API speaks it: UTF-8, camelCase, times in UTC ISO 8601 with milliseconds and `Z`
/// (for example `2026-09-30T01:02:03.456Z`).
public enum FocusJSON {
    private static let withMilliseconds = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let withoutFraction = Date.ISO8601FormatStyle()

    /// `2026-09-30T01:02:03.456Z`: always three fractional digits, always UTC.
    ///
    /// Built from whole milliseconds (rounded to the nearest), so formatting a parsed time gives back
    /// exactly the same text. Formatting the `Date` directly would truncate `.456` read back as
    /// `.45599999` to `.455`, and drift a millisecond on every round trip.
    public static func string(from date: Date) -> String {
        let totalMilliseconds = (date.timeIntervalSince1970 * 1000).rounded()
        let seconds = (totalMilliseconds / 1000).rounded(.down)
        let milliseconds = Int(totalMilliseconds - seconds * 1000)
        let whole = withoutFraction.format(Date(timeIntervalSince1970: seconds))
        let fraction = String(milliseconds + 1000).dropFirst()
        return whole.dropLast() + "." + fraction + "Z"
    }

    /// Reads times with or without fractional seconds.
    public static func date(from string: String) -> Date? {
        if let date = try? withMilliseconds.parse(string) { return date }
        return try? withoutFraction.parse(string)
    }

    /// Keys sorted and slashes unescaped, so a body's bytes (and its hash in a device proof) are stable.
    public static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(FocusJSON.string(from: date))
        }
        return encoder
    }

    public static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = FocusJSON.date(from: text) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected an ISO 8601 time, got \(text).")
            }
            return date
        }
        return decoder
    }

    public static func encode(_ value: some Encodable) throws -> Data {
        try makeEncoder().encode(value)
    }

    public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try makeDecoder().decode(type, from: data)
    }

    /// Truncates to whole milliseconds, the precision the wire carries.
    static func truncatedToMilliseconds(_ time: Date) -> Date {
        FocusJSON.date(from: FocusJSON.string(from: time)) ?? time
    }
}
