import Foundation

/// Where the API lives and how the app introduces itself.
public struct APIConfiguration: Sendable, Equatable {
    /// For example `https://api.focus.adhdslayer.au/v1` or `http://localhost:8080/v1`.
    public var baseURL: URL
    /// Config and copy come through CloudFront: `https://cdn.focus.adhdslayer.au/v1`.
    public var cdnURL: URL
    public var appVersion: String
    public var build: String
    public var osVersion: String
    /// Every API call except config.
    public var requestTimeout: TimeInterval
    /// `GET /config` never blocks a screen: 5 seconds (02-backend.md, Config).
    public var configTimeout: TimeInterval

    public init(baseURL: URL, cdnURL: URL? = nil, appVersion: String, build: String, osVersion: String,
                requestTimeout: TimeInterval = 30, configTimeout: TimeInterval = 5) {
        self.baseURL = baseURL
        self.cdnURL = cdnURL ?? baseURL
        self.appVersion = appVersion
        self.build = build
        self.osVersion = osVersion
        self.requestTimeout = requestTimeout
        self.configTimeout = configTimeout
    }

    /// `Focus/<version> (<build>; iOS <os>)` on every request.
    public var userAgent: String { "Focus/\(appVersion) (\(build); iOS \(osVersion))" }

    /// The origin without `/v1`, for `GET /healthz`.
    public var rootURL: URL {
        baseURL.lastPathComponent == "v1" ? baseURL.deletingLastPathComponent() : baseURL
    }

    /// Reads `FocusAPIBaseURL` and `FocusCDNBaseURL` from Info.plist. Returns nil when the API base is
    /// empty, which means "no server": the app keeps its local sign-in and works fully offline.
    ///
    /// With `allowEnvironmentOverride` (Debug builds only) `FOCUS_API_BASE_URL` and
    /// `FOCUS_CDN_BASE_URL` in the environment win, so the simulator can point at
    /// `http://localhost:8080/v1`. When only the API is overridden, the CDN base follows it, as in
    /// local development where one server answers both.
    public static func resolve(infoDictionary: [String: Any], environment: [String: String] = [:],
                               allowEnvironmentOverride: Bool = false,
                               osVersion: String = APIConfiguration.currentOSVersion) -> APIConfiguration? {
        var api = cleaned(infoDictionary["FocusAPIBaseURL"])
        var cdn = cleaned(infoDictionary["FocusCDNBaseURL"])
        if allowEnvironmentOverride {
            if let override = cleaned(environment["FOCUS_API_BASE_URL"]) {
                api = override
                cdn = cleaned(environment["FOCUS_CDN_BASE_URL"]) ?? override
            } else if let override = cleaned(environment["FOCUS_CDN_BASE_URL"]) {
                cdn = override
            }
        }
        guard let apiText = api, let baseURL = validURL(apiText) else { return nil }
        let cdnURL = cdn.flatMap(validURL) ?? baseURL
        return APIConfiguration(baseURL: baseURL, cdnURL: cdnURL,
                                appVersion: cleaned(infoDictionary["CFBundleShortVersionString"]) ?? "0",
                                build: cleaned(infoDictionary["CFBundleVersion"]) ?? "0",
                                osVersion: osVersion)
    }

    /// `26.0` or `26.0.1`.
    public static var currentOSVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return version.patchVersion > 0
            ? "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
            : "\(version.majorVersion).\(version.minorVersion)"
    }

    private static func cleaned(_ value: Any?) -> String? {
        guard let text = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty, !text.hasPrefix("$(") else { return nil }
        return text
    }

    private static func validURL(_ text: String) -> URL? {
        var trimmed = text
        while trimmed.hasSuffix("/") { trimmed.removeLast() }
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http", url.host() != nil else { return nil }
        return url
    }
}

/// The phone's model identifier (`iPhone17,1`), as sent in the device object.
public enum DeviceModel {
    public static var identifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"], !simulated.isEmpty {
            return simulated
        }
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
