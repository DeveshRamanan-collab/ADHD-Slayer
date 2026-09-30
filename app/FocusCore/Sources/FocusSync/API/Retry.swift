import Foundation

/// Background retries for writes that must eventually land: 2^n seconds with jitter, capped at
/// 6 hours (02-backend.md, App network rules). Never used for anything a screen waits on.
public struct RetryPolicy: Sendable, Equatable {
    /// Nil keeps trying until the task is cancelled.
    public var maxAttempts: Int?
    public var cap: TimeInterval

    public init(maxAttempts: Int? = nil, cap: TimeInterval = 6 * 60 * 60) {
        self.maxAttempts = maxAttempts
        self.cap = cap
    }

    /// The wait after failed attempt `attempt` (1-based): between half and all of 2^attempt seconds,
    /// never more than `cap`, and never less than the server's `Retry-After`. `unit` is the jitter
    /// draw in 0...1.
    public func delay(afterAttempt attempt: Int, retryAfter: TimeInterval? = nil,
                      unit: Double = Double.random(in: 0...1)) -> TimeInterval {
        let exponential = min(cap, pow(2, Double(max(1, min(attempt, 62)))))
        let jittered = exponential / 2 + exponential / 2 * min(max(unit, 0), 1)
        return min(cap, max(jittered, retryAfter ?? 0))
    }

    /// Offline, 5xx, `UPSTREAM_UNAVAILABLE`, `SERVICE_PAUSED` and `RATE_LIMITED` are worth another
    /// try later. Other 4xx aren't: they'd fail the same way again.
    public static func isRetryable(_ error: any Error) -> Bool {
        switch error {
        case APIError.transport:
            return true
        case APIError.server(let server):
            switch server.code {
            case .internalError, .upstreamUnavailable, .servicePaused, .rateLimited: return true
            case .unknown: return server.status >= 500
            default: return false
            }
        default:
            return false
        }
    }
}

/// Runs `operation` until it succeeds, fails in a way retrying won't fix, runs out of attempts, or
/// the task is cancelled. Pass a fixed idempotency key inside `operation` so retries replay.
public func withBackgroundRetry<T: Sendable>(
    policy: RetryPolicy = RetryPolicy(),
    sleep: @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
    _ operation: @Sendable () async throws -> T
) async throws -> T {
    var attempt = 0
    while true {
        attempt += 1
        do {
            return try await operation()
        } catch {
            guard RetryPolicy.isRetryable(error), policy.maxAttempts.map({ attempt < $0 }) ?? true else { throw error }
            let wait = policy.delay(afterAttempt: attempt, retryAfter: (error as? APIError)?.serverError?.retryAfter)
            try await sleep(.milliseconds(Int64(wait * 1000)))
        }
    }
}
