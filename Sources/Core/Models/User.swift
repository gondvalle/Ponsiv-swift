import Foundation

public struct User: Codable, Identifiable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var email: String
    public var passwordHash: String
    public var name: String
    public var handle: String
    public var avatarPath: String?
    public var age: Int?
    public var city: String?
    public var sex: String?
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        email: String,
        passwordHash: String,
        name: String,
        handle: String,
        avatarPath: String? = nil,
        age: Int? = nil,
        city: String? = nil,
        sex: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.name = name
        self.handle = handle
        self.avatarPath = avatarPath
        self.age = age
        self.city = city
        self.sex = sex
        self.createdAt = createdAt
    }
}

public extension User {
    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map { String($0) } ?? ""
        let last = parts.dropFirst().first?.first.map { String($0) } ?? ""
        return (first + last).uppercased()
    }
}
