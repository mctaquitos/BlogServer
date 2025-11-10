import Foundation

enum DataStore {
    // MARK: - Config

    private static var contentDirectory: String = "Content"
    private static let queue = DispatchQueue(label: "DataStore.queue")

    // How often we check for changes (seconds)
    private static let reloadInterval: TimeInterval = 86400

    // MARK: - State

    private static var postsCache: [Post] = []
    private static var lastLoaded: Date = .distantPast
    private static var lastKnownFileSignatures: [String: Date] = [:] // path -> mtime

    // MARK: - Public API

    static func configure(contentDirectory: String) {
        queue.sync {
            self.contentDirectory = contentDirectory
            // Force initial load
            _ = try? reloadIfNeeded(force: true)
        }
    }

    static func allPosts() -> [Post] {
        queue.sync {
            try? reloadIfNeeded()
            return postsCache
        }
    }

    static func findPost(slug: String) -> Post? {
        queue.sync {
            try? reloadIfNeeded()
            return postsCache.first { $0.slug == slug }
        }
    }

    // MARK: - Reload Logic

    @discardableResult
    private static func reloadIfNeeded(force: Bool = false) throws -> Bool {
        let now = Date()

        if !force && now.timeIntervalSince(lastLoaded) < reloadInterval {
            return false
        }

        let fm = FileManager.default
        let baseURL = URL(fileURLWithPath: contentDirectory, isDirectory: true)

        guard let files = try? fm.contentsOfDirectory(at: baseURL,
                                                      includingPropertiesForKeys: [.contentModificationDateKey],
                                                      options: [.skipsHiddenFiles]) else {
            if postsCache.isEmpty {
                Logger.error("Could not read Content directory at \(contentDirectory)")
            }
            lastLoaded = now
            return false
        }

        // Build current signature map (mtime per .md file)
        var currentSigs: [String: Date] = [:]
        var mdFiles: [URL] = []

        for url in files where url.pathExtension.lowercased() == "md" {
            let path = url.path
            let attrs = try? fm.attributesOfItem(atPath: path)
            let mtime = (attrs?[.modificationDate] as? Date) ?? .distantPast
            currentSigs[path] = mtime
            mdFiles.append(url)
        }

        // Detect changes: count difference, removed files, or any mtime change
        let changed = hasFileChanges(new: currentSigs, old: lastKnownFileSignatures)

        if !force && !changed {
            lastLoaded = now
            return false
        }

        // Reload all posts
        var loaded: [Post] = []

        for url in mdFiles {
            guard let data = try? Data(contentsOf: url),
                  let text = String(data: data, encoding: .utf8)
            else { continue }

            let slug = url.deletingPathExtension().lastPathComponent
            let (title, body) = extractTitleAndBody(from: text, fallbackSlug: slug)
            loaded.append(Post(slug: slug, title: title, markdownBody: body))
        }

        loaded.sort { $0.slug < $1.slug }

        postsCache = loaded
        lastKnownFileSignatures = currentSigs
        lastLoaded = now

        Logger.info("Reloaded \(loaded.count) posts from \(contentDirectory)")
        return true
    }

    private static func hasFileChanges(new: [String: Date], old: [String: Date]) -> Bool {
        if new.count != old.count { return true }
        for (path, mtime) in new {
            guard let oldTime = old[path] else { return true }
            if mtime != oldTime { return true }
        }
        return false
    }

    // MARK: - Helpers

    private static func extractTitleAndBody(from text: String, fallbackSlug: String) -> (String, String) {
        let lines = text.split(whereSeparator: \.isNewline, omittingEmptySubsequences: false)

        if let idx = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("#") }) {
            let headingLine = lines[idx].trimmingCharacters(in: .whitespaces)
            let title = headingLine
                .trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespaces))

            var bodyLines = Array(lines)
            bodyLines.remove(at: idx)
            let body = bodyLines.joined(separator: "\n")

            return (title.isEmpty ? fallbackSlug : title,
                    body.isEmpty ? text : body)
        } else {
            return (fallbackSlug, text)
        }
    }
}
