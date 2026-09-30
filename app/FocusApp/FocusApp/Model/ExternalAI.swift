import Foundation
import FocusPlanning
import Observation

/// Optional: talk to your own AI (OpenAI, Anthropic, or anything with an OpenAI-style API)
/// with your own key. Everything in the app keeps running on Apple's on-device model whether this is
/// on or off; your AI is only used when you ask it something yourself.
///
/// What it may see: task names and times, if you allow it. What it never sees: medication, doses,
/// check-ins, health data, your name or your account.
enum AIProvider: String, Codable, CaseIterable, Identifiable {
    case openAI, anthropic, custom
    var id: Self { self }

    var label: String {
        switch self {
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .custom: "Something else (OpenAI-style)"
        }
    }

    var defaultModel: String {
        switch self {
        case .openAI: "gpt-4.1-mini"
        case .anthropic: "claude-sonnet-5"
        case .custom: ""
        }
    }
}

struct ExternalAIConfig: Codable, Equatable {
    var provider: AIProvider = .openAI
    var model = AIProvider.openAI.defaultModel
    var customEndpoint = ""
    var enabled = false
    var acceptedWarningAt: Date?
    var shareTaskNames = true
    var shareTimes = true
}

@MainActor @Observable
final class ExternalAI {
    var config: ExternalAIConfig {
        didSet { if let data = try? JSONEncoder().encode(config) { UserDefaults.standard.set(data, forKey: "externalAI") } }
    }
    private(set) var hasKey: Bool

    enum AIError: LocalizedError {
        case noKey, badEndpoint, http(Int), unreadable
        var errorDescription: String? {
            switch self {
            case .noKey: "Add your key first."
            case .badEndpoint: "That address doesn’t look like an API endpoint."
            case .http(let code): code == 401 ? "Your provider didn’t accept that key." : "Your provider said no (error \(code))."
            case .unreadable: "Your provider answered, but not in a way we could read."
            }
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: "externalAI"), let saved = try? JSONDecoder().decode(ExternalAIConfig.self, from: data) {
            config = saved
        } else {
            config = ExternalAIConfig()
        }
        hasKey = Keychain.get("externalAIKey") != nil
    }

    var isReady: Bool { config.enabled && hasKey && config.acceptedWarningAt != nil }

    func setKey(_ key: String?) {
        let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines)
        Keychain.set(trimmed?.isEmpty == false ? trimmed : nil, for: "externalAIKey")
        hasKey = Keychain.get("externalAIKey") != nil
    }

    func disconnect() {
        setKey(nil)
        config = ExternalAIConfig()
    }

    /// Sends one question plus the context the person allowed. Nothing is stored by us.
    func ask(_ question: String, context: String) async throws -> String {
        guard let key = Keychain.get("externalAIKey") else { throw AIError.noKey }
        let system = "You are helping someone with ADHD think through their day. Be brief and kind. Never give medical or medication advice; if asked, say to talk to their prescriber."
        let user = context.isEmpty ? question : "My day so far:\n\(context)\n\n\(question)"
        var request: URLRequest
        switch config.provider {
        case .anthropic:
            request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
            request.setValue(key, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "model": config.model, "max_tokens": 600, "system": system,
                "messages": [["role": "user", "content": user]]])
        case .openAI, .custom:
            let base = config.provider == .openAI ? "https://api.openai.com/v1" : config.customEndpoint
            guard let url = URL(string: base.hasSuffix("/chat/completions") ? base : base + "/chat/completions"),
                  url.scheme == "https" else { throw AIError.badEndpoint }
            request = URLRequest(url: url)
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "model": config.model,
                "messages": [["role": "system", "content": system], ["role": "user", "content": user]]])
        }
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) { throw AIError.http(http.statusCode) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw AIError.unreadable }
        let text: String? = switch config.provider {
        case .anthropic: ((json["content"] as? [[String: Any]])?.first?["text"] as? String)
        case .openAI, .custom: ((json["choices"] as? [[String: Any]])?.first?["message"] as? [String: Any])?["content"] as? String
        }
        guard let text, !text.isEmpty else { throw AIError.unreadable }
        let tidy = text.replacingOccurrences(of: " — ", with: ", ").replacingOccurrences(of: "—", with: ", ").replacingOccurrences(of: " – ", with: " to ")
        // The same safety gate as everything else: answers that stray into doses or treatment claims
        // are replaced with the referral line, never shown.
        switch SafetyGate().screen(tidy, context: .aiRephrase) {
        case .allow(let ok): return ok
        case .replaced(let referral, _): return referral + " Your AI’s answer talked about medication, so Focus didn’t show it."
        }
    }
}
