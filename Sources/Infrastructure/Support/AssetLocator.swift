import Foundation

enum AssetLocator {
    private static func candidateBaseURLs() -> [URL] {
        var urls: [URL] = []

        #if os(iOS) || os(tvOS) || os(watchOS) || os(macOS)
        if let resourceURL = Bundle.main.resourceURL {
            urls.append(resourceURL.appendingPathComponent("assets"))
        }
        #endif

        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        urls.append(cwd.appendingPathComponent("assets"))
        return urls
    }

    static func assetsBaseURL() -> URL? {
        let fm = FileManager.default
        for url in candidateBaseURLs() {
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                return url
            }
        }
        return nil
    }

    static func url(for relativePath: String) -> URL? {
        guard let base = assetsBaseURL() else { return nil }
        let candidate = base.appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }
        return nil
    }
}
