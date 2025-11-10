import Foundation

struct Post: Codable {
    let slug: String
    let title: String
    let markdownBody: String

    var htmlBody: String {
        MarkdownRenderer.render(markdownBody)
    }
}

enum ContentType {
    case html
    case json

    static func from(acceptHeader: String?) -> ContentType {
        guard let accept = acceptHeader?.lowercased() else { return .html }
        if accept.contains("application/json") { return .json }
        return .html
    }
}
