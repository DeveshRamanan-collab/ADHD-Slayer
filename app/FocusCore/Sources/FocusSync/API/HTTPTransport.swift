import Foundation

public struct HTTPRequest: Sendable, Equatable {
    public var method: String
    public var url: URL
    /// Sent exactly as given.
    public var headers: [String: String]
    public var body: Data?
    public var timeout: TimeInterval?

    public init(method: String, url: URL, headers: [String: String] = [:], body: Data? = nil, timeout: TimeInterval? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }

    /// Case-insensitive header lookup.
    public func header(_ name: String) -> String? {
        headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    /// The path and query exactly as sent, which is what a device proof signs.
    public var pathWithQuery: String { url.pathWithQuery }
}

public struct HTTPResponse: Sendable, Equatable {
    public var statusCode: Int
    public var headers: [String: String]
    public var body: Data

    public init(statusCode: Int, headers: [String: String] = [:], body: Data = Data()) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }

    public func header(_ name: String) -> String? {
        headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    public var isSuccess: Bool { (200..<300).contains(statusCode) }
}

/// Sends one request. The app uses `URLSessionTransport`; tests use a fake.
public protocol HTTPTransport: Sendable {
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}

/// A `URLSession` with no cookies and no cache, TLS 1.2 or newer (02-backend.md, App network rules).
public struct URLSessionTransport: HTTPTransport {
    public let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }

    /// The one session for the API.
    public static func api() -> URLSessionTransport {
        URLSessionTransport(session: URLSession(configuration: baseConfiguration()))
    }

    /// A separate ephemeral session for crash reports and usage counts. It never carries a token.
    public static func anonymous() -> URLSessionTransport {
        let configuration = baseConfiguration()
        configuration.httpAdditionalHeaders = nil
        return URLSessionTransport(session: URLSession(configuration: configuration))
    }

    private static func baseConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCredentialStorage = nil
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        configuration.waitsForConnectivity = false
        return configuration
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
        urlRequest.httpShouldHandleCookies = false
        if let timeout = request.timeout { urlRequest.timeoutInterval = timeout }
        for (name, value) in request.headers { urlRequest.setValue(value, forHTTPHeaderField: name) }
        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse("Not an HTTP response.")
        }
        var headers: [String: String] = [:]
        for (key, value) in http.allHeaderFields {
            if let name = key as? String { headers[name] = "\(value)" }
        }
        return HTTPResponse(statusCode: http.statusCode, headers: headers, body: data)
    }
}

extension URL {
    /// `/v1/keys/slots/0199...?a=b`: the percent-encoded path plus the query, as sent on the wire.
    var pathWithQuery: String {
        let path = self.path(percentEncoded: true)
        let base = path.isEmpty ? "/" : path
        if let query = self.query(percentEncoded: true) { return base + "?" + query }
        return base
    }
}
