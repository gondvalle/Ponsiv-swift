import Foundation
import UniformTypeIdentifiers

public struct PhotoStorage {
    private let directory: URL
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let dir = base.appendingPathComponent("Looks", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        self.directory = dir
    }

    public func persistTemporaryImage(from source: URL, preferredName: String) throws -> String {
        let sanitizedName = preferredName.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "_", options: .regularExpression)
        let filename = sanitizedName.isEmpty ? UUID().uuidString : sanitizedName
        let ext = source.pathExtension.isEmpty ? "jpg" : source.pathExtension
        let destination = directory.appendingPathComponent("\(filename).\(ext)")
        try? fileManager.removeItem(at: destination)
        try fileManager.copyItem(at: source, to: destination)
        return destination.absoluteString
    }
}
