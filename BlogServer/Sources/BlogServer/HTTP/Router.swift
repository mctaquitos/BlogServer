import NIO
import NIOHTTP1
import Foundation

enum Router {
    static func route(_ head: HTTPRequestHead) -> Response {
        let method = head.method
        let path = head.uri
        let accept = head.headers.first(name: "Accept")
        let contentType = ContentType.from(acceptHeader: accept)

        guard method == .GET else {
            return Response.html("Method Not Allowed", status: .methodNotAllowed)
        }

        let components = path.split(separator: "/").map(String.init)

        // "/" index page
        if components.isEmpty {
            return indexPage(contentType: contentType)
        }

        // "/posts"
        if components.count == 1 && components[0] == "posts" {
            return listPosts(contentType: contentType)
        }

        // "/posts/:slug"
        if components.count == 2 && components[0] == "posts" {
            return showPost(slug: components[1], contentType: contentType)
        }

        // "/api" endpoints
        if components.count == 2 && components[0] == "api" && components[1] == "posts" {
            return listPosts(contentType: .json)
        }
        if components.count == 3 && components[0] == "api" && components[1] == "posts" {
            return showPost(slug: components[2], contentType: .json)
        }

        // "/health"
        if components.count == 1 && components[0] == "health" {
            return health()
        }

        return .notFound()
    }

    // MARK: - Shared HTML boilerplate

    private static func htmlPage(title: String, body: String) -> String {
        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(escapeHTML(title))</title>
          <style>
            :root {
              color-scheme: light dark;
            }
            body {
              font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
              max-width: 720px;
              margin: 0 auto;
              padding: 1.5rem;
              line-height: 1.6;
              background-color: Canvas;
              color: CanvasText;
            }
            a {
              color: LinkText;
              text-decoration: none;
            }
            a:hover {
              text-decoration: underline;
            }
            h1, h2 {
              line-height: 1.3;
            }
            ul {
              padding-left: 1.2rem;
            }
            header, footer {
              margin-bottom: 1.5rem;
            }
            footer {
              font-size: 0.9rem;
              opacity: 0.7;
              text-align: center;
              margin-top: 3rem;
            }
          </style>
        </head>
        <body>
          <header>
            <h1><a href="/">BlogServer</a></h1>
          </header>
          \(body)
          <footer>
            Served by SwiftNIO ✨
          </footer>
        </body>
        </html>
        """
    }

    // MARK: - Routes

    private static func indexPage(contentType: ContentType) -> Response {
        switch contentType {
        case .json:
            return .json(["message": "Welcome to BlogServer", "endpoints": ["/posts", "/api/posts"]])
        case .html:
            let body = """
            <p>This lightweight server renders Markdown posts as HTML for browsers or JSON for API clients.</p>
            <p><a href="/posts">View all posts →</a></p>
            """
            return .html(htmlPage(title: "Welcome", body: body))
        }
    }

    private static func listPosts(contentType: ContentType) -> Response {
        let posts = DataStore.allPosts()

        switch contentType {
        case .json:
            struct Summary: Codable { let slug: String; let title: String }
            let summaries = posts.map { Summary(slug: $0.slug, title: $0.title) }
            return .json(summaries)

        case .html:
            let listItems = posts
                .map { "<li><a href=\"/posts/\($0.slug)\">\($0.title)</a></li>" }
                .joined(separator: "\n")
            let body = """
            <h2>Posts</h2>
            <ul>
              \(listItems)
            </ul>
            <p><a href="/">← Home</a></p>
            """
            return .html(htmlPage(title: "Posts", body: body))
        }
    }

    private static func showPost(slug: String, contentType: ContentType) -> Response {
        guard let post = DataStore.findPost(slug: slug) else {
            return .notFound()
        }

        switch contentType {
        case .json:
            return .json(post)
        case .html:
            let body = """
            <a href="/posts">← All posts</a>
            <h2>\(escapeHTML(post.title))</h2>
            \(post.htmlBody)
            """
            return .html(htmlPage(title: post.title, body: body))
        }
    }

    private static func health() -> Response {
        .json(["status": "ok"])
    }

    private static func escapeHTML(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }
}
