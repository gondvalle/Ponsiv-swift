import Foundation

public struct Look: Codable, Identifiable, Equatable, Hashable, Sendable {
    public struct Author: Codable, Equatable, Hashable, Sendable {
        public var name: String
        public var avatarPath: String?

        public init(name: String, avatarPath: String? = nil) {
            self.name = name
            self.avatarPath = avatarPath
        }
    }

    public let id: String
    public var title: String
    public var author: Author
    public var productIDs: [String]
    public var coverPath: String
    public var description: String?
    public var createdAt: Date

    public init(
        id: String,
        title: String,
        author: Author,
        productIDs: [String],
        coverPath: String,
        description: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.productIDs = productIDs
        self.coverPath = coverPath
        self.description = description
        self.createdAt = createdAt
    }
}
