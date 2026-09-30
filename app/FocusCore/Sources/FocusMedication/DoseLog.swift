import Foundation
import FocusModel

/// Proof that a person deliberately asked for a dose write: a button, the Watch, double tap,
/// a Control, the Action button or an explicitly invoked Siri/Shortcut intent.
/// Scheduling, learning and AI targets cannot import this module, so they can never mint one.
public struct UserGesture: Sendable {
    public enum Origin: String, Sendable { case button, watchButton, doubleTap, control, actionButton, siri, shortcut }
    public let origin: Origin
    public let at: Date
    public init(origin: Origin, at: Date = .now) {
        self.origin = origin
        self.at = at
    }
}

public struct DoseLogRequest: Sendable {
    public var product: ProductID
    public var takenAt: Date
    public var ateFirst: Bool?
    public var isBooster: Bool
    public var source: DoseSource

    public init(product: ProductID, takenAt: Date, ateFirst: Bool? = nil, isBooster: Bool = false, source: DoseSource = .app) {
        self.product = product
        self.takenAt = takenAt
        self.ateFirst = ateFirst
        self.isBooster = isBooster
        self.source = source
    }
}

public enum DoseLogOutcome: Sendable, Equatable {
    case logged(DoseEvent)
    /// The same product was logged within its minimum re-log interval. Nothing was written.
    case needsDeliberateConfirm(previous: DoseEvent)
}

/// A local audit entry for every change to the log (spec §8.2 rule 8).
public struct DoseAuditEntry: Sendable, Equatable {
    public enum Action: String, Sendable { case logged, loggedAfterConfirm, undone, edited }
    public var action: Action
    public var event: DoseEvent
    public var gesture: UserGesture.Origin
    public var at: Date
}

public protocol DoseLogging: DoseTimelineReading {
    func record(_ request: DoseLogRequest, by gesture: UserGesture) async throws(DomainError) -> DoseLogOutcome
    func recordConfirmingDuplicate(_ request: DoseLogRequest, previous: DoseEventID, by gesture: UserGesture) async throws(DomainError) -> DoseEvent
    func undo(_ id: DoseEventID, by gesture: UserGesture) async throws(DomainError)
    func edit(_ id: DoseEventID, takenAt: Date, by gesture: UserGesture) async throws(DomainError) -> DoseEvent
}

/// In-memory implementation used by previews, tests and the MVP prototype.
/// The shipping store is the event-sourced SQLite ledger (system-design §4); the contract is identical.
public actor DoseLog: DoseLogging {
    private var products: [ProductID: Product]
    private var events: [DoseEvent] = []
    public private(set) var audit: [DoseAuditEntry] = []

    public init(products: [Product], events: [DoseEvent] = []) {
        self.products = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        self.events = events.sorted { $0.takenAt < $1.takenAt }
    }

    /// Adds a medication the person has just set up, or updates its name or relog guard. Past events
    /// are kept even if a product is later removed from the person's list (history is never rewritten).
    public func register(_ product: Product) {
        products[product.id] = product
    }

    public func record(_ request: DoseLogRequest, by gesture: UserGesture) async throws(DomainError) -> DoseLogOutcome {
        guard let product = products[request.product] else { throw .notFound(entity: "product") }
        guard request.takenAt <= gesture.at.addingTimeInterval(60) else {
            throw .validation(field: "takenAt", reason: "A dose can't be logged in the future")
        }
        if let previous = recentDose(of: product, near: request.takenAt) {
            return .needsDeliberateConfirm(previous: previous)
        }
        let event = append(request, gesture: gesture, action: .logged)
        return .logged(event)
    }

    public func recordConfirmingDuplicate(_ request: DoseLogRequest, previous: DoseEventID, by gesture: UserGesture) async throws(DomainError) -> DoseEvent {
        guard products[request.product] != nil else { throw .notFound(entity: "product") }
        guard events.contains(where: { $0.id == previous }) else { throw .notFound(entity: "previous dose") }
        return append(request, gesture: gesture, action: .loggedAfterConfirm)
    }

    public func undo(_ id: DoseEventID, by gesture: UserGesture) async throws(DomainError) {
        guard let index = events.firstIndex(where: { $0.id == id }) else { throw .notFound(entity: "dose") }
        let removed = events.remove(at: index)
        audit.append(DoseAuditEntry(action: .undone, event: removed, gesture: gesture.origin, at: gesture.at))
    }

    public func edit(_ id: DoseEventID, takenAt: Date, by gesture: UserGesture) async throws(DomainError) -> DoseEvent {
        guard let index = events.firstIndex(where: { $0.id == id }) else { throw .notFound(entity: "dose") }
        events[index].takenAt = takenAt
        events.sort { $0.takenAt < $1.takenAt }
        let edited = events.first { $0.id == id }!
        audit.append(DoseAuditEntry(action: .edited, event: edited, gesture: gesture.origin, at: gesture.at))
        return edited
    }

    // MARK: DoseTimelineReading

    public func doses(in interval: DateInterval) async -> [DoseEvent] {
        events.filter { interval.contains($0.takenAt) }
    }

    public func lastDose(of product: ProductID) async -> DoseEvent? {
        events.last { $0.product == product }
    }

    // MARK: Private

    private func recentDose(of product: Product, near takenAt: Date) -> DoseEvent? {
        events.last { event in
            event.product == product.id && abs(event.takenAt.timeIntervalSince(takenAt)) < product.minimumRelogInterval
        }
    }

    private func append(_ request: DoseLogRequest, gesture: UserGesture, action: DoseAuditEntry.Action) -> DoseEvent {
        let event = DoseEvent(product: request.product, takenAt: request.takenAt, loggedAt: gesture.at,
                              source: request.source, ateFirst: request.ateFirst, isBooster: request.isBooster)
        events.append(event)
        events.sort { $0.takenAt < $1.takenAt }
        audit.append(DoseAuditEntry(action: action, event: event, gesture: gesture.origin, at: gesture.at))
        return event
    }
}
