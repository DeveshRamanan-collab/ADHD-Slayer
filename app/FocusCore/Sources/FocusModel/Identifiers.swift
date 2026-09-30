import Foundation

public struct ProductID: Hashable, Sendable, Codable, CustomStringConvertible {
    public let raw: UUID
    public init(_ raw: UUID = UUID()) { self.raw = raw }
    public var description: String { raw.uuidString }
}

public struct DoseEventID: Hashable, Sendable, Codable {
    public let raw: UUID
    public init(_ raw: UUID = UUID()) { self.raw = raw }
}

public struct TaskID: Hashable, Sendable, Codable, CustomStringConvertible {
    public let raw: String
    public init(_ raw: String) { self.raw = raw }
    public var description: String { raw }
}
